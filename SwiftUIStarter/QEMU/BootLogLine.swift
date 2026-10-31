import Foundation

/// 引导日志中的一行及其语义类别
struct BootLogLine: Identifiable, Equatable {
    enum Kind: Equatable {
        case heading
        case separator
        case stage
        case check
        case passed
        case failed
        case plain
    }

    let id: Int
    let text: String
    let kind: Kind

    init(id: Int, text: String) {
        self.id = id
        self.text = text
        self.kind = Kind(text: text)
    }
}

extension BootLogLine.Kind {
    /// 依据串口日志文本推断行类别（与 run-boot-test.sh 的输出约定一致）
    init(text: String) {
        if text.contains("PASSED") {
            self = .passed
        } else if text.contains("FAILED") {
            self = .failed
        } else if text.hasPrefix("====") {
            self = .separator
        } else if text.hasSuffix("BOOT TEST") {
            self = .heading
        } else if text.contains(": OK") {
            self = .check
        } else if text.hasPrefix("Stage") || text.hasPrefix("CPU") || text.hasPrefix("Target") || text.hasPrefix("BIOS") {
            self = .stage
        } else {
            self = .plain
        }
    }
}
