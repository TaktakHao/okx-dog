#!/bin/bash
# =============================================================================
# OKX-Dog v6.0 - 虚拟量化公司 Mac mini 一键混合拉起运维脚本
# 架构: 宿主机原生 (OKX-Dog + 本地 agy CLI) + 容器端 (Paperclip 组织架构)
# =============================================================================

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_DIR="$ROOT_DIR/okx-dog-ai"
BACKEND_DIR="$ROOT_DIR/okx-dog-backend"
FRONTEND_DIR="$ROOT_DIR/okx-dog-frontend"

GREEN="\033[92m"
CYAN="\033[96m"
YELLOW="\033[93m"
BOLD="\033[1m"
RESET="\033[0m"

echo -e "\n${BOLD}${CYAN}======================================================================${RESET}"
echo -e "${BOLD}${CYAN}   🚀 OKX-Dog v6.0 个人量化对冲基金 (Mac mini 混合集群一键拉起)   ${RESET}"
echo -e "${BOLD}${CYAN}======================================================================${RESET}\n"

# 1. 检查 macOS 宿主机与本地 agy CLI 状态
echo -e "${BOLD}[1/4] 检查宿主机环境与本地 CLI 状态...${RESET}"
if command -v agy &> /dev/null; then
    echo -e "  ${GREEN}✔ [OK] 检测到本地 Antigravity CLI (agy) 已就绪${RESET}"
else
    echo -e "  ${YELLOW}⚠ [提示] 未在 PATH 中找到 agy 命令，系统将以 OpenAI 协议兼容模式运行${RESET}"
fi

# 2. 检查 Docker / OrbStack 容器运行时并拉起 Paperclip
echo -e "\n${BOLD}[2/4] 启动 Paperclip 虚拟公司控制中枢 (Docker / OrbStack)...${RESET}"
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        echo -e "  正在启动 Paperclip 与 PostgreSQL 容器..."
        docker compose -f "$ROOT_DIR/docker-compose.paperclip.yml" up -d
        echo -e "  ${GREEN}✔ [OK] Paperclip 组织中枢已在后台启动 (端口: 3100)${RESET}"
    else
        echo -e "  ${YELLOW}⚠ [跳过] Docker 守护进程未启动，请启动 OrbStack 或 Docker Desktop 后运行 compose${RESET}"
    fi
else
    echo -e "  ${YELLOW}⚠ [跳过] 宿主机未安装 docker 命令，跳过容器启动${RESET}"
fi

# 3. 启动 OKX-Dog AI 决策网关与 CFO 战绩中枢 (端口: 8001)
echo -e "\n${BOLD}[3/4] 启动 OKX-Dog AI 网关与 CFO 战绩中枢 (端口: 8001)...${RESET}"
pkill -f "antigravity_server.py" 2>/dev/null || true
cd "$AI_DIR"
PYTHON_CMD="python3"
if [ -f "$ROOT_DIR/.agents/auditor_r2/venv/bin/python3" ]; then
    PYTHON_CMD="$ROOT_DIR/.agents/auditor_r2/venv/bin/python3"
fi

nohup $PYTHON_CMD antigravity_server.py > "$ROOT_DIR/ai_gateway.log" 2>&1 &
echo -e "  ${GREEN}✔ [OK] AI 决策网关已在后台运行 (PID: $!, 见 ai_gateway.log)${RESET}"

# 4. 启动 OKX-Dog 毫秒级交易与风控引擎 (端口: 8000)
echo -e "\n${BOLD}[4/4] 启动 OKX-Dog 7x24h 交易与硬风控底座 (端口: 8000)...${RESET}"
pkill -f "main:app" 2>/dev/null || true
cd "$BACKEND_DIR"
nohup $PYTHON_CMD -m uvicorn main:app --host 0.0.0.0 --port 8000 > "$ROOT_DIR/backend.log" 2>&1 &
echo -e "  ${GREEN}✔ [OK] 后端交易中枢已在后台运行 (PID: $!, 见 backend.log)${RESET}"

echo -e "\n${BOLD}${GREEN}======================================================================${RESET}"
echo -e "${BOLD}${GREEN}   🎉 虚拟量化公司已全部就绪！祝交易顺遂，利润长青！                ${RESET}"
echo -e "${BOLD}${GREEN}======================================================================${RESET}"
echo -e "  💼 ${BOLD}Paperclip 组织架构与任务看板${RESET}: ${CYAN}http://localhost:3100${RESET}"
echo -e "  📊 ${BOLD}OKX-Dog 暗黑交易大屏与自操盘${RESET}: ${CYAN}http://localhost:3000${RESET}"
echo -e "  🤖 ${BOLD}AI 决策网关与 CFO 配额 API${RESET}:   ${CYAN}http://localhost:8001/api/v1/paperclip/org${RESET}"
echo -e "  📜 ${BOLD}停止命令${RESET}: pkill -f 'uvicorn main:app' && pkill -f 'antigravity_server.py'\n"
