#!/bin/bash
# =============================================================================
# OKX-Dog 个人量化智能交易系统 - 一键启动脚本
# 自动启动后端 FastAPI 服务 (8000 端口) 与前端 React 控制台 (3000 端口)
# =============================================================================

# 遇到中断时自动清理后台子进程
trap cleanup SIGINT SIGTERM EXIT

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$ROOT_DIR/okx-dog-backend"
FRONTEND_DIR="$ROOT_DIR/okx-dog-frontend"
AI_DIR="$ROOT_DIR/okx-dog-ai"

# 颜色输出定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "=================================================================="
echo "   🐕 OKX-Dog 个人量化智能交易副驾驶系统 (AI Trading Co-pilot)   "
echo "=================================================================="
echo -e "${NC}"

# 1. 查找可用 Python 虚拟环境
PYTHON_BIN=""
if [ -f "$ROOT_DIR/.venv/bin/python" ]; then
    PYTHON_BIN="$ROOT_DIR/.venv/bin/python"
elif [ -f "$ROOT_DIR/.agents/auditor_r2/venv/bin/python" ]; then
    PYTHON_BIN="$ROOT_DIR/.agents/auditor_r2/venv/bin/python"
elif command -v python3 &> /dev/null; then
    PYTHON_BIN="$(command -v python3)"
else
    echo -e "${RED}[错误] 未找到可用 Python 解释器，请先安装 Python 3.9+${NC}"
    exit 1
fi

echo -e "${BLUE}[1/4] 检测到 Python 运行环境: ${GREEN}$PYTHON_BIN${NC}"

# 2. 检测 Node.js 与前端依赖
if ! command -v npm &> /dev/null; then
    echo -e "${RED}[错误] 未检测到 npm / Node.js，请先安装 Node.js 18+${NC}"
    exit 1
fi

if [ ! -d "$FRONTEND_DIR/node_modules" ]; then
    echo -e "${YELLOW}[提示] 正在初始化前端依赖 (npm install)...${NC}"
    (cd "$FRONTEND_DIR" && npm install)
fi

echo -e "${BLUE}[2/4] 前端 Node.js 环境准备就绪${NC}"

# 3. 清理已占用的 8000 和 3000 端口旧进程 (防止端口冲突)
kill_port() {
    local port=$1
    local pids=$(lsof -ti tcp:$port 2>/dev/null)
    if [ -n "$pids" ]; then
        echo -e "${YELLOW}[清理] 端口 $port 已被占用，正在清理旧进程 (PID: $pids)...${NC}"
        kill -9 $pids 2>/dev/null || true
        sleep 0.5
    fi
}
kill_port 8000
kill_port 3000

# 4. 启动后端 FastAPI 网关与 AI 分析引擎
echo -e "${BLUE}[3/4] 正在启动后端 FastAPI 服务与 AI 量化引擎 (Port: 8000)...${NC}"
export PYTHONPATH="$BACKEND_DIR:$AI_DIR:$ROOT_DIR:$PYTHONPATH"

cd "$BACKEND_DIR"
$PYTHON_BIN -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload &
BACKEND_PID=$!

# 等待后端服务健康就绪
for i in {1..20}; do
    if curl -s http://127.0.0.1:8000/api/v1/health > /dev/null 2>&1; then
        echo -e "${GREEN}[后端就绪] FastAPI 核心网关已启动: http://127.0.0.1:8000 (PID: $BACKEND_PID)${NC}"
        break
    fi
    sleep 0.5
done

# 5. 启动前端 Vite 交易控制台
echo -e "${BLUE}[4/4] 正在启动前端 React 交易控制台 (Port: 3000)...${NC}"
cd "$FRONTEND_DIR"
npm run dev -- --host 127.0.0.1 --port 3000 &
FRONTEND_PID=$!

sleep 1.5

echo -e "\n${GREEN}=================================================================="
echo "   🚀 OKX-Dog 系统全部服务已成功启动！"
echo "   🌐 前端控制台: ${CYAN}http://127.0.0.1:3000${GREEN}"
echo "   ⚡ 后端 API 网关: ${CYAN}http://127.0.0.1:8000/docs${GREEN}"
echo "   🔐 安全特性: AES-256-GCM 密盒 · 页面脱敏 · 提现物理隔离"
echo "   提示: 按 ${YELLOW}Ctrl+C${GREEN} 即可安全停止所有服务。"
echo "==================================================================${NC}\n"

# 自动在浏览器中打开前端界面 (Mac / Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    open "http://127.0.0.1:3000" 2>/dev/null || true
elif [[ "$OSTYPE" == "linux-gnu"* ]] && command -v xdg-open &> /dev/null; then
    xdg-open "http://127.0.0.1:3000" 2>/dev/null || true
fi

# 退出清理函数
cleanup() {
    echo -e "\n${YELLOW}[停止] 正在安全停止 OKX-Dog 后端与前端服务...${NC}"
    if [ -n "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    if [ -n "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    kill_port 8000
    kill_port 3000
    echo -e "${GREEN}[完成] 所有服务已安全退出。${NC}"
    exit 0
}

# 保持前台运行并监听日志
wait
