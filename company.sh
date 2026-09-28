#!/bin/bash
# =============================================================================
# OKX-Dog v6.0 - 虚拟量化对冲基金与 Paperclip 统一全生命周期运维主控脚本
# 用法:
#   ./company.sh start    # 一键拉起全套系统 (Paperclip + AI网关 + 后端 + 前端 + 自动接入)
#   ./company.sh stop     # 一键平滑彻底关闭全部服务 (前端 + 后端 + AI + Docker容器)
#   ./company.sh restart  # 一键平滑重启全套系统
#   ./company.sh status   # 一键全息巡检系统运行状态与服务健康度
#   ./company.sh logs     # 实时查看系统运行日志 (可加参数: ai | backend | frontend | docker)
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
DIM="\033[2m"
RESET="\033[0m"

# 查找可用 Python 解释器
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
        echo -e "  ${YELLOW}正在清理占用端口 $port 的进程 (PID: $pids)...${RESET}"
        kill -15 $pids 2>/dev/null || true
        sleep 0.5
        kill -9 $pids 2>/dev/null || true
    fi
}

start_company() {
    echo -e "\n${BOLD}${CYAN}======================================================================${RESET}"
    echo -e "${BOLD}${CYAN}   🚀 OKX-Dog v6.0 虚拟量化对冲基金 - 一键全面开机拉起               ${RESET}"
    echo -e "${BOLD}${CYAN}======================================================================${RESET}\n"

    # 1. 检查本地 agy CLI 环境
    echo -e "${BOLD}[1/6] 检查宿主机环境与本地 Antigravity CLI 状态...${RESET}"
    if command -v agy &> /dev/null; then
        echo -e "  ${GREEN}✔ [OK] 检测到本地 Antigravity CLI (agy) 已就绪，享受套餐包月零边际成本${RESET}"
    else
        echo -e "  ${YELLOW}⚠ [提示] 未在 PATH 中找到 agy 命令，系统将以 OpenAI 协议兼容/精简推理模式运行${RESET}"
    fi

    # 2. 拉起 Paperclip 容器中枢
    echo -e "\n${BOLD}[2/6] 拉起 Paperclip 智能体组织中枢 (Docker / OrbStack 端口: 3100)...${RESET}"
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null; then
            echo -e "  正在启动 Paperclip 与 PostgreSQL 17 轻量容器..."
            docker compose -f "$ROOT_DIR/docker-compose.paperclip.yml" up -d
            echo -e "  ${GREEN}✔ [OK] Paperclip 容器集群已在后台启动 (Web控制台: 3100)${RESET}"
        else
            echo -e "  ${YELLOW}⚠ [提示] Docker 守护进程未启动，请开启 OrbStack 或 Docker Desktop。宿主机部分将先行启动${RESET}"
        fi
    else
        echo -e "  ${YELLOW}⚠ [跳过] 宿主机未安装 Docker，跳过容器启动${RESET}"
    fi

    # 3. 启动 AI 决策网关与 CFO 战绩引擎 (8001)
    echo -e "\n${BOLD}[3/6] 启动 AI 决策大脑与 CFO 战绩激励引擎 (端口: 8001)...${RESET}"
    kill_port_pids 8001
    pkill -f "antigravity_server.py" 2>/dev/null || true
    cd "$AI_DIR"
    export PYTHONPATH="$ROOT_DIR:$AI_DIR:$BACKEND_DIR:$PYTHONPATH"
    nohup $PYTHON_CMD antigravity_server.py < /dev/null > "$LOG_DIR/ai_gateway.log" 2>&1 &
    AI_PID=$!
    echo $AI_PID > "$PID_DIR/ai_gateway.pid"
    echo -e "  ${GREEN}✔ [OK] AI 决策网关已在后台运行 (PID: $AI_PID, 见 ai_gateway.log)${RESET}"

    # 等待 AI 网关健康探针
    for i in {1..15}; do
        if curl -s http://127.0.0.1:8001/api/v1/paperclip/org > /dev/null 2>&1; then
            echo -e "  ${GREEN}✔ [健康] AI 决策网关已通过接口探活${RESET}"
            break
        fi
        sleep 0.5
    done

    # 4. 启动 7x24h 交易中枢与不可绕过硬风控底座 (8000)
    echo -e "\n${BOLD}[4/6] 启动 7x24h 毫秒级交易与 5 重不可绕过硬风控底座 (端口: 8000)...${RESET}"
    kill_port_pids 8000
    pkill -f "main:app" 2>/dev/null || true
    cd "$BACKEND_DIR"
    nohup $PYTHON_CMD -m uvicorn main:app --host 0.0.0.0 --port 8000 < /dev/null > "$LOG_DIR/backend.log" 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > "$PID_DIR/backend.pid"
    echo -e "  ${GREEN}✔ [OK] 交易核心服务已在后台运行 (PID: $BACKEND_PID, 见 backend.log)${RESET}"

    # 等待后端健康探针
    for i in {1..15}; do
        if curl -s http://127.0.0.1:8000/api/v1/health > /dev/null 2>&1; then
            echo -e "  ${GREEN}✔ [健康] 后端交易底座已通过接口探活${RESET}"
            break
        fi
        sleep 0.5
    done

    # 5. 启动 前端 Vite 暗黑交易操盘大屏 (3000)
    echo -e "\n${BOLD}[5/6] 启动 前端金融级暗黑交易操盘大屏 (端口: 3000)...${RESET}"
    kill_port_pids 3000
    cd "$FRONTEND_DIR"
    if [ ! -d "node_modules" ]; then
        echo -e "  ${YELLOW}正在安装前端依赖...${RESET}"
        npm install
    fi
    nohup npx vite --host 0.0.0.0 --port 3000 < /dev/null > "$LOG_DIR/frontend.log" 2>&1 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > "$PID_DIR/frontend.pid"
    echo -e "  ${GREEN}✔ [OK] 前端暗黑大屏已在后台运行 (PID: $FRONTEND_PID, 见 frontend.log)${RESET}"

    # 6. 自动执行 Paperclip 自动接入与 6 大员工注册引导
    echo -e "\n${BOLD}[6/6] 自动向 Paperclip 注册虚拟量化公司与 6 大 AI 员工...${RESET}"
    cd "$ROOT_DIR"
    $PYTHON_CMD "$ROOT_DIR/scripts/bootstrap_paperclip_company.py"

    echo -e "\n${BOLD}${GREEN}======================================================================${RESET}"
    echo -e "${BOLD}${GREEN}   🎉 全套系统已成功一键拉起并自动接入！系统处于全自动运营状态       ${RESET}"
    echo -e "${BOLD}${GREEN}======================================================================${RESET}"
    echo -e "  🌐 ${BOLD}暗黑交易控制台 (投资人操盘大屏)${RESET}: ${CYAN}http://localhost:3000${RESET}"
    echo -e "  💼 ${BOLD}Paperclip 组织架构与任务看板${RESET}:   ${CYAN}http://localhost:3100${RESET}"
    echo -e "  ⚡ ${BOLD}FastAPI 后端交易与风控接口${RESET}:     ${CYAN}http://localhost:8000/docs${RESET}"
    echo -e "  🤖 ${BOLD}AI 决策网关与 CFO 战绩 API${RESET}:     ${CYAN}http://localhost:8001/api/v1/paperclip/org${RESET}"
    echo -e "  ------------------------------------------------------------------"
    echo -e "  📌 ${BOLD}查看运行状态${RESET}: ${YELLOW}./company.sh status${RESET}"
    echo -e "  🛑 ${BOLD}一键彻底关闭${RESET}: ${RED}./company.sh stop${RESET}"
    echo -e "  📜 ${BOLD}实时查看日志${RESET}: ${CYAN}./company.sh logs${RESET}\n"
}

