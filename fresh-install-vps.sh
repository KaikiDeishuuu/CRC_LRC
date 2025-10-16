#!/bin/bash
# VPS 完全重新安装脚本
# 删除旧安装，重新克隆，自动配置

set -e

echo "🔄 ========== VPS 完全重新安装 =========="
echo ""
echo "⚠️  警告：此脚本将删除现有安装并重新克隆代码"
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 获取当前路径
CURRENT_DIR=$(pwd)
PROJECT_NAME="CRC_LRC"

# 检查是否在项目目录中
if [[ $CURRENT_DIR == *"$PROJECT_NAME"* ]]; then
    # 在项目目录中，需要退出到父目录
    PARENT_DIR=$(dirname "$CURRENT_DIR")
    while [[ $PARENT_DIR == *"$PROJECT_NAME"* ]]; do
        PARENT_DIR=$(dirname "$PARENT_DIR")
    done
    cd "$PARENT_DIR"
    echo -e "${YELLOW}已切换到父目录: $(pwd)${NC}"
fi

PROJECT_DIR="$(pwd)/$PROJECT_NAME"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}步骤 1: 备份配置${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

BACKUP_DIR="/tmp/crc_lrc_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ -f "$PROJECT_DIR/config/config.yaml" ]; then
    cp "$PROJECT_DIR/config/config.yaml" "$BACKUP_DIR/"
    echo -e "${GREEN}✓ 已备份 config.yaml${NC}"
fi

if [ -f "$PROJECT_DIR/.env" ]; then
    cp "$PROJECT_DIR/.env" "$BACKUP_DIR/"
    echo -e "${GREEN}✓ 已备份 .env${NC}"
fi

echo -e "${CYAN}备份位置: $BACKUP_DIR${NC}"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}步骤 2: 停止并删除容器${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -d "$PROJECT_DIR" ]; then
    cd "$PROJECT_DIR"
    
    # 检测 docker compose 命令
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    else
        DOCKER_COMPOSE="docker compose"
    fi
    
    $DOCKER_COMPOSE down -v 2>/dev/null || true
    echo -e "${GREEN}✓ 容器已停止${NC}"
    
    cd ..
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}步骤 3: 删除旧目录${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -d "$PROJECT_DIR" ]; then
    rm -rf "$PROJECT_DIR"
    echo -e "${GREEN}✓ 旧目录已删除${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}步骤 4: 克隆最新代码${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

git clone -b DEV https://github.com/KaikiDeishuuu/CRC_LRC.git
echo -e "${GREEN}✓ 代码克隆完成${NC}"

cd "$PROJECT_NAME"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}步骤 5: 恢复配置${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -f "$BACKUP_DIR/config.yaml" ]; then
    cp "$BACKUP_DIR/config.yaml" config/config.yaml
    echo -e "${GREEN}✓ 已恢复 config.yaml${NC}"
else
    echo -e "${YELLOW}⚠️  没有找到配置备份，使用默认配置${NC}"
fi

if [ -f "$BACKUP_DIR/.env" ]; then
    cp "$BACKUP_DIR/.env" .env
    echo -e "${GREEN}✓ 已恢复 .env${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}步骤 6: 构建并启动${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 检测 docker compose 命令
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

echo "使用命令: $DOCKER_COMPOSE"
$DOCKER_COMPOSE up -d --build

echo ""
echo -e "${BLUE}⏳ 等待容器启动...${NC}"
sleep 5

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}步骤 7: 测试 API（触发 Telegram 通知）${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

sleep 3

RESPONSE=$(curl -s -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"Fresh Install Test - '$(date +%H:%M:%S)'","method":"text"}')

echo "API 响应:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}步骤 8: 查看日志${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

CONTAINER_ID=$(docker ps -q --filter "name=checksum-api")

if [ -n "$CONTAINER_ID" ]; then
    echo "容器 ID: $CONTAINER_ID"
    echo ""
    echo "最近 30 条日志:"
    docker logs "$CONTAINER_ID" --tail 30
    
    echo ""
    echo -e "${YELLOW}查找 Telegram 相关日志:${NC}"
    docker logs "$CONTAINER_ID" 2>&1 | grep -i "telegram\|notification" | tail -10 || {
        echo -e "${RED}未找到 Telegram 日志${NC}"
    }
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ 重新安装完成！${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 请检查 Telegram 是否收到通知！"
echo ""
echo "💡 实时查看日志:"
echo "   docker logs -f $CONTAINER_ID"
echo ""
echo "📂 配置备份位置: $BACKUP_DIR"
