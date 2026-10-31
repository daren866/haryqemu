import Foundation

/// QEMU 引导测试的真实串口日志固件。
/// 内容由 `qemu-boot-test/run-boot-test.sh` 实测捕获，本文件由
/// `python3 qemu-boot-test/gen_boot_fixture.py` 生成，请勿手工编辑。
enum QEMUBootLogFixture {
    /// 串口日志捕获时间
    static let capturedAt = "2026-10-31 13:10 UTC"

    /// COM1 串口逐行输出（与 artifacts/serial.log 一致）
    static let lines: [String] = [
        "QEMU x86-64 BOOT TEST",
        "=====================",
        "Stage 1 bootloader entered at 0000:7C00",
        "VGA text console via INT 10h: OK",
        "COM1 serial 115200 8N1: OK",
        "CPU: real mode, TCG translation",
        "BOOT TEST PASSED",
    ]
}
