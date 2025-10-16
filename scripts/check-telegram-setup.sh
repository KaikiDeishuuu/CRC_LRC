#!/bin/bash
# Telegram 通知功能 - 部署前检查清单

echo "🔍 Telegram 通知功能部署检查"
echo "================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNINGS=0

# 检查函数
check_file() {
    local file=$1
    local desc=$2
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $desc: $file"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $desc: $file ${RED}(缺失)${NC}"
        ((FAILED++))
        return 1
    fi
}

check_content() {
    local file=$1
    local pattern=$2
    local desc=$3
    
    if [ -f "$file" ] && grep -q "$pattern" "$file"; then
        echo -e "${GREEN}✓${NC} $desc"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $desc ${RED}(未找到)${NC}"
        ((FAILED++))
        return 1
    fi
}

check_warning() {
    local condition=$1
    local message=$2
    
    if [ "$condition" = "true" ]; then
        echo -e "${YELLOW}⚠${NC} $message"
        ((WARNINGS++))
    fi
}

echo -e "${BLUE}1. 文件完整性检查${NC}"
echo "----------------------------"

# 核心文件
check_file "internal/notification/telegram.go" "通知模块"
check_file "config/config.yaml" "配置文件"
check_file "test-telegram.sh" "测试脚本"

# 文档文件
check_file "TELEGRAM_INTEGRATION_GUIDE.md" "集成指南"
check_file "TELEGRAM_QUICKSTART.md" "快速入门"
check_file "TELEGRAM_CHANGELOG.md" "变更日志"
check_file ".env.example" "环境变量示例"

echo ""
echo -e "${BLUE}2. 配置检查${NC}"
echo "----------------------------"

# 检查配置项
check_content "config/config.yaml" "telegram:" "Telegram 配置块"
check_content "config/config.yaml" "enabled:" "enabled 配置"
check_content "config/config.yaml" "botToken:" "botToken 配置"
check_content "config/config.yaml" "chatId:" "chatId 配置"

# 检查配置结构体
check_content "config/config.go" "Telegram struct" "配置结构体"

echo ""
echo -e "${BLUE}3. 代码集成检查${NC}"
echo "----------------------------"

# 检查 handler 集成
check_content "internal/handler/checksum_handler.go" "notification" "导入 notification 包"
check_content "internal/handler/checksum_handler.go" "SendTelegramNotification" "调用通知函数"
check_content "internal/handler/checksum_handler.go" "getClientIP" "IP 获取函数"

echo ""
echo -e "${BLUE}4. 配置值检查${NC}"
echo "----------------------------"

# 读取配置
if [ -f "config/config.yaml" ]; then
    ENABLED=$(grep "enabled:" config/config.yaml | awk '{print $2}')
    BOT_TOKEN=$(grep "botToken:" config/config.yaml | awk '{print $2}' | tr -d '"')
    CHAT_ID=$(grep "chatId:" config/config.yaml | awk '{print $2}' | tr -d '"')
    
    # 检查是否启用
    if [ "$ENABLED" = "true" ]; then
        echo -e "${GREEN}✓${NC} Telegram 通知已启用"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠${NC} Telegram 通知未启用 (enabled: $ENABLED)"
        echo -e "  ${YELLOW}提示:${NC} 修改 config/config.yaml 中的 enabled 为 true"
        ((WARNINGS++))
    fi
    
    # 检查 Token
    if [ -n "$BOT_TOKEN" ] && [ "$BOT_TOKEN" != '""' ] && [ "$BOT_TOKEN" != "''" ]; then
        TOKEN_LEN=${#BOT_TOKEN}
        if [ $TOKEN_LEN -gt 40 ]; then
            echo -e "${GREEN}✓${NC} Bot Token 已配置 (长度: $TOKEN_LEN)"
            ((PASSED++))
        else
            echo -e "${YELLOW}⚠${NC} Bot Token 可能无效 (长度: $TOKEN_LEN)"
            ((WARNINGS++))
        fi
    else
        echo -e "${RED}✗${NC} Bot Token 未配置"
        echo -e "  ${YELLOW}提示:${NC} 获取 Token: 在 Telegram 搜索 @BotFather"
        ((FAILED++))
    fi
    
    # 检查 Chat ID
    if [ -n "$CHAT_ID" ] && [ "$CHAT_ID" != '""' ] && [ "$CHAT_ID" != "''" ]; then
        echo -e "${GREEN}✓${NC} Chat ID 已配置: $CHAT_ID"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Chat ID 未配置"
        echo -e "  ${YELLOW}提示:${NC} 获取 Chat ID: 在 Telegram 搜索 @userinfobot"
        ((FAILED++))
    fi
fi

echo ""
echo -e "${BLUE}5. 编译检查${NC}"
echo "----------------------------"

# 尝试编译
if go build -o /tmp/checksum-api-test . 2>/dev/null; then
    echo -e "${GREEN}✓${NC} 代码编译成功"
    ((PASSED++))
    rm -f /tmp/checksum-api-test
else
    echo -e "${RED}✗${NC} 代码编译失败"
    echo -e "  ${YELLOW}提示:${NC} 运行 'go build .' 查看详细错误"
    ((FAILED++))
fi

echo ""
echo -e "${BLUE}6. 依赖检查${NC}"
echo "----------------------------"

# 检查必要的包
if go list -m all | grep -q "github.com/sirupsen/logrus"; then
    echo -e "${GREEN}✓${NC} logrus 包已安装"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} logrus 包未安装"
    echo -e "  ${YELLOW}提示:${NC} 运行 'go mod tidy'"
    ((FAILED++))
fi

echo ""
echo "================================"
echo -e "${BLUE}检查总结${NC}"
echo "================================"
echo -e "${GREEN}通过: $PASSED${NC}"
echo -e "${RED}失败: $FAILED${NC}"
echo -e "${YELLOW}警告: $WARNINGS${NC}"
echo ""

if [ $FAILED -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ 所有检查通过！可以部署。${NC}"
    echo ""
    echo -e "${BLUE}下一步:${NC}"
    echo "1. 确保配置正确: vim config/config.yaml"
    echo "2. 重启服务: sudo systemctl restart checksum-api.service"
    echo "3. 运行测试: ./test-telegram.sh"
    exit 0
elif [ $FAILED -eq 0 ]; then
    echo -e "${YELLOW}⚠ 有 $WARNINGS 个警告，建议检查后再部署。${NC}"
    echo ""
    echo -e "${BLUE}建议操作:${NC}"
    echo "1. 检查上述警告项"
    echo "2. 修改配置: vim config/config.yaml"
    echo "3. 重新运行此脚本验证"
    exit 1
else
    echo -e "${RED}✗ 有 $FAILED 项检查失败，必须修复后才能部署！${NC}"
    echo ""
    echo -e "${BLUE}必须操作:${NC}"
    echo "1. 修复上述失败项"
    echo "2. 运行 'go mod tidy' 安装依赖"
    echo "3. 运行 'go build .' 检查编译"
    echo "4. 重新运行此脚本验证"
    exit 2
fi
