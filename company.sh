#!/bin/bash
# =============================================================================
# OKX-Dog v6.0 - 虚拟量化对冲基金与 Hermes Agent 统一全生命周期运维主控脚本
# 用法:
#   ./company.sh start    # 一键拉起全套系统 (Hermes 多角色 + AI网关 + 后端 + 前端)
#   ./company.sh stop     # 一键平滑彻底关闭全部服务 (前端 + 后端 + AI + Hermes)
#   ./company.sh restart  # 一键平滑重启全套系统
#   ./company.sh status   # 一键全息巡检系统运行状态与服务健康度
#   ./company.sh logs     # 实时查看系统运行日志 (可加参数: ai | backend | frontend | hermes)
#
# Hermes 运行方式:
#   以 Mac mini 宿主机原生进程运行，支持统一通讯网关 (hermes gateway) 与多角色配置。
#   数据与技能位于项目内 hermes/，完全告别沉重的外部数据库与 Web 看板。
# =============================================================================

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_DIR="$ROOT_DIR/okx-dog-ai"
BACKEND_DIR="$ROOT_DIR/okx-dog-backend"
FRONTEND_DIR="$ROOT_DIR/okx-dog-frontend"
HERMES_DIR="$ROOT_DIR/hermes"
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
if [ -f "$ROOT_DIR/.agents/auditor_r2/venv/bin/python3" ]; then
    PYTHON_CMD="$ROOT_DIR/.agents/auditor_r2/venv/bin/python3"
elif [ -f "$ROOT_DIR/.venv/bin/python3" ]; then
    PYTHON_CMD="$ROOT_DIR/.venv/bin/python3"
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

# -----------------------------------------------------------------------------
# Hermes Agent 宿主机进程、Web 看板与远程机器管理
# -----------------------------------------------------------------------------
HERMES_PORT="${HERMES_PORT:-8088}"
HERMES_DASHBOARD_PORT="${HERMES_DASHBOARD_PORT:-9119}"
HERMES_REMOTE_HOST="${HERMES_REMOTE_HOST:-}"
HERMES_GATEWAY_LOG="$LOG_DIR/hermes_gateway.log"
HERMES_DASHBOARD_LOG="$LOG_DIR/hermes_dashboard.log"
HERMES_TUNNEL_PID="$PID_DIR/hermes_tunnel.pid"

hermes_gateway_healthy() {
    if lsof -ti tcp:"$HERMES_PORT" &> /dev/null; then
        return 0
    fi
    return 1
}

hermes_dashboard_healthy() {
    if lsof -ti tcp:"$HERMES_DASHBOARD_PORT" &> /dev/null; then
        return 0
    fi
    return 1
}

start_remote_hermes() {
    local remote="$1"
    echo -e "  ${CYAN}正在连接远端电脑 ($remote) 启动 Hermes 环境...${RESET}"
    
    # 检查 SSH 连通性
    if ! ssh -o BatchMode=yes -o ConnectTimeout=4 "$remote" "which hermes" &> /dev/null; then
        echo -e "  ${YELLOW}⚠ 无法免密连接远端主机 $remote 或远端未找到 hermes 命令。${RESET}"
        echo -e "    ${DIM}请确保配置了 ssh 密钥免密登录，且远端安装了 Hermes CLI。${RESET}"
        return 1
    fi

    # 在远端启动 gateway 与 dashboard
    echo -e "  正在远端 ($remote) 唤起 Hermes Gateway (8088) 与 Dashboard (9119)..."
    ssh "$remote" "nohup hermes gateway --port $HERMES_PORT >/dev/null 2>&1 & nohup hermes dashboard --port $HERMES_DASHBOARD_PORT >/dev/null 2>&1 &" || true
    sleep 1

    # 建立本地 SSH 端口转发隧道
    kill_port_pids "$HERMES_PORT"
    kill_port_pids "$HERMES_DASHBOARD_PORT"
    echo -e "  正在建立本地直连远端的安全 SSH 隧道 (9119 -> $remote:9119, 8088 -> $remote:8088)..."
    ssh -N -f -o ExitOnForwardFailure=yes -L ${HERMES_DASHBOARD_PORT}:127.0.0.1:${HERMES_DASHBOARD_PORT} -L ${HERMES_PORT}:127.0.0.1:${HERMES_PORT} "$remote"
    
    # 记录隧道 PID
    local tpid=$(pgrep -f "ssh.*${HERMES_DASHBOARD_PORT}:127.0.0.1:${HERMES_DASHBOARD_PORT}" | head -n 1 || true)
    if [ -n "$tpid" ]; then
        echo "$tpid" > "$HERMES_TUNNEL_PID"
    fi
    echo -e "  ${GREEN}✔ [OK] 远端 Hermes 已成功映射到本地！${RESET}"
    echo -e "    ${CYAN}👉 Web 看板: http://localhost:${HERMES_DASHBOARD_PORT}${RESET}"
    return 0
}

