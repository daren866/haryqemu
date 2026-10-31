import Foundation

/// QEMU 源码与引导测试的静态描述信息
enum QEMUInfo {
    /// 仓库 qemu/ 目录携带的完整 QEMU 发行版源码版本
    static let qemuVersion = "11.1.3"

    /// 引导测试使用的模拟目标（TCG 纯软件翻译，不依赖 KVM）
    static let emulationTarget = "x86_64-softmmu"

    /// 引导测试的默认机型与固件
    static let machine = "pc (i440FX) + SeaBIOS"

    /// 引导测试时的显示模式
    static let displayMode = "VGA 文本模式 720×400"

    /// 引导测试使用的串口
    static let serialPort = "COM1 · 115200 8N1"

    /// QEMU 源码在仓库中的位置
    static let sourcePath = "qemu/"

    /// 引导测试目录（引导扇区、脚本与实测产物）
    static let bootTestPath = "qemu-boot-test/"
}
