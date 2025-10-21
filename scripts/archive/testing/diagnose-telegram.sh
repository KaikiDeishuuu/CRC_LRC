#!/bin/bash
# Telegram 通知诊断脚本
# 检查所有可能导致通知失败的问题

set -e

echo "🔍 ========== Telegram 通知诊断 =========="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查函数
check_pass() {
    echo -e "${GREEN}✅ $1${NC}"
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

check_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 1. 检查 config.yaml
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 1. 检查 config.yaml 配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "config/config.yaml" ]; then
    check_pass "config.yaml 文件存在"
    
    # 检查 enabled 状态
    ENABLED=$(grep -A 5 "telegram:" config/config.yaml | grep "enabled:" | awk '{print $2}')
    if [ "$ENABLED" == "true" ]; then
        check_pass "Telegram 通知已启用 (enabled: true)"
    else
        check_fail "Telegram 通知未启用！当前: enabled: $ENABLED"
        echo "   修复方法: 编辑 config/config.yaml，设置 telegram.enabled: true"
    fi
    
    # 检查 token
    TOKEN=$(grep -A 5 "telegram:" config/config.yaml | grep "botToken:" | awk '{print $2}' | tr -d '"')
    if [ "$TOKEN" == "YOUR_BOT_TOKEN_HERE" ] || [ -z "$TOKEN" ]; then
        check_fail "Bot Token 未配置！当前: $TOKEN"
        echo "   修复方法: 设置真实的 Bot Token"
    else
        TOKEN_PREFIX="${TOKEN:0:10}"
        check_pass "Bot Token 已配置 ($TOKEN_PREFIX...)"
    fi
    
    # 检查 chatId
    CHATID=$(grep -A 5 "telegram:" config/config.yaml | grep "chatId:" | awk '{print $2}' | tr -d '"')
    if [ "$CHATID" == "YOUR_CHAT_ID_HERE" ] || [ -z "$CHATID" ]; then
        check_fail "Chat ID 未配置！当前: $CHATID"
        echo "   修复方法: 设置真实的 Chat ID"
    else
        check_pass "Chat ID 已配置 ($CHATID)"
    fi
    
    echo ""
    echo "📄 当前 telegram 配置:"
    grep -A 5 "telegram:" config/config.yaml | sed 's/^/   /'
else
    check_fail "config.yaml 文件不存在！"
fi

echo ""

