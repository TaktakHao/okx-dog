#!/bin/bash
# =============================================================================
# OKX-Dog 双引擎量化交易系统 - 统一启停与状态运维脚本
# 用法:
#   ./company.sh start    # 一键启动后端 (8000) + 前端 (3000)
#   ./company.sh stop     # 一键停止前后端服务
#   ./company.sh restart  # 一键重启前后端服务
#   ./company.sh status   # 查看服务健康状态
#   ./company.sh logs     # 查看日志 (backend | frontend)
# =============================================================================

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_DIR="$ROOT_DIR/okx-dog-ai"
BACKEND_DIR="$ROOT_DIR/okx-dog-backend"
FRONTEND_DIR="$ROOT_DIR/okx-dog-frontend"
PID_DIR="$ROOT_DIR/.pids"
LOG_DIR="$ROOT_DIR"

mkdir -p "$PID_DIR"

GREEN="\033[92m"
CYAN="\033[96m"
YELLOW="\033[93m"
RED="\033[91m"
BOLD="\033[1m"
RESET="\033[0m"

PYTHON_CMD="python3"
if [ -f "$ROOT_DIR/.venv/bin/python3" ]; then
    PYTHON_CMD="$ROOT_DIR/.venv/bin/python3"
elif [ -f "$ROOT_DIR/.agents/auditor_r2/venv/bin/python3" ]; then
    PYTHON_CMD="$ROOT_DIR/.agents/auditor_r2/venv/bin/python3"
fi

kill_port_pids() {
    local port=$1
    local pids=$(lsof -ti tcp:$port 2>/dev/null || true)
    if [ -n "$pids" ]; then
        echo -e "  ${YELLOW}正在清理端口 $port 占用进程 (PID: $pids)...${RESET}"
        kill -15 $pids 2>/dev/null || true
        sleep 0.5
        kill -9 $pids 2>/dev/null || true
    fi
}

start_services() {
    echo -e "\n${BOLD}${CYAN}======================================================================${RESET}"
    echo -e "${BOLD}${CYAN}   🚀 OKX-Dog 双引擎量化交易系统 - 一键启动                           ${RESET}"
    echo -e "${BOLD}${CYAN}======================================================================${RESET}\n"

    # 1. 启动后端 FastAPI 服务 (8000)
    echo -e "${BOLD}[1/2] 启动后端量化执行与硬风控底座 (端口: 8000)...${RESET}"
    kill_port_pids 8000
    pkill -f "main:app" 2>/dev/null || true
    cd "$BACKEND_DIR"
    export PYTHONPATH="$BACKEND_DIR:$AI_DIR:$ROOT_DIR:$PYTHONPATH"
    nohup $PYTHON_CMD -m uvicorn main:app --host 0.0.0.0 --port 8000 < /dev/null > "$LOG_DIR/backend.log" 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > "$PID_DIR/backend.pid"
    echo -e "  ${GREEN}✔ [OK] 后端服务已启动 (PID: $BACKEND_PID, 日志: backend.log)${RESET}"

    for i in {1..20}; do
        if curl -s http://127.0.0.1:8000/api/v1/health > /dev/null 2>&1; then
            echo -e "  ${GREEN}✔ [健康] 后端健康探针通过${RESET}"
            break
        fi
        sleep 0.5
    done

    # 2. 启动前端 Vite 暗黑交易终端 (3000)
    echo -e "\n${BOLD}[2/2] 启动前端暗黑交易控制台 (端口: 3000)...${RESET}"
    kill_port_pids 3000
    cd "$FRONTEND_DIR"
    if [ ! -d "node_modules" ]; then
        echo -e "  ${YELLOW}正在安装前端依赖...${RESET}"
        npm install
    fi
    nohup ./node_modules/.bin/vite --host 0.0.0.0 --port 3000 > "$LOG_DIR/frontend.log" 2>&1 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > "$PID_DIR/frontend.pid"
    echo -e "  ${GREEN}✔ [OK] 前端终端已启动 (PID: $FRONTEND_PID, 日志: frontend.log)${RESET}"

    for i in {1..15}; do
        if curl -s http://127.0.0.1:3000 > /dev/null 2>&1; then
            echo -e "  ${GREEN}✔ [健康] 前端服务探活通过${RESET}"
            break
        fi
        sleep 0.5
    done

    echo -e "\n${BOLD}${GREEN}======================================================================${RESET}"
    echo -e "${BOLD}${GREEN}   🎉 OKX-Dog 双引擎量化系统已就绪！                                  ${RESET}"
    echo -e "${BOLD}${GREEN}======================================================================${RESET}"
    echo -e "  🌐 ${BOLD}暗黑交易控制台${RESET}: ${CYAN}http://localhost:3000${RESET}"
    echo -e "  ⚡ ${BOLD}后端 API 文档${RESET}:  ${CYAN}http://localhost:8000/docs${RESET}"
    echo -e "  📌 ${BOLD}查看状态${RESET}:       ${YELLOW}./company.sh status${RESET}"
    echo -e "  🛑 ${BOLD}停止服务${RESET}:       ${RED}./company.sh stop${RESET}\n"
}

stop_services() {
    echo -e "\n${BOLD}${RED}正在停止 OKX-Dog 前后端服务...${RESET}"
    if [ -f "$PID_DIR/frontend.pid" ]; then
        kill $(cat "$PID_DIR/frontend.pid") 2>/dev/null || true
        rm -f "$PID_DIR/frontend.pid"
    fi
    kill_port_pids 3000
    pkill -f "vite" 2>/dev/null || true
    echo -e "  ${GREEN}✔ 前端服务已停止${RESET}"

    if [ -f "$PID_DIR/backend.pid" ]; then
        kill $(cat "$PID_DIR/backend.pid") 2>/dev/null || true
        rm -f "$PID_DIR/backend.pid"
    fi
    kill_port_pids 8000
    pkill -f "uvicorn main:app" 2>/dev/null || true
    echo -e "  ${GREEN}✔ 后端服务已停止${RESET}\n"
}

status_services() {
    echo -e "\n${BOLD}${CYAN}--- OKX-Dog 运行状态巡检 ---${RESET}"
    echo -n "  • 前端控制台 (Port 3000): "
    if lsof -ti tcp:3000 &> /dev/null; then
        echo -e "${GREEN}● 运行中${RESET} -> http://localhost:3000"
    else
        echo -e "${RED}○ 已停止${RESET}"
    fi
    echo -n "  • 后端交易底座 (Port 8000): "
    if curl -s http://127.0.0.1:8000/api/v1/health &> /dev/null; then
        echo -e "${GREEN}● 运行中${RESET} -> http://localhost:8000"
    else
        echo -e "${RED}○ 已停止${RESET}"
    fi
    echo ""
}

show_logs() {
    case "${1:-backend}" in
        frontend)
            tail -f "$LOG_DIR/frontend.log"
            ;;
        *)
            tail -f "$LOG_DIR/backend.log"
            ;;
    esac
}

case "$1" in
    start)   start_services ;;
    stop)    stop_services ;;
    restart) stop_services; sleep 1; start_services ;;
    status)  status_services ;;
    logs)    show_logs "$2" ;;
    *)
        echo -e "用法: ./company.sh {start|stop|restart|status|logs [backend|frontend]}"
        exit 1
        ;;
esac
