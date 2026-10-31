import SwiftUI

/// 关于页面：仓库内容、引导测试流程与本地运行方式
struct AboutQEMUView: View {
    var body: some View {
        NavigationView {
            List {
                Section("仓库内容") {
                    row(icon: "externaldrive.fill", title: "QEMU \(QEMUInfo.qemuVersion) 完整源码",
                        subtitle: "\(QEMUInfo.sourcePath) 官方发行版源码（qemu-11.1.3.tar.xz，GPLv2）")
                    row(icon: "terminal", title: "引导测试",
                        subtitle: "\(QEMUInfo.bootTestPath) 512 字节引导扇区 + 运行脚本 + 实测产物")
                    row(icon: "square.stack.3d.up", title: "SwiftUI 界面",
                        subtitle: "SwiftUIStarter/QEMU/ 引导测试与画面整合界面")
                }

                Section("引导测试流程") {
                    step(1, "汇编 boot.S 为 512 字节引导扇区（0x55AA 签名）")
                    step(2, "qemu-system-x86_64 从 IDE 磁盘引导（TCG 翻译）")
                    step(3, "引导扇区经 INT 10h 写 VGA 屏幕、经 COM1 写串口")
                    step(4, "QMP screendump 抓取 720×400 VGA 画面")
                    step(5, "校验串口 BOOT TEST PASSED 与画面非空白")
                }

                Section("本地运行真实引导测试") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("需要 qemu-system-x86_64、binutils 与 Python3+Pillow：")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        codeBlock("cd qemu-boot-test\nQEMU_BIN=/path/to/qemu-system-x86_64 \\\n  bash run-boot-test.sh")
                        Text("CI（ubuntu-latest）在每次 push 时自动执行同一流程。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("源码来源与完整性") {
                    row(icon: "link", title: "官方发行包",
                        subtitle: "download.qemu.org/qemu-11.1.3.tar.xz")
                    row(icon: "checkmark.seal", title: "SHA-256",
                        subtitle: "5a8289c7940dc77d3873c81a6c29ba3a\nfe1446fc9d36e77fa1658cdbecb84b22")
                }

                Section("说明") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("iOS 沙盒不允许派生进程，App 内无法直接运行 QEMU 二进制。「引导测试」页回放并校验的串口日志、以及本页画面，均来自仓库内 qemu-boot-test 实测固件（Linux 沙箱 / CI 真实运行捕获）。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("关于", displayMode: .inline)
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - 子视图

    private func row(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }

    private func step(_ index: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.caption.bold())
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentColor.opacity(0.15)))
            Text(text)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }

    private func codeBlock(_ code: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.system(.caption, design: .monospaced))
                .padding(10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
    }
}
