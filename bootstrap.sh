#!/bin/bash
# =============================================================================
# OKX-Dog 新电脑一键快速拉取与环境初始化脚本
# 自动拉取前端、后端、AI、产品全部子仓库，并配置 Python/Node.js 运行环境
# =============================================================================

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_USER="TaktakHao"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "=================================================================="
echo "   🐕 OKX-Dog 新设备一键快速拉取与环境自动化配置引导"
echo "=================================================================="
echo -e "${NC}"

# 1. 批量克隆/更新 4 个核心独立仓库
REPOS=("okx-dog-frontend" "okx-dog-backend" "okx-dog-ai" "okx-dog-product")

for REPO in "${REPOS[@]}"; do
    TARGET_DIR="$ROOT_DIR/$REPO"
    REPO_URL="https://github.com/$GITHUB_USER/$REPO.git"
    
    if [ -d "$TARGET_DIR/.git" ]; then
        echo -e "${BLUE}[更新] 正在拉取最新代码: ${CYAN}$REPO${NC}..."
        (cd "$TARGET_DIR" && git pull origin main)
    else
        echo -e "${BLUE}[克隆] 正在拉取独立仓库: ${CYAN}$REPO${NC}..."
        git clone "$REPO_URL" "$TARGET_DIR"
    fi
done

echo -e "\n${GREEN}[✓] 全部 4 个核心项目仓库已成功拉取就绪！${NC}\n"

# 2. Python 虚拟环境自动化配置
echo -e "${BLUE}[环境配置 1/2] 正在配置 Python 3 虚拟运行环境...${NC}"
if [ ! -d "$ROOT_DIR/.venv" ]; then
    if command -v python3 &> /dev/null; then
        python3 -m venv "$ROOT_DIR/.venv"
        echo -e "${GREEN}[✓] 创建虚拟环境 .venv 成功${NC}"
    else
        echo -e "${RED}[错误] 未检测到 python3，请先安装 Python 3.9+${NC}"
        exit 1
    fi
fi

PYTHON_PIP="$ROOT_DIR/.venv/bin/pip"
echo -e "${YELLOW}正在安装后端与 AI 依赖包 (requirements.txt)...${NC}"
$PYTHON_PIP install --upgrade pip > /dev/null 2>&1 || true
if [ -f "$ROOT_DIR/okx-dog-backend/requirements.txt" ]; then
    $PYTHON_PIP install -r "$ROOT_DIR/okx-dog-backend/requirements.txt"
fi
if [ -f "$ROOT_DIR/okx-dog-ai/requirements.txt" ]; then
    $PYTHON_PIP install -r "$ROOT_DIR/okx-dog-ai/requirements.txt"
fi
echo -e "${GREEN}[✓] Python 后端与 AI 依赖安装完成${NC}"

# 3. 前端 Node.js 依赖配置
echo -e "\n${BLUE}[环境配置 2/2] 正在配置前端 Node.js 依赖...${NC}"
if ! command -v npm &> /dev/null; then
    echo -e "${RED}[错误] 未检测到 npm / Node.js，请先安装 Node.js 18+${NC}"
    exit 1
fi

if [ -d "$ROOT_DIR/okx-dog-frontend" ]; then
    echo -e "${YELLOW}正在安装前端 npm 依赖包...${NC}"
    (cd "$ROOT_DIR/okx-dog-frontend" && npm install)
    echo -e "${GREEN}[✓] 前端依赖包安装完成${NC}"
fi

echo -e "\n${GREEN}=================================================================="
echo "   🎉 OKX-Dog 全部环境与代码已 100% 准备就绪！"
echo "   一键启动系统只需执行:"
echo "   👉 ${CYAN}bash start.sh${GREEN}"
echo "==================================================================${NC}\n"