stop_company() {
    echo -e "\n${BOLD}${RED}======================================================================${RESET}"
    echo -e "${BOLD}${RED}   🛑 正在一键安全平滑关闭 OKX-Dog 虚拟公司所有服务...               ${RESET}"
    echo -e "${BOLD}${RED}======================================================================${RESET}\n"

    # 1. 停止前端
    echo -e "${BOLD}[1/4] 停止前端 React/Vite 服务 (端口: 3000)...${RESET}"
    if [ -f "$PID_DIR/frontend.pid" ]; then
        FPID=$(cat "$PID_DIR/frontend.pid")
        kill $FPID 2>/dev/null || true
        rm -f "$PID_DIR/frontend.pid"
    fi
    kill_port_pids 3000
    pkill -f "vite" 2>/dev/null || true
    echo -e "  ${GREEN}✔ 前端服务已停止${RESET}"

    # 2. 停止交易底座与风控拦截器
    echo -e "\n${BOLD}[2/4] 停止 7x24h 交易中枢与硬风控底座 (端口: 8000)...${RESET}"
    if [ -f "$PID_DIR/backend.pid" ]; then
        BPID=$(cat "$PID_DIR/backend.pid")
        kill $BPID 2>/dev/null || true
        rm -f "$PID_DIR/backend.pid"
    fi
    kill_port_pids 8000
    pkill -f "uvicorn main:app" 2>/dev/null || true
    echo -e "  ${GREEN}✔ 后端交易底座已安全停止${RESET}"

    # 3. 停止 AI 决策网关
    echo -e "\n${BOLD}[3/4] 停止 AI 决策大脑与 CFO 战绩引擎 (端口: 8001)...${RESET}"
    if [ -f "$PID_DIR/ai_gateway.pid" ]; then
        APID=$(cat "$PID_DIR/ai_gateway.pid")
        kill $APID 2>/dev/null || true
        rm -f "$PID_DIR/ai_gateway.pid"
    fi
    kill_port_pids 8001
    pkill -f "antigravity_server.py" 2>/dev/null || true
    echo -e "  ${GREEN}✔ AI 决策网关已安全停止${RESET}"

    # 4. 停止 Paperclip 容器集群
    echo -e "\n${BOLD}[4/4] 停止 Paperclip 与 PostgreSQL 容器集群...${RESET}"
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        docker compose -f "$ROOT_DIR/docker-compose.paperclip.yml" stop
        echo -e "  ${GREEN}✔ Paperclip 与数据库容器已优雅暂停${RESET}"
    else
        echo -e "  ${YELLOW}⚠ 未运行 Docker 容器或 Docker 守护进程未启动，跳过容器停止${RESET}"
    fi

    echo -e "\n${BOLD}${GREEN}======================================================================${RESET}"
    echo -e "${BOLD}${GREEN}   ✔ 所有服务已彻底安全关闭，端口已全部释放！                      ${RESET}"
    echo -e "${BOLD}${GREEN}======================================================================${RESET}\n"
}

