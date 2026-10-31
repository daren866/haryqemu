# QEMU · SwiftUI 引导测试仓库

在原 SwiftUI Starter 模板基础上，集成了 **完整版 QEMU 11.1.3 源码**、一套 **x86 引导测试**，并把 **引导测试与模拟器画面整合进 SwiftUI 界面**。

[![QEMU Boot Test](https://github.com/daren866/haryqemu/actions/workflows/qemu-boot-test.yml/badge.svg)](https://github.com/daren866/haryqemu/actions/workflows/qemu-boot-test.yml)
[![Build Unsigned IPA](https://github.com/daren866/haryqemu/actions/workflows/main.yml/badge.svg)](https://github.com/daren866/haryqemu/actions/workflows/main.yml)

## 目录结构

| 路径 | 内容 |
| --- | --- |
| `qemu/` | QEMU 11.1.3 官方发行版完整源码（约 900MB，GPLv2，见 `qemu/COPYING`） |
| `qemu-boot-test/` | 引导测试：`boot.S`（512 字节引导扇区）、`run-boot-test.sh`（运行脚本）、`qmp_screendump.py`（QMP 截图）、`artifacts/`（实测证据） |
| `SwiftUIStarter/QEMU/` | SwiftUI 整合界面：引导测试控制台、模拟器画面、关于页 |
| `SwiftUIStarter/Assets.xcassets/BootScreen.imageset/` | 引导测试实测捕获的 VGA 画面 |
| `.github/workflows/qemu-boot-test.yml` | CI：Linux 上编译仓库内 QEMU 并运行引导测试 |
| `.github/workflows/main.yml` | CI：macOS 上用 Tuist 构建无签名 IPA（TrollStore） |

## 引导测试原理

1. `boot.S` 汇编为 512 字节 MBR 引导扇区（`0x55AA` 签名）；
2. `qemu-system-x86_64`（本仓库源码构建，TCG 软件翻译）从 IDE 磁盘引导该扇区；
3. 引导扇区通过 **BIOS INT 10h** 将测试报告写到 VGA 文本屏幕，同时初始化 **COM1（115200 8N1）** 并将同一份报告写入串口；
4. 测试脚本通过 **QMP `screendump`** 抓取 720×400 的 VGA 画面；
5. 判定标准：串口日志包含 `BOOT TEST PASSED`，且画面为 720×400、非空白。

实测产物提交在 `qemu-boot-test/artifacts/`：

- `serial.log` — COM1 串口日志
- `screen.png` — QMP 捕获的 VGA 文本画面

### 运行方式

```bash
# 本地（需要 qemu-system-x86_64、binutils、Python3 + Pillow）
cd qemu-boot-test
QEMU_BIN=/path/to/qemu-system-x86_64 bash run-boot-test.sh

# 或使用 just
just boot-test QEMU_BIN=/path/to/qemu-system-x86_64
```

CI（`ubuntu-latest`）在每次 push 到 `main` 时自动执行：编译本仓库 `qemu/` 源码 → 运行引导测试 → 上传证据产物。

## SwiftUI 界面

App 入口 `ContentView` → `QEMUEmulatorView`，含三个页面：

- **引导测试**：按实测节奏逐行回放 COM1 串口日志（终端风格、自动滚动），结束后按与脚本相同的判定标准给出五项校验结果（引导扇区执行、VGA 输出、串口输出、通过标记、无失败标记）；
- **画面**：展示引导测试真实捕获的 VGA 画面（720×400），支持 1–4 倍无损缩放与 CRT 扫描线效果；
- **关于**：仓库内容、引导测试流程、本地运行方法与源码完整性信息。

> 说明：iOS 沙盒不允许派生进程，App 内无法直接运行 QEMU 二进制。界面回放与展示的串口日志、画面均来自 `qemu-boot-test` 的实测固件（由 `gen_boot_fixture.py` 从 `artifacts/serial.log` 生成），与 CI / 本地运行是同一套测试。

## 源码来源与完整性

- 官方发行包：<https://download.qemu.org/qemu-11.1.3.tar.xz>
- SHA-256：`5a8289c7940dc77d3873c81a6c29ba3afe1446fc9d36e77fa1658cdbecb84b22`

## SwiftUI Starter 工具链（原模板保留）

文件系统优先的项目设置，使用 **Tuist + just**：生成 Xcode 工作区、构建/测试、SwiftFormat 格式化、可选 build-server 支持 LSP。

工具：[tuist](https://tuist.io)、[just](https://github.com/casey/just)、[swiftformat](https://github.com/nicklockwood/SwiftFormat)、[xcode-build-server](https://github.com/SolaWing/xcode-build-server)（可选）。

常用命令：

- `just generate` — 生成 Xcode 工作区
- `just build` — 在 iOS 模拟器中构建应用
- `just test` — 运行单元测试
- `just open` — 在 Xcode 中打开工作区
- `just boot-test` — 运行 QEMU 引导测试

入门步骤：安装上述工具 → 重命名目录并更新 `Project.swift`（项目名、Bundle ID、开发团队）→ 按需调整 `justfile` 中的模拟器型号 → `just generate` 打开工作区。

注意：`*.xcodeproj` / `*.xcworkspace` 为生成产物，已被 Git 忽略；CI 构建使用 `just build` 与 `just test`。
