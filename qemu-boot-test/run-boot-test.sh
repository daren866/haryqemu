#!/usr/bin/env bash
#
# QEMU x86-64 引导测试
#
# 流程：
#   1. 汇编 512 字节引导扇区 boot.S -> boot.img（0x55AA 签名校验）
#   2. 用 qemu-system-x86_64 引导（-display none，串口输出到文件，QMP 控制）
#   3. 通过 QMP screendump 抓取 VGA 文本画面（720x400）
#   4. 校验串口日志包含 BOOT TEST PASSED，画面非空白
#   5. 产物写入 artifacts/（serial.log / screen.png），供 SwiftUI 界面与 CI 使用
#
# 用法：
#   bash run-boot-test.sh
# 环境变量：
#   QEMU_BIN    qemu-system-x86_64 路径（默认取 PATH）
#   BUILD_DIR   中间产物目录（默认 ./build）
#   ARTIFACTS_DIR 证据输出目录（默认 ./artifacts）

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QEMU_BIN="${QEMU_BIN:-qemu-system-x86_64}"
BUILD_DIR="${BUILD_DIR:-$HERE/build}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-$HERE/artifacts}"

command -v "$QEMU_BIN" >/dev/null 2>&1 || { echo "错误: 找不到 QEMU 可执行文件 '$QEMU_BIN'"; exit 1; }

mkdir -p "$BUILD_DIR" "$ARTIFACTS_DIR"

echo "== QEMU 引导测试 =="
echo "QEMU: $($QEMU_BIN --version | head -1)"

# --- 1. 汇编引导扇区 ---
as --32 -o "$BUILD_DIR/boot.o" "$HERE/boot.S"
ld -m elf_i386 --oformat binary -Ttext=0x7c00 -o "$BUILD_DIR/boot.img" "$BUILD_DIR/boot.o"
SIZE=$(wc -c < "$BUILD_DIR/boot.img" | tr -d ' ')
[ "$SIZE" -eq 512 ] || { echo "错误: 引导扇区大小 $SIZE != 512"; exit 1; }
echo "[1/5] 引导扇区构建完成: boot.img (512 字节)"

# --- 2. 启动 QEMU ---
rm -f "$ARTIFACTS_DIR/serial.log" "$ARTIFACTS_DIR/screen.ppm" "$BUILD_DIR/qmp.sock"
"$QEMU_BIN" \
    -drive "file=$BUILD_DIR/boot.img,format=raw,if=ide" \
    -display none \
    -serial "file:$ARTIFACTS_DIR/serial.log" \
    -qmp "unix:$BUILD_DIR/qmp.sock,server,nowait" \
    -no-reboot &
QEMU_PID=$!
trap 'kill "$QEMU_PID" 2>/dev/null || true' EXIT
echo "[2/5] QEMU 已启动 (PID $QEMU_PID)，等待 SeaBIOS 完成引导..."

sleep 4

# --- 3. QMP 抓取 VGA 画面 ---
python3 "$HERE/qmp_screendump.py" "$BUILD_DIR/qmp.sock" "$ARTIFACTS_DIR/screen.ppm"
kill "$QEMU_PID" 2>/dev/null || true
echo "[3/5] VGA 画面已捕获: screen.ppm"

# --- 4. 校验串口日志与画面 ---
PASS=1
if grep -q "BOOT TEST PASSED" "$ARTIFACTS_DIR/serial.log"; then
    echo "[4/5] 串口日志校验: 通过"
else
    echo "[4/5] 串口日志校验: 失败（缺少 BOOT TEST PASSED）"
    PASS=0
fi

if python3 - "$ARTIFACTS_DIR" <<'PY'
import sys
import pathlib
from PIL import Image

d = pathlib.Path(sys.argv[1])
img = Image.open(d / "screen.ppm").convert("RGB")
w, h = img.size
px = img.tobytes()
bright = sum(1 for i in range(0, len(px), 3) if max(px[i], px[i + 1], px[i + 2]) > 40)
img.save(d / "screen.png")
print(f"      画面校验: {w}x{h}, 非黑像素 {bright} 个", end=" -> ")
if w == 720 and h == 400 and bright > 1000:
    print("通过")
    sys.exit(0)
print("失败")
sys.exit(1)
PY
then
    :
else
    echo "      画面校验失败"
    PASS=0
fi

# --- 5. 汇总 ---
echo "[5/5] 产物: $ARTIFACTS_DIR/serial.log, $ARTIFACTS_DIR/screen.png"
if [ "$PASS" -eq 1 ]; then
    echo "=== BOOT TEST PASSED ==="
    exit 0
fi
echo "=== BOOT TEST FAILED ==="
exit 1
