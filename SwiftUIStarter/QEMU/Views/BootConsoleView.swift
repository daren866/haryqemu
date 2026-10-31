import SwiftUI

/// 引导测试控制台：回放实测串口日志，展示逐项校验结果
struct BootConsoleView: View {
    @ObservedObject var tester: QEMUBootTester

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                infoStrip
                console
                Divider()
                controlPanel
            }
            .navigationTitle("QEMU 引导测试")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - 顶部信息条

    private var infoStrip: some View {
        HStack(spacing: 8) {
            InfoChip(title: "QEMU", value: QEMUInfo.qemuVersion)
            InfoChip(title: "目标", value: "x86_64")
            InfoChip(title: "固件", value: "SeaBIOS")
            Spacer()
            Text("捕获于 \(QEMUBootLogFixture.capturedAt)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - 串口控制台

    private var console: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    if tester.lines.isEmpty {
                        Text("等待引导…\n\n点击下方「开始引导测试」，将按实测节奏回放 COM1 串口日志。")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 120)
                    }
                    ForEach(tester.lines) { line in
                        BootLogRow(line: line)
                            .id(line.id)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .background(Color.black)
            .onChange(of: tester.lines.count) { _ in
                if let last = tester.lines.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - 底部控制面板

    private var controlPanel: some View {
        VStack(spacing: 12) {
            switch tester.phase {
            case .idle:
                Button {
                    tester.start()
                } label: {
                    Label("开始引导测试", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

            case .booting:
                HStack(spacing: 12) {
                    ProgressView()
                    Text(tester.phase.label)
                        .font(.subheadline)
                    Spacer()
                    Button("中止") {
                        tester.reset()
                    }
                    .buttonStyle(.bordered)
                }

            case .passed, .failed:
                VStack(spacing: 12) {
                    resultBanner
                    checkList
                    Button {
                        tester.start()
                    } label: {
                        Label("重新测试", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .animation(.easeInOut(duration: 0.2), value: tester.phase)
    }

    private var resultBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: tester.phase == .passed ? "checkmark.seal.fill" : "xmark.octagon.fill")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(tester.phase == .passed ? "BOOT TEST PASSED" : "BOOT TEST FAILED")
                    .font(.headline)
                Text(String(format: "历时 %.1f 秒 · %d 行串口日志", tester.elapsed, tester.lines.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .foregroundColor(tester.phase == .passed ? .green : .red)
    }

    private var checkList: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(tester.checks) { check in
                HStack(spacing: 8) {
                    Image(systemName: check.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(check.title)
                        .font(.footnote)
                    Spacer()
                }
                .foregroundColor(check.passed ? .green : .red)
            }
        }
    }
}

// MARK: - 子视图

private struct InfoChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct BootLogRow: View {
    let line: BootLogLine

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: symbolName)
                .font(.system(size: 10, weight: .bold))
                .frame(width: 14)
            Text(line.text)
                .textSelection(.enabled)
        }
        .foregroundColor(color)
    }

    private var symbolName: String {
        switch line.kind {
        case .heading: return "chevron.left.forwardslash.chevron.right"
        case .separator: return "minus"
        case .stage: return "greaterthan"
        case .check: return "checkmark.circle.fill"
        case .passed: return "checkmark.seal.fill"
        case .failed: return "xmark.octagon.fill"
        case .plain: return "circle.dotted"
        }
    }

    private var color: Color {
        switch line.kind {
        case .heading: return .accentColor
        case .separator: return .secondary
        case .stage: return .primary
        case .check: return .green
        case .passed: return .green
        case .failed: return .red
        case .plain: return .primary
        }
    }
}
