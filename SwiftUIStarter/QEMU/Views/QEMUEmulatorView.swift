import SwiftUI

/// QEMU 模拟器主界面：引导测试 / 画面 / 关于
struct QEMUEmulatorView: View {
    @StateObject private var tester = QEMUBootTester()

    var body: some View {
        TabView {
            BootConsoleView(tester: tester)
                .tabItem { Label("引导测试", systemImage: "terminal") }
            EmulatorDisplayView()
                .tabItem { Label("画面", systemImage: "display") }
            AboutQEMUView()
                .tabItem { Label("关于", systemImage: "info.circle") }
        }
        .preferredColorScheme(.dark)
    }
}