status_company() {
    echo -e "\n${BOLD}${CYAN}======================================================================${RESET}"
    echo -e "${BOLD}${CYAN}   📊 OKX-Dog v6.0 虚拟量化公司 - 全息巡检运行状态大屏               ${RESET}"
    echo -e "${BOLD}${CYAN}======================================================================${RESET}\n"

    # 前端状态
    echo -n "  • 前端交易控制台 (Port 3000): "
    if lsof -ti tcp:3000 &> /dev/null; then
        echo -e "${GREEN}● 运行中 (ACTIVE)${RESET} -> http://localhost:3000"
    else
        echo -e "${RED}○ 已停止 (STOPPED)${RESET}"
    fi

    # 后端状态
    echo -n "  • 交易与风控底座 (Port 8000): "
    if curl -s http://127.0.0.1:8000/api/v1/health &> /dev/null; then
        echo -e "${GREEN}● 运行中 (HEALTHY)${RESET} -> http://localhost:8000"
    else
        echo -e "${RED}○ 已停止 (STOPPED)${RESET}"
    fi

    # AI 网关状态
    echo -n "  • AI决策与CFO网关 (Port 8001): "
    if curl -s http://127.0.0.1:8001/api/v1/paperclip/org &> /dev/null; then
        echo -e "${GREEN}● 运行中 (HEALTHY)${RESET} -> http://localhost:8001"
    else
        echo -e "${RED}○ 已停止 (STOPPED)${RESET}"
    fi

    # Paperclip 容器状态
    echo -n "  • Paperclip 中枢 (Port 3100): "
    if curl -s http://127.0.0.1:3100 &> /dev/null || (command -v docker &> /dev/null && docker ps 2>/dev/null | grep -q "okx-dog-paperclip-core"); then
        echo -e "${GREEN}● 运行中 (ONLINE)${RESET} -> http://localhost:3100"
    else
        echo -e "${YELLOW}○ 未就绪 / 离线模式 (启动 OrbStack/Docker 后执行 ./company.sh start 即可拉起)${RESET}"
    fi

    # 本地 agy CLI 状态
    echo -n "  • 本地 Antigravity CLI (agy):  "
    if command -v agy &> /dev/null; then
        echo -e "${GREEN}● 已就绪 (Ready - 尊享包月零边际成本)${RESET}"
    else
        echo -e "${YELLOW}○ 未安装 (Fallback 兼容模式)${RESET}"
    fi

    # Paperclip 自动接入状态
    echo -n "  • 虚拟公司自动接入状态:      "
    if [ -f "$ROOT_DIR/.paperclip_bootstrapped.json" ]; then
        echo -e "${GREEN}✔ 已接入在册 (6 大员工全天候就位)${RESET}"
    else
        echo -e "${YELLOW}○ 待接入 (启动时将自动注入)${RESET}"
    fi

    # 查看 CFO 战绩激励简讯
    if curl -s http://127.0.0.1:8001/api/v1/paperclip/quota/overview &> /dev/null; then
        echo -e "\n  ${BOLD}🏆 CFO 战绩激励奖金池概览 (长效分红制):${RESET}"
        curl -s http://127.0.0.1:8001/api/v1/paperclip/quota/overview | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    pool = d.get("total_bonus_pool_tokens", 0)
    remain = d.get("remaining_pool_tokens", 0)
    emps = d.get("employees_quota", [])
    total_7d_pnl = sum(e.get("rolling_7d_pnl_usdt", 0) for e in emps)
    unlocked_count = sum(1 for e in emps if e.get("deep_thinking_unlocked", False))
    print(f"    - 7天滚动总收益:       {total_7d_pnl:+.2f} USDT")
    print(f"    - 累计分红战绩池:     {pool:,} Tokens")
    print(f"    - 当前可用奖金池:     {remain:,} Tokens")
    print(f"    - 深度思考特权解锁:   {unlocked_count}/6 位员工已解锁 DeepSeek-R1 深度辩论")
except Exception:
    pass
' 2>/dev/null || true
    fi

    echo -e "\n${BOLD}${CYAN}======================================================================${RESET}\n"
}

