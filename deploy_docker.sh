#!/bin/bash
# =============================================================================
# OKX-Dog 个人量化交易系统 - Docker 一键重新构建与部署脚本
# 模块: deploy_docker.sh
# 作用: 一键构建前后端镜像、平滑拉起容器、健康检查与状态汇报
# =============================================================================

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# 终端色彩定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${CYAN}${BOLD}"
echo "=================================================================="
echo "   🐕 OKX-Dog Docker 容器化一键重新部署中枢 (Production Deploy)   "
echo "=================================================================="
echo -e "${NC}"

# 参数解析
NO_CACHE=""
PULL_GIT=false
FOLLOW_LOGS=false
ONLY_RESTART=false
ACTION_DOWN=false

for arg in "$@"; do
    case $arg in
        --no-cache|-B)
            NO_CACHE="--no-cache"
            ;;
        --pull|-p)
            PULL_GIT=true
            ;;
        --logs|-l)
            FOLLOW_LOGS=true
            ;;
        --restart|-r)
            ONLY_RESTART=true
            ;;
        --down|-d)
            ACTION_DOWN=true
            ;;
        --help|-h)
            echo "用法: ./deploy_docker.sh [选项]"
            echo ""
            echo "选项:"
            echo "  -B, --no-cache    禁用 Docker 构建缓存，强制从头编译"
            echo "  -p, --pull        部署前自动 git pull 更新所有子仓库"
            echo "  -r, --restart     仅快速重启现有容器 (不重新 build 镜像)"
            echo "  -d, --down        停止并销毁已运行的容器与网络"
            echo "  -l, --logs        启动后自动持续输出容器实时日志"
            echo "  -h, --help        显示帮助信息"
            echo ""
            exit 0
            ;;
    esac
done

# 0. 如果指定了停止销毁
if [ "$ACTION_DOWN" = true ]; then
    echo -e "${YELLOW}[停止] 正在停止并销毁 OKX-Dog 容器...${NC}"
    docker compose down
    echo -e "${GREEN}[完成] OKX-Dog 容器已停止。${NC}"
    exit 0
fi

# 1. 检查 Docker 守护进程是否在运行
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}[错误] Docker 守护进程未运行，请先启动 Docker Desktop 或 Docker Engine！${NC}"
    exit 1
fi
echo -e "${BLUE}[1/5] Docker 引擎运行正常: ${GREEN}$(docker --version)${NC}"

# 2. 是否拉取最新代码
if [ "$PULL_GIT" = true ]; then
    echo -e "${BLUE}[2/5] 正在拉取子仓库最新代码...${NC}"
    if [ -f "$ROOT_DIR/update_all.sh" ]; then
        bash "$ROOT_DIR/update_all.sh"
    fi
else
    echo -e "${BLUE}[2/5] 跳过 Git 拉取 (如需拉取可加参数: ./deploy_docker.sh --pull)${NC}"
fi

# 3. 停止或重新构建
if [ "$ONLY_RESTART" = true ]; then
    echo -e "${BLUE}[3/5] 快速重启容器 (不重编镜像)...${NC}"
    docker compose restart
else
    echo -e "${BLUE}[3/5] 重新构建并启动容器 (Build & Up)...${NC}"
    if [ -n "$NO_CACHE" ]; then
        echo -e "${YELLOW}>>> 采用 --no-cache 强制无缓存重编模式${NC}"
    fi
    docker compose up -d --build $NO_CACHE
fi

# 4. 健康检查探针轮询
echo -e "${BLUE}[4/5] 正在等待容器服务健康就绪...${NC}"
BACKEND_HEALTHY=false
for i in {1..30}; do
    if curl -s -f http://127.0.0.1:8000/api/v1/health > /dev/null 2>&1; then
        BACKEND_HEALTHY=true
        break
    fi
    echo -ne "${YELLOW}⏳ 等待后端服务就绪 (${i}/30s)...\r${NC}"
    sleep 1
done
echo ""

if [ "$BACKEND_HEALTHY" = true ]; then
    echo -e "${GREEN}✅ 后端 FastAPI 核心服务健康检查通过！${NC}"
else
    echo -e "${RED}⚠️ 后端健康检查超时，请检查后端容器日志: docker compose logs backend${NC}"
fi

# 5. 打印当前服务状态与面板访问入口
echo -e "\n${BLUE}[5/5] 当前容器运行状态概览:${NC}"
docker compose ps

echo -e "\n${GREEN}=================================================================="
echo -e "   🚀 OKX-Dog Docker 容器服务已成功部署上线！"
echo -e "   🌐 前端控制台:    ${CYAN}http://localhost:3000${GREEN}"
echo -e "   ⚡ 后端 API 接口:  ${CYAN}http://localhost:8000/docs${GREEN}"
echo -e "   🩺 健康检查端点:  ${CYAN}http://localhost:8000/api/v1/health${GREEN}"
echo -e "   📊 数据持久化:    ${CYAN}okx-dog-backend/data (挂载中)${GREEN}"
echo -e "==================================================================${NC}"
echo -e "💡 实用命令提示:"
echo -e "   - 查看实时日志:   ${YELLOW}docker compose logs -f${NC} (或运行 ./deploy_docker.sh -l)"
echo -e "   - 停止服务容器:   ${YELLOW}docker compose down${NC} (或运行 ./deploy_docker.sh -d)"
echo -e "   - 快速重新构建:   ${YELLOW}./deploy_docker.sh${NC}"
echo ""

if [ "$FOLLOW_LOGS" = true ]; then
    echo -e "${CYAN}正在监听容器实时日志 (按 Ctrl+C 退出日志追踪)...${NC}\n"
    docker compose logs -f
fi