start_hermes() {
    # 1. 如果指定了远程主机，则走远程拉起与隧道映射
    if [ -n "$HERMES_REMOTE_HOST" ]; then
        start_remote_hermes "$HERMES_REMOTE_HOST" && return 0
    fi

    # 2. 本地模式：检测全局 hermes 命令
    if ! command -v hermes &> /dev/null; then
        echo -e "  ${YELLOW}ℹ [跳过本地后台拉起] 当前机器未安装全局 hermes CLI。${RESET}"
        echo -e "    ${DIM}• 若在另一台电脑上部署，可指定 HERMES_REMOTE_HOST=user@ip 一键远程唤起${RESET}"
        echo -e "    ${DIM}• 若在本机安装，可执行: curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash${RESET}"
        return 0
    fi

    # 启动 Gateway
    if hermes_gateway_healthy; then
        echo -e "  ${GREEN}✔ [OK] Hermes Gateway 已在运行 (端口 $HERMES_PORT)${RESET}"
    else
        kill_port_pids "$HERMES_PORT"
        echo -e "  正在启动 Hermes Gateway 通讯网关 (端口: $HERMES_PORT)..."
        nohup hermes gateway --port "$HERMES_PORT" < /dev/null > "$HERMES_GATEWAY_LOG" 2>&1 &
        echo $! > "$PID_DIR/hermes_gateway.pid"
        echo -e "  ${GREEN}✔ [OK] Hermes Gateway 已在后台运行 (PID: $!, 见 hermes_gateway.log)${RESET}"
    fi

    # 启动 Web Dashboard 看板 (9119)
    if hermes_dashboard_healthy; then
        echo -e "  ${GREEN}✔ [OK] Hermes Web 看板已在运行 (端口 $HERMES_DASHBOARD_PORT)${RESET}"
    else
        kill_port_pids "$HERMES_DASHBOARD_PORT"
        echo -e "  正在启动 Hermes Web Dashboard 看板 (端口: $HERMES_DASHBOARD_PORT)..."
        nohup hermes dashboard --port "$HERMES_DASHBOARD_PORT" < /dev/null > "$HERMES_DASHBOARD_LOG" 2>&1 &
        echo $! > "$PID_DIR/hermes_dashboard.pid"
        echo -e "  ${GREEN}✔ [OK] Hermes Web 看板已启动 -> http://localhost:$HERMES_DASHBOARD_PORT${RESET}"
    fi
}

stop_hermes() {
    # 清理远程隧道
    if [ -f "$HERMES_TUNNEL_PID" ]; then
        TPID=$(cat "$HERMES_TUNNEL_PID" 2>/dev/null || true)
        if [ -n "$TPID" ]; then
            kill "$TPID" 2>/dev/null || true
        fi
        rm -f "$HERMES_TUNNEL_PID"
    fi
    pkill -f "ssh.*${HERMES_DASHBOARD_PORT}:127.0.0.1" 2>/dev/null || true

    # 清理本地 Gateway
    if [ -f "$PID_DIR/hermes_gateway.pid" ]; then
        H_PID=$(cat "$PID_DIR/hermes_gateway.pid")
        kill -15 "$H_PID" 2>/dev/null || true
        rm -f "$PID_DIR/hermes_gateway.pid"
    fi
    pkill -f "hermes gateway" 2>/dev/null || true
    kill_port_pids "$HERMES_PORT"

    # 清理本地 Dashboard
    if [ -f "$PID_DIR/hermes_dashboard.pid" ]; then
        D_PID=$(cat "$PID_DIR/hermes_dashboard.pid")
        kill -15 "$D_PID" 2>/dev/null || true
        rm -f "$PID_DIR/hermes_dashboard.pid"
    fi
    pkill -f "hermes dashboard" 2>/dev/null || true
    kill_port_pids "$HERMES_DASHBOARD_PORT"
}

