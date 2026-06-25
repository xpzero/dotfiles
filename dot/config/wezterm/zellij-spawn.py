#!/usr/bin/env python3
"""
为 zellij 创建 session 提供 PTY 环境，解决从 WezTerm 后台启动时 ENODEV 错误。

用法:
  python3 zellij-spawn.py <session-name>               # 仅创建 session，不加载 layout
  python3 zellij-spawn.py <session-name> <layout-path> # 创建 session 并加载 layout
"""
import sys
import os
import pty
import subprocess
import time

if len(sys.argv) < 2 or len(sys.argv) > 3:
    print("用法: python3 zellij-spawn.py <session-name> [layout-path]", file=sys.stderr)
    sys.exit(1)

session_name = sys.argv[1]
layout_path = sys.argv[2] if len(sys.argv) == 3 else None

# fork 创建带 PTY 的子进程
pid, fd = pty.fork()
if pid == 0:
    # 子进程：执行 zellij
    os.execvp("zellij", ["zellij", "-s", session_name])
else:
    # 父进程：等待 zellij 初始化
    time.sleep(2)

    # 如果有 layout，添加 workspace tab 并关闭默认空 tab
    if layout_path and os.path.isfile(layout_path):
        # 添加 workspace tab
        subprocess.run([
            "zellij", "--session", session_name, "action",
            "new-tab", "--name", "workspace", "--layout", layout_path
        ], check=False)
        time.sleep(0.5)

        # 切回默认 tab（#1），然后关闭它
        subprocess.run([
            "zellij", "--session", session_name, "action",
            "go-to-previous-tab"
        ], check=False)
        time.sleep(0.3)

        subprocess.run([
            "zellij", "--session", session_name, "action",
            "close-tab"
        ], check=False)
        time.sleep(0.3)

    # 关闭 PTY fd，让 session 保持后台运行
    try:
        os.close(fd)
    except:
        pass
    sys.exit(0)


