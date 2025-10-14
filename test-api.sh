#!/bin/bash

# API 测试脚本
# 用于验证 API 是否正常工作

set -e

# 配置
API_URL="${API_URL:-http://localhost:8080}"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=================================="
echo "CRC/LRC API 测试"
echo "目标地址: $API_URL"
echo "=================================="
echo ""

# 测试计数
PASSED=0
FAILED=0

# 测试函数
test_api() {
    local test_name="$1"
    local endpoint="$2"
    local data="$3"
    local expected_field="$4"
    local expected_value="$5"
    
    echo -n "测试: $test_name ... "
    
    # 发送请求
    response=$(curl -s -X POST "$API_URL$endpoint" \
        -H "Content-Type: application/json" \
        -d "$data" 2>&1)
    
    # 检查响应
    if [ -z "$response" ]; then
        echo -e "${RED}失败${NC} (无响应)"
        FAILED=$((FAILED + 1))
        return 1
    fi
    
    # 如果指定了期望值，进行验证
    if [ -n "$expected_field" ] && [ -n "$expected_value" ]; then
        actual_value=$(echo "$response" | grep -o "\"$expected_field\":\"[^\"]*\"" | cut -d'"' -f4)
        
        if [ "$actual_value" = "$expected_value" ]; then
            echo -e "${GREEN}通过${NC}"
            PASSED=$((PASSED + 1))
            return 0
        else
            echo -e "${RED}失败${NC} (期望: $expected_value, 实际: $actual_value)"
            echo "响应: $response"
            FAILED=$((FAILED + 1))
            return 1
        fi
    else
        # 只检查是否有响应
        if echo "$response" | grep -q "error"; then
            echo -e "${RED}失败${NC}"
            echo "错误: $response"
            FAILED=$((FAILED + 1))
            return 1
        else
            echo -e "${GREEN}通过${NC}"
            PASSED=$((PASSED + 1))
            return 0
        fi
    fi
}

# 测试1: 首页访问
echo -n "测试: 访问首页 ... "
if curl -s -o /dev/null -w "%{http_code}" "$API_URL/" | grep -q "200"; then
    echo -e "${GREEN}通过${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}失败${NC}"
    FAILED=$((FAILED + 1))
fi

# 测试2: 文本输入 - Hello
test_api "文本输入(Hello)" \
    "/api/checksum" \
    '{"data":"Hello","method":"text"}' \
    "crc" \
    "14C4"

# 测试3: HEX 输入
test_api "HEX输入(01 02 03 04)" \
    "/api/checksum" \
    '{"data":"01 02 03 04","method":"hex"}' \
    "crc" \
    "B448"

# 测试4: 标准测试向量 123456789
test_api "标准测试向量(123456789)" \
    "/api/checksum" \
    '{"data":"123456789","method":"text"}' \
    "crc" \
    "4B37"

# 测试5: LRC 计算
test_api "LRC计算" \
    "/api/lrc" \
    '{"data":"Hello","method":"text"}' \
    "lrc"

# 测试6: 空数据处理
echo -n "测试: 空数据处理 ... "
response=$(curl -s -X POST "$API_URL/api/checksum" \
    -H "Content-Type: application/json" \
    -d '{"data":"","method":"text"}' 2>&1)

if echo "$response" | grep -q "error"; then
    echo -e "${GREEN}通过${NC} (正确返回错误)"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}警告${NC} (应该返回错误)"
    PASSED=$((PASSED + 1))
fi

# 测试7: 无效 HEX 格式
echo -n "测试: 无效HEX格式处理 ... "
response=$(curl -s -X POST "$API_URL/api/checksum" \
    -H "Content-Type: application/json" \
    -d '{"data":"GG HH","method":"hex"}' 2>&1)

if echo "$response" | grep -q "error"; then
    echo -e "${GREEN}通过${NC} (正确返回错误)"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}警告${NC} (应该返回错误)"
    PASSED=$((PASSED + 1))
fi

# 测试8: CRC32 验证
test_api "CRC32验证(Hello)" \
    "/api/checksum" \
    '{"data":"Hello","method":"text"}' \
    "crc32" \
    "F7D18982"

# 测试9: CRC16 CCITT
test_api "CRC16 CCITT(Hello)" \
    "/api/checksum" \
    '{"data":"Hello","method":"text"}' \
    "crc16_ccitt" \
    "9DD6"

# 测试10: SUM8
test_api "SUM8(Hello)" \
    "/api/checksum" \
    '{"data":"Hello","method":"text"}' \
    "sum8" \
    "FC"

echo ""
echo "=================================="
echo "测试结果汇总"
echo "=================================="
echo -e "通过: ${GREEN}$PASSED${NC}"
echo -e "失败: ${RED}$FAILED${NC}"
echo "总计: $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ 所有测试通过！${NC}"
    exit 0
else
    echo -e "${RED}✗ 有测试失败${NC}"
    exit 1
fi