start_company() {
    echo -e "\n${BOLD}${CYAN}======================================================================${RESET}"
    echo -e "${BOLD}${CYAN}   🚀 OKX-Dog v6.0 虚拟量化对冲基金 (Hermes Edition) - 开机拉起        ${RESET}"
    echo -e "${BOLD}${CYAN}======================================================================${RESET}\n"

    # 1. 检查宿主机环境与 Hermes 多角色就绪状态
    echo -e "${BOLD}[1/5] 初始化与校验 Hermes 6 大虚拟员工多角色就绪状态...${RESET}"
    $PYTHON_CMD "$ROOT_DIR/scripts/setup_hermes.py"

    # 2. 启动 AI 决策网关与 CFO 战绩引擎 (8001)
    echo -e "\n${BOLD}[2/5] 启动 AI 决策大脑与 CFO 战绩激励引擎 (端口: 8001)...${RESET}"
    kill_port_pids 8001
    pkill -f "antigravity_server.py" 2>/dev/null || true
    cd "$AI_DIR"
    export PYTHONPATH="$ROOT_DIR:$AI_DIR:$BACKEND_DIR:$PYTHONPATH"
    nohup $PYTHON_CMD antigravity_server.py < /dev/null > "$LOG_DIR/ai_gateway.log" 2>&1 &
    AI_PID=$!
    echo $AI_PID > "$PID_DIR/ai_gateway.pid"
    echo -e "  ${GREEN}✔ [OK] AI 决策网关已在后台运行 (PID: $AI_PID, 见 ai_gateway.log)${RESET}"

    for i in {1..15}; do
        if curl -s http://127.0.0.1:8001/api/v1/hermes/org > /dev/null 2>&1 || curl -s http://127.0.0.1:8001/api/v1/health > /dev/null 2>&1; then
            echo -e "  ${GREEN}✔ [健康] AI 决策网关已通过接口探活${RESET}"
            break
        fi
        sleep 0.5
    done

    # 3. 启动 7x24h 交易中枢与不可绕过硬风控底座 (8000)
    echo -e "\n${BOLD}[3/5] 启动 7x24h 毫秒级交易与 5 重不可绕过硬风控底座 (端口: 8000)...${RESET}"
    kill_port_pids 8000
    pkill -f "uvicorn main:app" 2>/dev/null || true
    cd "$BACKEND_DIR"
    nohup $PYTHON_CMD -m uvicorn main:app --host 0.0.0.0 --port 8000 < /dev/null > "$LOG_DIR/backend.log" 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > "$PID_DIR/backend.pid"
    echo -e "  ${GREEN}✔ [OK] 交易核心服务已在后台运行 (PID: $BACKEND_PID, 见 backend.log)${RESET}"

    for i in {1..15}; do
        if curl -s http://127.0.0.1:8000/api/v1/health > /dev/null 2>&1; then
            echo -e "  ${GREEN}✔ [健康] 后端交易底座已通过接口探活${RESET}"
            break
        fi
        sleep 0.5
    done

    # 4. 启动 前端 Vite 暗黑交易操盘大屏 (3000)
    echo -e "\n${BOLD}[4/5] 启动 前端金融级暗黑交易操盘大屏 (端口: 3000)...${RESET}"
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

    # 5. 启动 Hermes Gateway 通讯网关 (8088) 与 Web 看板 (9119)
    echo -e "\n${BOLD}[5/5] 启动 Hermes 通讯网关与 Web 看板 (手机通讯与技能管理)...${RESET}"
    cd "$ROOT_DIR"
    start_hermes

    echo -e "\n${BOLD}${GREEN}======================================================================${RESET}"
    echo -e "${BOLD}${GREEN}   🎉 全套系统已成功一键拉起！Hermes 6 大员工全天候守护中             ${RESET}"
    echo -e "${BOLD}${GREEN}======================================================================${RESET}"
    echo -e "  🌐 ${BOLD}暗黑交易控制台 (投资人操盘大屏)${RESET}: ${CYAN}http://localhost:3000${RESET}"
    echo -e "  💻 ${BOLD}Hermes Web 管理看板 (Skills/网关)${RESET}: ${CYAN}http://localhost:$HERMES_DASHBOARD_PORT${RESET}"
    echo -e "  ⚡ ${BOLD}FastAPI 后端交易与风控接口${RESET}:     ${CYAN}http://localhost:8000/docs${RESET}"
    echo -e "  🤖 ${BOLD}AI 决策网关与 CFO 战绩 API${RESET}:     ${CYAN}http://localhost:8001/api/v1/hermes/org${RESET}"
    echo -e "  💬 ${BOLD}Hermes 多角色技能包与配置${RESET}:     ${CYAN}$HERMES_DIR${RESET}"
    echo -e "  ------------------------------------------------------------------"
    echo -e "  📌 ${BOLD}查看运行状态${RESET}: ${YELLOW}./company.sh status${RESET}"
    echo -e "  🛑 ${BOLD}一键彻底关闭${RESET}: ${RED}./company.sh stop${RESET}"
    echo -e "  📜 ${BOLD}实时查看日志${RESET}: ${CYAN}./company.sh logs [backend|ai|frontend|hermes|dashboard]${RESET}\n"
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

    # 4. 停止 Hermes Gateway 与 Dashboard
    echo -e "\n${BOLD}[4/4] 停止 Hermes 通讯网关与 Web 看板 (端口: $HERMES_PORT, $HERMES_DASHBOARD_PORT)...${RESET}"
    stop_hermes
    echo -e "  ${GREEN}✔ Hermes 网关与看板已安全停止${RESET}"

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
    if curl -s http://127.0.0.1:8001/api/v1/hermes/org &> /dev/null || curl -s http://127.0.0.1:8001/api/v1/health &> /dev/null; then
        echo -e "${GREEN}● 运行中 (HEALTHY)${RESET} -> http://localhost:8001"
    else
        echo -e "${RED}○ 已停止 (STOPPED)${RESET}"
    fi

    # Hermes Web 看板状态 (9119)
    echo -n "  • Hermes Web 看板 (Port $HERMES_DASHBOARD_PORT): "
    if hermes_dashboard_healthy; then
        if [ -f "$HERMES_TUNNEL_PID" ]; then
            echo -e "${GREEN}● 运行中 (SSH 远端映射)${RESET} -> http://localhost:$HERMES_DASHBOARD_PORT"
        else
            echo -e "${GREEN}● 运行中 (本地)${RESET} -> http://localhost:$HERMES_DASHBOARD_PORT"
        fi
    else
        echo -e "${YELLOW}○ 未启动 (执行 ./company.sh start 或 hermes dashboard 唤醒)${RESET}"
    fi

    # Hermes 通讯网关状态 (8088)
    echo -n "  • Hermes 通讯网关 (Port $HERMES_PORT): "
    if hermes_gateway_healthy; then
        if [ -f "$HERMES_TUNNEL_PID" ]; then
            echo -e "${GREEN}● 运行中 (SSH 远端映射)${RESET} -> http://localhost:$HERMES_PORT"
        else
            echo -e "${GREEN}● 运行中 (本地)${RESET} -> http://localhost:$HERMES_PORT"
        fi
    else
        echo -e "${YELLOW}○ 未启动 (本地技能随时就绪)${RESET}"
    fi

    # Hermes 6 大员工多角色就绪情况
    echo -n "  • Hermes 6 大员工角色状态:   "
    if [ -d "$HERMES_DIR/personas" ] && [ $(ls "$HERMES_DIR/personas"/*.md 2>/dev/null | wc -l) -eq 6 ]; then
        echo -e "${GREEN}✔ 6 大员工已全量登记在册 (陈守拙/张大炮/周铁山/林望远/赵小刀/钱公道)${RESET}"
    else
        echo -e "${YELLOW}○ 待初始化 (执行 ./company.sh start 将自动就绪)${RESET}"
    fi

    # 查看 CFO 战绩激励简讯
    if curl -s http://127.0.0.1:8001/api/v1/hermes/quota/overview &> /dev/null; then
        echo -e "\n  ${BOLD}🏆 CFO 战绩激励奖金池概览 (长效分红制):${RESET}"
        curl -s http://127.0.0.1:8001/api/v1/hermes/quota/overview | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    if "data" in d: d = d["data"]
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
        hermes)
            echo -e "${CYAN}正在追踪 Hermes 网关日志 (hermes_gateway.log)...${RESET}"
            tail -f "$HERMES_GATEWAY_LOG"
            ;;
        dashboard)
            echo -e "${CYAN}正在追踪 Hermes Web 看板日志 (hermes_dashboard.log)...${RESET}"
            tail -f "$HERMES_DASHBOARD_LOG"
            ;;
        *)
            echo -e "${CYAN}可用日志命令: ./company.sh logs [ai | backend | frontend | hermes | dashboard]${RESET}"
            echo -e "${CYAN}默认显示后端与AI网关最近 10 行日志:${RESET}\n"
            echo -e "--- [AI 网关最近日志] ---"
            tail -n 10 "$LOG_DIR/ai_gateway.log" 2>/dev/null || true
            echo -e "\n--- [后端最近日志] ---"
            tail -n 10 "$LOG_DIR/backend.log" 2>/dev/null || true
            ;;
    esac
}

case "$1" in
    start)
        # 支持传参指定远端机器: ./company.sh start user@192.168.1.100
        if [ -n "$2" ]; then
            export HERMES_REMOTE_HOST="$2"
        fi
        start_company
        ;;
    stop)
        stop_company
        ;;
    restart)
        if [ -n "$2" ]; then
            export HERMES_REMOTE_HOST="$2"
        fi
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
    cli)
        # 本地 CLI / TUI 交互式入口
        PERSONA_ARG="${2:-}"
        PERSONA_FILE=""
        case "$PERSONA_ARG" in
            chen|ceo) PERSONA_FILE="$HERMES_DIR/personas/chen_shouzhuo.md" ;;
            zhou|risk) PERSONA_FILE="$HERMES_DIR/personas/zhou_tieshan.md" ;;
            zhang|bull) PERSONA_FILE="$HERMES_DIR/personas/zhang_dapao.md" ;;
            zhao|order) PERSONA_FILE="$HERMES_DIR/personas/zhao_xiaodao.md" ;;
            lin|macro) PERSONA_FILE="$HERMES_DIR/personas/lin_wangyuan.md" ;;
            qian|cfo) PERSONA_FILE="$HERMES_DIR/personas/qian_gongdao.md" ;;
            *) ;;
        esac

        echo -e "${CYAN}🚀 正在启动 Hermes 本地极客交互式终端 (挂载 okxdog_ops 技能)...${RESET}"
        if [ -n "$PERSONA_FILE" ] && [ -f "$PERSONA_FILE" ]; then
            echo -e "${GREEN}✔ 已装载员工专属设定: $(basename $PERSONA_FILE)${RESET}\n"
            exec hermes --tui -s okxdog_ops --in "$ROOT_DIR"
        else
            echo -e "${DIM}提示: 可指定专属员工入场: ./company.sh cli [chen|zhou|zhang|zhao|lin|qian]${RESET}\n"
            exec hermes --tui -s okxdog_ops --in "$ROOT_DIR"
        fi
        ;;
    remote-hermes)
        # 针对另一台电脑的独立操作: ./company.sh remote-hermes <user@ip> [start|stop|status]
        REMOTE_TARGET="$2"
        REMOTE_ACT="${3:-start}"
        if [ -z "$REMOTE_TARGET" ]; then
            echo -e "${RED}错误: 请指定远端主机地址，例如: ./company.sh remote-hermes user@192.168.1.100 start${RESET}"
            exit 1
        fi
        case "$REMOTE_ACT" in
            start)
                start_remote_hermes "$REMOTE_TARGET"
                ;;
            stop)
                stop_hermes
                ssh "$REMOTE_TARGET" "pkill -f 'hermes gateway'; pkill -f 'hermes dashboard'" 2>/dev/null || true
                echo -e "  ${GREEN}✔ 远端 $REMOTE_TARGET 上的 Hermes 服务已停止${RESET}"
                ;;
            status)
                echo -e "  正在查询远端主机 $REMOTE_TARGET 状态..."
                ssh "$REMOTE_TARGET" "hermes --version 2>/dev/null; ps aux | grep -E 'hermes gateway|hermes dashboard' | grep -v grep || echo '未在运行'"
                ;;
        esac
        ;;
    *)
        echo -e "${BOLD}使用说明:${RESET}"
        echo -e "  ${CYAN}./company.sh start [remote_host]${RESET}    - 🚀 一键启动系统 (支持本地或远端 Hermes，如 user@ip)"
        echo -e "  ${CYAN}./company.sh stop${RESET}                  - 🛑 一键彻底关闭全部服务 (前端+后端+AI+Hermes+看板)"
        echo -e "  ${CYAN}./company.sh restart [remote_host]${RESET} - 🔄 一键平滑重启所有服务"
        echo -e "  ${CYAN}./company.sh status${RESET}                - 📊 全息巡检运行状态、Web 看板与战绩奖金池"
        echo -e "  ${CYAN}./company.sh logs [target]${RESET}         - 📜 实时查看日志 (ai|backend|frontend|hermes|dashboard)"
        echo -e "  ${CYAN}./company.sh cli [chen|zhou|...]${RESET}   - 💬 一键启动本地 CLI/TUI 与虚拟员工对话"
        echo -e "  ${CYAN}./company.sh remote-hermes <user@ip> [start|stop|status]${RESET} - 🌐 独立管理另一台电脑上的 Hermes"
        exit 1
        ;;
esac
