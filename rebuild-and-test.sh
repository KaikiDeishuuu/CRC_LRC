#!/bin/bash
# VPS 完整重新部署脚本（包含 Telegram 通知功能）

set -e

echo "🚀 ========== 完整重新部署 =========="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 检测 docker compose 命令
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

echo -e "${BLUE}📋 步骤 1: 停止并删除旧容器${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$DOCKER_COMPOSE down -v
docker system prune -f

echo ""
echo -e "${BLUE}📋 步骤 2: 重新构建镜像（强制不使用缓存）${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$DOCKER_COMPOSE build --no-cache

echo ""
echo -e "${BLUE}📋 步骤 3: 启动新容器${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$DOCKER_COMPOSE up -d

echo ""
echo -e "${BLUE}⏳ 等待容器启动...${NC}"
sleep 5

echo ""
echo -e "${BLUE}📋 步骤 4: 检查容器状态${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker ps | grep checksum-api

CONTAINER_ID=$(docker ps -q --filter "name=checksum-api")
if [ -z "$CONTAINER_ID" ]; then
    echo -e "${RED}❌ 容器启动失败！${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 容器运行中: $CONTAINER_ID${NC}"

echo ""
echo -e "${BLUE}📋 步骤 5: 查看启动日志${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker logs "$CONTAINER_ID" --tail 20

echo ""
echo -e "${BLUE}📋 步骤 6: 测试 API（触发 Telegram 通知）${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "发送测试请求..."

RESPONSE=$(curl -s -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"VPS Rebuild Test - '$(date +%H:%M:%S)'","method":"text"}')

echo "API 响应:"
echo "$RESPONSE" | jq '.' || echo "$RESPONSE"

echo ""
echo -e "${BLUE}📋 步骤 7: 查看实时日志（Telegram 相关）${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "等待 2 秒让通知发送..."
sleep 2

echo "查找 Telegram 相关日志:"
docker logs "$CONTAINER_ID" 2>&1 | grep -i "telegram\|notification" | tail -20 || {
    echo -e "${YELLOW}⚠️  未找到 Telegram 日志，显示最近 30 条日志:${NC}"
    docker logs "$CONTAINER_ID" --tail 30
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ 部署完成！${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 请检查 Telegram 是否收到通知！"
echo ""
echo "💡 实时查看日志:"
echo "   docker logs -f $CONTAINER_ID"
echo ""
echo "🔍 如果还是没有通知，运行诊断:"
echo "   ./scripts/diagnose-telegram.sh"
