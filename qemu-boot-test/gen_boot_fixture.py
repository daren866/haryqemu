#!/usr/bin/env python3
"""从引导测试实测产物生成 SwiftUI 固件文件。

读取 qemu-boot-test/artifacts/serial.log（run-boot-test.sh 的真实输出），
生成 SwiftUIStarter/QEMU/QEMUBootLogFixture.swift，供 App 内回放引导日志。

用法: python3 gen_boot_fixture.py
"""

import datetime
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parent / "SwiftUIStarter" / "QEMU" / "QEMUBootLogFixture.swift"


def swift_escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"')


def main() -> None:
    log_path = HERE / "artifacts" / "serial.log"
    if not log_path.exists():
        raise SystemExit(f"错误: 未找到 {log_path}，请先运行 run-boot-test.sh")

    raw_lines = log_path.read_text(encoding="ascii").splitlines()
    lines = [line for line in raw_lines if line.strip()]
    if not any("BOOT TEST PASSED" in line for line in lines):
        raise SystemExit("错误: 串口日志中缺少 BOOT TEST PASSED，测试未通过，拒绝生成固件")

    captured_at = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    body = "\n".join(f'        "{swift_escape(line)}",' for line in lines)

    content = f"""import Foundation

/// QEMU 引导测试的真实串口日志固件。
/// 内容由 `qemu-boot-test/run-boot-test.sh` 实测捕获，本文件由
/// `python3 qemu-boot-test/gen_boot_fixture.py` 生成，请勿手工编辑。
enum QEMUBootLogFixture {{
    /// 串口日志捕获时间
    static let capturedAt = "{captured_at}"

    /// COM1 串口逐行输出（与 artifacts/serial.log 一致）
    static let lines: [String] = [
{body}
    ]
}}
"""

    OUT.write_text(content, encoding="utf-8")
    print(f"已生成 {OUT}（{len(lines)} 行日志，捕获于 {captured_at}）")


if __name__ == "__main__":
    main()
