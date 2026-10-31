#!/usr/bin/env python3
"""QMP 客户端：连接 QEMU 的 QMP unix socket，执行 screendump 抓取 VGA 画面为 PPM。

用法: python3 qmp_screendump.py <qmp.sock> <输出.ppm>
"""

import json
import socket
import sys
import time


def main() -> None:
    if len(sys.argv) != 3:
        print(f"用法: {sys.argv[0]} <qmp.sock> <输出.ppm>", file=sys.stderr)
        raise SystemExit(2)

    sock_path, out_path = sys.argv[1], sys.argv[2]

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.settimeout(10)
        s.connect(sock_path)
        f = s.makefile("rw", encoding="utf-8", newline="\n")

        greeting = json.loads(f.readline())
        if "QMP" not in greeting:
            raise RuntimeError(f"非 QMP 问候报文: {greeting}")

        f.write(json.dumps({"execute": "qmp_capabilities"}) + "\n")
        f.flush()

        while True:
            msg = json.loads(f.readline())
            if "return" in msg or "error" in msg:
                break

        f.write(json.dumps({"execute": "screendump", "arguments": {"filename": out_path}}) + "\n")
        f.flush()

        while True:
            line = f.readline()
            if not line:
                raise RuntimeError("QMP 连接被对方关闭")
            msg = json.loads(line)
            if "error" in msg:
                raise RuntimeError(f"screendump 失败: {msg['error']}")
            if "return" in msg:
                break

    # screendump 由 QEMU 异步写盘，稍等片刻保证文件完整
    time.sleep(0.3)
    print(f"screendump -> {out_path}")


if __name__ == "__main__":
    main()