show_logs() {
    local target=${1:-"all"}
    case "$target" in
        ai)
            echo -e "${CYAN}正在追踪 AI 决策网关日志 (ai_gateway.log)...${RESET}"
            tail -f "$LOG_DIR/ai_gateway.log"
            ;;
        backend)
            echo -e "${CYAN}正在追踪 交易底座日志 (backend.log)...${RESET}"
            tail -f "$LOG_DIR/backend.log"
            ;;
        frontend)
            echo -e "${CYAN}正在追踪 前端操盘台日志 (frontend.log)...${RESET}"
            tail -f "$LOG_DIR/frontend.log"
            ;;
        docker)
            echo -e "${CYAN}正在追踪 Paperclip 容器集群日志...${RESET}"
            docker compose -f "$ROOT_DIR/docker-compose.paperclip.yml" logs -f
            ;;
        *)
            echo -e "${CYAN}可用日志命令: ./company.sh logs [ai | backend | frontend | docker]${RESET}"
            echo -e "${CYAN}默认显示后端与AI网关最近 20 行日志:${RESET}\n"
            echo -e "--- [AI 网关最近日志] ---"
            tail -n 10 "$LOG_DIR/ai_gateway.log" 2>/dev/null || true
            echo -e "\n--- [后端最近日志] ---"
            tail -n 10 "$LOG_DIR/backend.log" 2>/dev/null || true
            ;;
    esac
}

case "$1" in
    start)
        start_company
        ;;
    stop)
        stop_company
        ;;
    restart)
        stop_company
        sleep 1
        start_company
        ;;
    status)
        status_company
        ;;
    logs)
        show_logs "$2"
        ;;
    *)
        echo -e "${BOLD}使用说明:${RESET}"
        echo -e "  ${CYAN}./company.sh start${RESET}    - 🚀 一键全部启动并自动接入 Paperclip"
        echo -e "  ${CYAN}./company.sh stop${RESET}     - 🛑 一键彻底关闭全部服务 (前端+后端+AI+Docker)"
        echo -e "  ${CYAN}./company.sh restart${RESET}  - 🔄 一键平滑重启所有服务"
        echo -e "  ${CYAN}./company.sh status${RESET}   - 📊 全息巡检运行状态与战绩奖金池"
        echo -e "  ${CYAN}./company.sh logs${RESET}     - 📜 实时查看日志 (支持 ai|backend|frontend|docker)"
        exit 1
        ;;
esac
