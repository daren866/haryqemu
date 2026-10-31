import Combine
import Foundation

/// 引导测试的执行阶段
enum BootTestPhase: Equatable {
    case idle
    case booting
    case passed
    case failed

    var label: String {
        switch self {
        case .idle: return "待机"
        case .booting: return "引导中"
        case .passed: return "引导成功"
        case .failed: return "引导失败"
        }
    }
}

/// 引导测试结束后的单项校验结果
struct BootTestCheck: Identifiable, Equatable {
    let id: Int
    let title: String
    let passed: Bool
}

/// 引导测试控制器
///
/// 逐行回放 `run-boot-test.sh` 实测捕获的 COM1 串口日志，
/// 结束后按与脚本相同的判定标准给出整体校验结果。
/// iOS 沙盒不允许派生进程，真实引导发生在 Linux CI / 本地，
/// 界面回放并校验的是实测固件数据。
final class QEMUBootTester: ObservableObject {
    /// 每行之间的最短间隔（秒）
    private static let minimumLineDelay: TimeInterval = 0.12
    /// 每个字符的回放延迟（秒），模拟串口输出节奏
    private static let perCharacterDelay: TimeInterval = 0.013

    @Published private(set) var phase: BootTestPhase = .idle
    @Published private(set) var lines: [BootLogLine] = []
    @Published private(set) var checks: [BootTestCheck] = []
    @Published private(set) var startedAt: Date?
    @Published private(set) var finishedAt: Date?

    private var playbackTask: Task<Void, Never>?

    deinit {
        playbackTask?.cancel()
    }

    var isRunning: Bool {
        phase == .booting
    }

    var elapsed: TimeInterval {
        guard let startedAt else { return 0 }
        return (finishedAt ?? Date()).timeIntervalSince(startedAt)
    }

    /// 开始一次引导测试：回放实测串口日志并校验结果
    func start() {
        guard !isRunning else { return }
        phase = .booting
        lines = []
        checks = []
        startedAt = Date()
        finishedAt = nil

        let fixture = QEMUBootLogFixture.lines
        playbackTask = Task { [weak self] in
            for (index, text) in fixture.enumerated() {
                if Task.isCancelled { return }
                let line = BootLogLine(id: index, text: text)
                await MainActor.run {
                    self?.lines.append(line)
                }
                let delay = max(Self.minimumLineDelay, TimeInterval(text.count) * Self.perCharacterDelay)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            await MainActor.run {
                self?.finish(with: fixture)
            }
        }
    }

    /// 中止回放并回到待机
    func reset() {
        playbackTask?.cancel()
        playbackTask = nil
        phase = .idle
        lines = []
        checks = []
        startedAt = nil
        finishedAt = nil
    }

    /// 回放结束：按 run-boot-test.sh 的判定标准校验
    private func finish(with rawLines: [String]) {
        finishedAt = Date()
        checks = [
            BootTestCheck(
                id: 0,
                title: "引导扇区被 BIOS 加载并执行",
                passed: rawLines.contains { $0.contains("Stage 1 bootloader") }
            ),
            BootTestCheck(
                id: 1,
                title: "VGA 文本控制台输出正常",
                passed: rawLines.contains { $0.contains("VGA text console via INT 10h: OK") }
            ),
            BootTestCheck(
                id: 2,
                title: "COM1 串口输出正常",
                passed: rawLines.contains { $0.contains("COM1 serial 115200 8N1: OK") }
            ),
            BootTestCheck(
                id: 3,
                title: "存在 BOOT TEST PASSED 通过标记",
                passed: rawLines.contains { $0.contains("BOOT TEST PASSED") }
            ),
            BootTestCheck(
                id: 4,
                title: "不存在 FAILED 失败标记",
                passed: !rawLines.contains { $0.contains("FAILED") }
            ),
        ]
        phase = checks.allSatisfy(\.passed) ? .passed : .failed
    }
}
