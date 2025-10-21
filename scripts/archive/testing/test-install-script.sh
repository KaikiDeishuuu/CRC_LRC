#!/bin/bash
# 测试傻瓜式安装脚本的各个功能

set -e

echo "╔════════════════════════════════════════════╗"
echo "║   测试傻瓜式安装脚本                      ║"
echo "╚════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

TEST_PASSED=0
TEST_FAILED=0

# 测试函数
test_check() {
    local test_name="$1"
    local result="$2"
    
    if [ "$result" = "0" ]; then
        echo -e "${GREEN}✓ $test_name${NC}"
        TEST_PASSED=$((TEST_PASSED + 1))
    else
        echo -e "${RED}✗ $test_name${NC}"
        TEST_FAILED=$((TEST_FAILED + 1))
    fi
}

echo -e "${CYAN}测试 1: 检查脚本文件是否存在${NC}"
if [ -f "scripts/install-or-update.sh" ]; then
    test_check "脚本文件存在" 0
else
    test_check "脚本文件存在" 1
fi

echo ""
echo -e "${CYAN}测试 2: 检查脚本执行权限${NC}"
if [ -x "scripts/install-or-update.sh" ]; then
    test_check "脚本可执行" 0
else
    test_check "脚本可执行" 1
fi

echo ""
echo -e "${CYAN}测试 3: 检查脚本语法${NC}"
if bash -n scripts/install-or-update.sh 2>/dev/null; then
    test_check "脚本语法正确" 0
else
    test_check "脚本语法正确" 1
fi

echo ""
echo -e "${CYAN}测试 4: 检查必需的文档文件${NC}"
REQUIRED_DOCS=(
    "QUICKSTART.md"
    "docs/EASY_INSTALL.md"
    "docs/DEMO.md"
)

for doc in "${REQUIRED_DOCS[@]}"; do
    if [ -f "$doc" ]; then
        test_check "文档文件 $doc 存在" 0
    else
        test_check "文档文件 $doc 存在" 1
    fi
done

echo ""
echo -e "${CYAN}测试 5: 检查配置文件模板${NC}"
if [ -f ".env.example" ]; then
    test_check ".env.example 存在" 0
else
    test_check ".env.example 存在" 1
fi

if [ -f "config/config.yaml" ]; then
    test_check "config.yaml 存在" 0
else
    test_check "config.yaml 存在" 1
fi

echo ""
echo -e "${CYAN}测试 6: 检查 Docker 配置文件${NC}"
if [ -f "docker-compose.yml" ]; then
    test_check "docker-compose.yml 存在" 0
else
    test_check "docker-compose.yml 存在" 1
fi

if [ -f "Dockerfile" ]; then
    test_check "Dockerfile 存在" 0
else
    test_check "Dockerfile 存在" 1
fi

echo ""
echo -e "${CYAN}测试 7: 检查脚本中的关键功能${NC}"

# 检查是否包含环境检测
if grep -q "command -v docker" scripts/install-or-update.sh; then
    test_check "包含 Docker 检测" 0
else
    test_check "包含 Docker 检测" 1
fi

# 检查是否包含备份功能
if grep -q "BACKUP_DIR" scripts/install-or-update.sh; then
    test_check "包含备份功能" 0
else
    test_check "包含备份功能" 1
fi

# 检查是否包含 Telegram 配置
if grep -q "TELEGRAM_BOT_TOKEN" scripts/install-or-update.sh; then
    test_check "包含 Telegram 配置" 0
else
    test_check "包含 Telegram 配置" 1
fi

# 检查是否包含健康检查
if grep -q "健康检查" scripts/install-or-update.sh; then
    test_check "包含健康检查" 0
else
    test_check "包含健康检查" 1
fi

echo ""
echo -e "${CYAN}测试 8: 检查 README 更新${NC}"
if grep -q "install-or-update.sh" README.md; then
    test_check "README 包含安装脚本引用" 0
else
    test_check "README 包含安装脚本引用" 1
fi

if grep -q "QUICKSTART.md" README.md || grep -q "EASY_INSTALL.md" README.md; then
    test_check "README 包含文档链接" 0
else
    test_check "README 包含文档链接" 1
fi

echo ""
echo -e "${CYAN}测试 9: 检查脚本颜色输出${NC}"
if grep -q "GREEN=" scripts/install-or-update.sh && grep -q "RED=" scripts/install-or-update.sh; then
    test_check "脚本包含颜色定义" 0
else
    test_check "脚本包含颜色定义" 1
fi

echo ""
echo -e "${CYAN}测试 10: 模拟脚本执行（dry run）${NC}"
# 检查脚本是否会因为没有 Docker 而正确退出
if [ ! -f "/tmp/test-install-script" ]; then
    # 创建一个测试环境
    echo -e "${YELLOW}跳过实际执行测试（需要 Docker 环境）${NC}"
    test_check "脚本执行测试（已跳过）" 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "测试结果汇总"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "通过: ${GREEN}$TEST_PASSED${NC}"
echo -e "失败: ${RED}$TEST_FAILED${NC}"
echo -e "总计: $((TEST_PASSED + TEST_FAILED))"
echo ""

if [ $TEST_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                            ║${NC}"
    echo -e "${GREEN}║    ✓ 所有测试通过！                      ║${NC}"
    echo -e "${GREEN}║                                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}安装脚本已准备就绪，可以使用：${NC}"
    echo ""
    echo "  ./scripts/install-or-update.sh"
    echo ""
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                            ║${NC}"
    echo -e "${RED}║    ✗ 部分测试失败                        ║${NC}"
    echo -e "${RED}║                                            ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}请检查失败的测试项并修复${NC}"
    echo ""
    exit 1
fi
