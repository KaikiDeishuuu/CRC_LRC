#!/bin/bash
# Telegram 通知测试脚本

echo "🧪 测试 Telegram 通知功能..."
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 测试用例
TEST_CASES=(
    '{"input":"Hello","description":"普通文本测试"}'
    '{"input":"0x4142434445","description":"十六进制测试"}'
    '{"input":"测试中文","description":"中文测试"}'
)

echo -e "${YELLOW}提示: 请确保服务已启动在 http://localhost:8080${NC}"
echo ""

# 执行测试
for i in "${!TEST_CASES[@]}"; do
    # 解析测试用例
    TEST_JSON="${TEST_CASES[$i]}"
    INPUT=$(echo "$TEST_JSON" | grep -o '"input":"[^"]*"' | cut -d'"' -f4)
    DESC=$(echo "$TEST_JSON" | grep -o '"description":"[^"]*"' | cut -d'"' -f4)
    
    echo -e "${YELLOW}测试 $((i+1)): $DESC${NC}"
    echo "输入: $INPUT"
    
    # 发送请求
    RESPONSE=$(curl -s -w "\n%{http_code}" "http://localhost:8080/api/checksum?input=$INPUT")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n-1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✅ 请求成功 (HTTP $HTTP_CODE)${NC}"
        echo "响应: $BODY" | jq '.' 2>/dev/null || echo "$BODY"
        echo -e "${GREEN}📱 请检查 Telegram 是否收到通知${NC}"
    else
        echo -e "${RED}❌ 请求失败 (HTTP $HTTP_CODE)${NC}"
        echo "响应: $BODY"
    fi
    
    echo ""
    echo "--------------------------------"
    echo ""
    
    # 等待 2 秒，避免频繁请求
    sleep 2
done

echo -e "${GREEN}✅ 测试完成！${NC}"
echo ""
echo -e "${YELLOW}提示:${NC}"
echo "1. 如果没有收到 Telegram 通知，请检查 config/config.yaml 中的配置"
echo "2. 确保 telegram.enabled 设置为 true"
echo "3. 确认 botToken 和 chatId 正确"
echo "4. 查看服务日志: journalctl -u checksum-api.service -f"
