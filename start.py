#!/usr/bin/env python3
"""
OKX-Dog 个人量化智能交易系统 - 跨平台 Python 一键启动器
支持 macOS, Linux, Windows
一键并行拉起后端 FastAPI (8000 端口) 与前端 React (3000 端口)
"""

import os
import sys
import time
import signal
import subprocess
import webbrowser
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent
BACKEND_DIR = ROOT_DIR / "okx-dog-backend"
FRONTEND_DIR = ROOT_DIR / "okx-dog-frontend"
AI_DIR = ROOT_DIR / "okx-dog-ai"

# 查找 Python 虚拟环境解释器
def get_python_executable():
    candidates = [
        ROOT_DIR / ".venv" / "bin" / "python",
        ROOT_DIR / ".venv" / "Scripts" / "python.exe",
        ROOT_DIR / ".agents" / "auditor_r2" / "venv" / "bin" / "python",
        Path(sys.executable)
    ]
    for c in candidates:
        if c.exists():
            return str(c)
    return sys.executable

def main():
    print("\033[1;36m" + "=" * 66)
    print("   🐕 OKX-Dog 个人量化智能交易副驾驶系统 (AI Trading Co-pilot)   ")
    print("=" * 66 + "\033[0m")

    python_bin = get_python_executable()
    print(f"\033[1;34m[1/3] Python 运行环境:\033[0m \033[1;32m{python_bin}\033[0m")

    # 设置 PYTHONPATH
    env = os.environ.copy()
    python_path_entries = [str(BACKEND_DIR), str(AI_DIR), str(ROOT_DIR)]
    if "PYTHONPATH" in env:
        python_path_entries.append(env["PYTHONPATH"])
    env["PYTHONPATH"] = os.pathsep.join(python_path_entries)

    processes = []

    def shutdown(sig, frame):
        print("\n\033[1;33m[停止] 正在安全关闭 OKX-Dog 全部服务...\033[0m")
        for p in processes:
            try:
                p.terminate()
            except Exception:
                pass
        time.sleep(0.5)
        for p in processes:
            try:
                p.kill()
            except Exception:
                pass
        print("\033[1;32m[完成] 所有服务已安全退出。\033[0m")
        sys.exit(0)

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    # 1. 启动后端 FastAPI
    print("\033[1;34m[2/3] 正在启动后端 FastAPI 网关 (Port: 8000)...\033[0m")
    backend_cmd = [
        python_bin, "-m", "uvicorn", "main:app",
        "--host", "127.0.0.1", "--port", "8000", "--reload"
    ]
    backend_proc = subprocess.Popen(backend_cmd, cwd=str(BACKEND_DIR), env=env)
    processes.append(backend_proc)

    # 2. 启动前端 Vite
    print("\033[1;34m[3/3] 正在启动前端 React 控制台 (Port: 3000)...\033[0m")
    frontend_cmd = ["npm", "run", "dev", "--", "--host", "127.0.0.1", "--port", "3000"]
    frontend_proc = subprocess.Popen(frontend_cmd, cwd=str(FRONTEND_DIR), env=env)
    processes.append(frontend_proc)

    time.sleep(2.0)
    print("\n\033[1;32m" + "=" * 66)
    print("   🚀 OKX-Dog 系统全部服务已成功启动！")
    print("   🌐 前端交易控制台: \033[1;36mhttp://127.0.0.1:3000\033[1;32m")
    print("   ⚡ 后端 OpenAPI 接口: \033[1;36mhttp://127.0.0.1:8000/docs\033[1;32m")
    print("   提示: 按 Ctrl+C 即可安全退出所有服务。")
    print("=" * 66 + "\033[0m\n")

    # 自动打开浏览器
    try:
        webbrowser.open("http://127.0.0.1:3000")
    except Exception:
        pass

    try:
        while True:
            time.sleep(1)
            # 检查子进程健康
            for p in processes:
                if p.poll() is not None:
                    print(f"\033[1;31m[告警] 子进程 (PID: {p.pid}) 意外退出 (退出码: {p.returncode})\033[0m")
    except KeyboardInterrupt:
        shutdown(None, None)

if __name__ == "__main__":
    main()
