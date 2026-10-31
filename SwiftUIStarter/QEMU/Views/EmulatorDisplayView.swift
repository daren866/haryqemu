import SwiftUI

/// 模拟器画面：展示引导测试期间通过 QMP screendump 捕获的真实 VGA 画面
struct EmulatorDisplayView: View {
    @State private var zoom: CGFloat = 1
    @State private var scanlinesOn = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    screen
                    zoomControls
                    screenInfo
                }
                .padding()
            }
            .navigationTitle("模拟器画面")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - 画面

    private var screen: some View {
        VStack(spacing: 0) {
            screenBody
            statusBar
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.secondary.opacity(0.4), lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
    }

    @ViewBuilder private var screenBody: some View {
        if let image = UIImage(named: "BootScreen") {
            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .scaleEffect(zoom)
                .overlay(scanlines)
        } else {
            Text("未找到 BootScreen 画面资源")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 240)
                .background(Color.black)
        }
    }

    /// CRT 扫描线效果
    @ViewBuilder private var scanlines: some View {
        if scanlinesOn {
            Canvas { context, size in
                let stripe: CGFloat = 3
                var y: CGFloat = 0
                while y < size.height {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: stripe / 2)
                    context.fill(Path(rect), with: .color(.black.opacity(0.16)))
                    y += stripe
                }
            }
            .allowsHitTesting(false)
        }
    }

    private var statusBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.green)
                .frame(width: 7, height: 7)
            Text("QEMU · \(QEMUInfo.emulationTarget) · 运行中")
                .font(.caption2.weight(.medium))
            Spacer()
            Text(QEMUInfo.displayMode)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.15))
    }

    // MARK: - 缩放与效果控制

    private var zoomControls: some View {
        HStack(spacing: 12) {
            Image(systemName: "minus.magnifyingglass")
                .foregroundStyle(.secondary)
            Slider(value: $zoom, in: 1...4)
            Image(systemName: "plus.magnifyingglass")
                .foregroundStyle(.secondary)
            Text(String(format: "%.1fx", zoom))
                .font(.footnote.monospacedDigit())
                .frame(width: 40, alignment: .trailing)
            Toggle("扫描线", isOn: $scanlinesOn)
                .font(.footnote)
                .fixedSize()
        }
    }

    // MARK: - 画面说明

    private var screenInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("画面说明", systemImage: "info.circle")
                .font(.subheadline.weight(.semibold))
            Text("这是引导测试真实捕获的 VGA 文本模式画面（QMP screendump，720×400）：SeaBIOS 自检输出之后，由仓库内 512 字节引导扇区通过 BIOS INT 10h 打印的测试报告。与「引导测试」页的串口日志来自同一次运行。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}