# 2. 检查环境变量（如果使用了）
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌍 2. 检查环境变量"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f ".env" ]; then
    check_info ".env 文件存在"
    
    if grep -q "TELEGRAM_BOT_TOKEN" .env; then
        ENV_TOKEN=$(grep "TELEGRAM_BOT_TOKEN" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        if [ -n "$ENV_TOKEN" ]; then
            ENV_TOKEN_PREFIX="${ENV_TOKEN:0:10}"
            check_info ".env 中的 Bot Token: $ENV_TOKEN_PREFIX..."
        fi
    fi
    
    if grep -q "TELEGRAM_CHAT_ID" .env; then
        ENV_CHATID=$(grep "TELEGRAM_CHAT_ID" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        if [ -n "$ENV_CHATID" ]; then
            check_info ".env 中的 Chat ID: $ENV_CHATID"
        fi
    fi
else
    check_warn ".env 文件不存在（如果使用 config.yaml 则正常）"
fi

echo ""

# 3. 检查 Docker 环境变量（如果是 Docker 部署）
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐳 3. 检查 Docker 配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v docker &> /dev/null; then
    if docker ps --format "{{.Names}}" | grep -q "crc_lrc"; then
        check_pass "Docker 容器正在运行"
        
        # 检查容器环境变量
        CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep "crc_lrc" | head -n 1)
        echo "   容器名称: $CONTAINER_NAME"
        
        # 检查容器内的配置
        echo ""
        check_info "检查容器内的 config.yaml:"
        docker exec "$CONTAINER_NAME" cat /app/config/config.yaml | grep -A 5 "telegram:" | sed 's/^/   /'
    else
        check_warn "Docker 容器未运行"
    fi
else
    check_info "Docker 未安装或不可用（本地开发模式）"
fi

echo ""

# 4. 测试 Telegram API 连接
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 4. 测试 Telegram API 连接"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 从 config.yaml 读取
CONFIG_TOKEN=$(grep -A 5 "telegram:" config/config.yaml | grep "botToken:" | awk '{print $2}' | tr -d '"')
CONFIG_CHATID=$(grep -A 5 "telegram:" config/config.yaml | grep "chatId:" | awk '{print $2}' | tr -d '"')

# 优先使用 .env
if [ -f ".env" ]; then
    ENV_TOKEN=$(grep "TELEGRAM_BOT_TOKEN" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    ENV_CHATID=$(grep "TELEGRAM_CHAT_ID" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    
    [ -n "$ENV_TOKEN" ] && CONFIG_TOKEN="$ENV_TOKEN"
    [ -n "$ENV_CHATID" ] && CONFIG_CHATID="$ENV_CHATID"
fi

if [ "$CONFIG_TOKEN" == "YOUR_BOT_TOKEN_HERE" ] || [ -z "$CONFIG_TOKEN" ]; then
    check_fail "无法测试：Token 未配置"
elif [ "$CONFIG_CHATID" == "YOUR_CHAT_ID_HERE" ] || [ -z "$CONFIG_CHATID" ]; then
    check_fail "无法测试：Chat ID 未配置"
else
    check_info "正在测试 Telegram API 连接..."
    
    # 测试 getMe
    echo -n "   测试 Bot Token: "
    GETME_RESPONSE=$(curl -s "https://api.telegram.org/bot${CONFIG_TOKEN}/getMe")
    
    if echo "$GETME_RESPONSE" | grep -q '"ok":true'; then
        BOT_NAME=$(echo "$GETME_RESPONSE" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
        check_pass "Token 有效！Bot: @$BOT_NAME"
    else
        check_fail "Token 无效！"
        echo "   响应: $GETME_RESPONSE"
    fi
    
    # 测试发送消息
    echo -n "   测试发送消息: "
    SEND_RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${CONFIG_TOKEN}/sendMessage" \
        -H "Content-Type: application/json" \
        -d "{\"chat_id\":\"${CONFIG_CHATID}\",\"text\":\"🧪 测试消息 - $(date '+%Y-%m-%d %H:%M:%S')\",\"parse_mode\":\"HTML\"}")
    
    if echo "$SEND_RESPONSE" | grep -q '"ok":true'; then
        check_pass "消息发送成功！请检查 Telegram"
    else
        check_fail "消息发送失败！"
        echo "   响应: $SEND_RESPONSE"
        
        # 常见错误提示
        if echo "$SEND_RESPONSE" | grep -q "chat not found"; then
            echo "   ⚠️  错误原因: Chat ID 不正确"
            echo "   💡 解决方法: 确保你已经向 Bot 发送过消息（比如 /start）"
        elif echo "$SEND_RESPONSE" | grep -q "Unauthorized"; then
            echo "   ⚠️  错误原因: Bot Token 无效"
        elif echo "$SEND_RESPONSE" | grep -q "Forbidden"; then
            echo "   ⚠️  错误原因: Bot 被用户阻止或未开始对话"
            echo "   💡 解决方法: 在 Telegram 中搜索你的 Bot，点击 Start"
        fi
    fi
fi

echo ""

# 5. 检查应用日志
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 5. 检查应用日志"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if docker ps --format "{{.Names}}" | grep -q "crc_lrc"; then
    CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep "crc_lrc" | head -n 1)
    check_info "最近的日志（查找 Telegram 相关）:"
    docker logs "$CONTAINER_NAME" --tail 20 2>&1 | grep -i "telegram\|notification" | sed 's/^/   /' || check_warn "没有找到 Telegram 相关日志"
else
    check_info "非 Docker 模式，请手动查看应用日志"
fi

echo ""

# 6. 诊断总结和建议
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 6. 诊断总结"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "📌 快速修复步骤:"
echo ""
echo "1️⃣  如果 enabled: false，修改 config/config.yaml:"
echo "   telegram:"
echo "     enabled: true"
echo ""
echo "2️⃣  如果 Token/Chat ID 未配置，运行配置脚本:"
echo "   ./scripts/install-or-update.sh"
echo ""
echo "3️⃣  手动测试发送消息:"
echo "   BOT_TOKEN='你的Token'"
echo "   CHAT_ID='你的ChatID'"
echo "   curl -X POST \"https://api.telegram.org/bot\${BOT_TOKEN}/sendMessage\" \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"chat_id\":\"\${CHAT_ID}\",\"text\":\"测试消息\"}'"
echo ""
echo "4️⃣  测试 API 并检查通知:"
echo "   curl -X POST http://localhost:8080/api/checksum \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"data\":\"Hello\",\"method\":\"text\"}'"
echo ""
echo "5️⃣  查看实时日志:"
echo "   docker logs -f \$(docker ps | grep crc_lrc | awk '{print \$1}')"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 诊断完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
