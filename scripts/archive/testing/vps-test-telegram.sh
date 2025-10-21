#!/bin/bash
# VPS Telegram 通知完整测试脚本

set -e

echo "🚀 ========== VPS Telegram 通知测试 =========="
echo ""

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📋 步骤 1: 启动 Docker 容器${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检测使用 docker-compose 还是 docker compose
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

echo "使用命令: $DOCKER_COMPOSE"
$DOCKER_COMPOSE down
$DOCKER_COMPOSE up -d --build

echo ""
echo -e "${BLUE}⏳ 等待容器启动...${NC}"
sleep 5

echo ""
echo -e "${BLUE}📋 步骤 2: 检查容器状态${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker ps | grep crc_lrc || echo "⚠️  容器未找到"

echo ""
echo -e "${BLUE}📋 步骤 3: 检查容器日志（启动信息）${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
CONTAINER_ID=$(docker ps | grep crc_lrc | awk '{print $1}')
if [ -n "$CONTAINER_ID" ]; then
    docker logs "$CONTAINER_ID" --tail 10
else
    echo "❌ 容器未运行"
    exit 1
fi

echo ""
echo -e "${BLUE}📋 步骤 4: 测试 API（会触发 Telegram 通知）${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "发送 API 请求..."

curl -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"VPS Telegram Test","method":"text"}' \
  -w "\n\nHTTP 状态码: %{http_code}\n" || echo "❌ API 请求失败"

echo ""
echo -e "${BLUE}📋 步骤 5: 查看实时日志（Telegram 相关）${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "查找 Telegram 通知日志..."
docker logs "$CONTAINER_ID" 2>&1 | grep -i "telegram\|notification" | tail -10 || echo "⚠️  未找到 Telegram 相关日志"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ 测试完成！${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 请检查 Telegram 是否收到通知消息！"
echo ""
echo "💡 如果没收到消息，运行以下命令查看完整日志："
echo "   docker logs -f $CONTAINER_ID"
echo ""
echo "🔍 或运行诊断脚本："
echo "   ./scripts/diagnose-telegram.sh"
