#!/bin/bash
# =============================================================================
# OKX-Dog 一键更新所有子仓库最新代码
# =============================================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOS=("okx-dog-frontend" "okx-dog-backend" "okx-dog-ai" "okx-dog-product")

echo "正在拉取所有子仓库最新代码..."
for REPO in "${REPOS[@]}"; do
    if [ -d "$ROOT_DIR/$REPO/.git" ]; then
        echo ">>> 更新 $REPO..."
        (cd "$ROOT_DIR/$REPO" && git pull origin main)
    fi
done
echo "全部子仓库更新完毕！"
