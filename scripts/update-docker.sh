#!/bin/bash
# VPS Docker 自动更新脚本

set -e  # 遇到错误立即退出

echo "🚀 开始更新 CRC_LRC Docker 服务..."
echo "================================"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 获取脚本所在目录的父目录（项目根目录）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo "项目目录: $PROJECT_DIR"
echo ""

# 1. 备份配置
echo -e "${YELLOW}步骤 1: 备份配置...${NC}"
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp config/config.yaml "$BACKUP_DIR/" 2>/dev/null || true
cp .env "$BACKUP_DIR/" 2>/dev/null || true
echo -e "${GREEN}✓ 配置已备份到 $BACKUP_DIR${NC}"

# 2. 记录当前版本
CURRENT_VERSION=$(git rev-parse HEAD)
echo -e "${YELLOW}步骤 2: 当前版本: ${CURRENT_VERSION:0:8}${NC}"

# 3. 暂存本地修改
echo -e "${YELLOW}步骤 3: 检查本地修改...${NC}"
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}发现本地修改，暂存中...${NC}"
    git stash save "自动更新前备份 $(date +%Y%m%d_%H%M%S)"
    STASHED=true
else
    STASHED=false
fi

# 4. 拉取最新代码
echo -e "${YELLOW}步骤 4: 拉取最新代码...${NC}"
git fetch origin
BRANCH=$(git rev-parse --abbrev-ref HEAD)
git pull origin "$BRANCH" || {
    echo -e "${RED}✗ Git 拉取失败！${NC}"
    exit 1
}
NEW_VERSION=$(git rev-parse HEAD)
echo -e "${GREEN}✓ 更新到版本: ${NEW_VERSION:0:8}${NC}"

# 5. 恢复本地修改
if [ "$STASHED" = true ]; then
    echo -e "${YELLOW}步骤 5: 恢复本地配置...${NC}"
    git stash pop || {
        echo -e "${YELLOW}⚠ 配置恢复有冲突，请手动解决${NC}"
    }
fi

# 6. 停止旧容器
echo -e "${YELLOW}步骤 6: 停止旧容器...${NC}"
docker-compose down
echo -e "${GREEN}✓ 容器已停止${NC}"

# 7. 清理旧镜像（可选）
read -p "是否清理旧镜像？(y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}步骤 7: 清理旧镜像...${NC}"
    docker image prune -f
    echo -e "${GREEN}✓ 旧镜像已清理${NC}"
else
    echo -e "${YELLOW}跳过清理旧镜像${NC}"
fi

# 8. 重新构建
echo -e "${YELLOW}步骤 8: 重新构建镜像...${NC}"
docker-compose build || {
    echo -e "${RED}✗ 构建失败！回滚...${NC}"
    git checkout "$CURRENT_VERSION"
    docker-compose up -d
    exit 1
}
echo -e "${GREEN}✓ 镜像构建成功${NC}"

# 9. 启动新容器
echo -e "${YELLOW}步骤 9: 启动新容器...${NC}"
docker-compose up -d || {
    echo -e "${RED}✗ 启动失败！回滚...${NC}"
    git checkout "$CURRENT_VERSION"
    docker-compose build
    docker-compose up -d
    exit 1
}
echo -e "${GREEN}✓ 容器已启动${NC}"

# 10. 等待服务就绪
echo -e "${YELLOW}步骤 10: 等待服务就绪...${NC}"
sleep 5

# 11. 健康检查
echo -e "${YELLOW}步骤 11: 健康检查...${NC}"
MAX_RETRIES=5
RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
    if curl -f http://localhost:8080/api/checksum?input=test > /dev/null 2>&1; then
        echo -e "${GREEN}✓ API 响应正常${NC}"
        break
    else
        RETRY=$((RETRY+1))
        if [ $RETRY -lt $MAX_RETRIES ]; then
            echo -e "${YELLOW}等待 API 就绪... ($RETRY/$MAX_RETRIES)${NC}"
            sleep 3
        else
            echo -e "${RED}✗ API 无响应！请检查日志${NC}"
            docker-compose logs --tail=50
            exit 1
        fi
    fi
done

# 12. 记录更新
echo "[$(date)] 更新: ${CURRENT_VERSION:0:8} -> ${NEW_VERSION:0:8}" >> logs/update.log 2>/dev/null || true

# 13. 完成
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✓ 更新完成！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "版本变化: ${CURRENT_VERSION:0:8} -> ${NEW_VERSION:0:8}"
echo "备份位置: $BACKUP_DIR"
echo ""
echo "查看日志: docker-compose logs -f"
echo "查看状态: docker-compose ps"
echo ""
