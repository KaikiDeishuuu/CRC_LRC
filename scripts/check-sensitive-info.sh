#!/bin/bash
# 检查是否包含敏感信息

echo "🔍 检查敏感信息..."
echo "================================"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FOUND=0

# 检查暂存区和工作区的修改
echo "正在检查 Git 修改..."

# 敏感关键词列表
SENSITIVE_PATTERNS=(
    "bot[0-9]+:[A-Za-z0-9_-]+"  # Telegram Bot Token 格式
    "[0-9]{10,}"                 # Chat ID (10位以上数字)
    "password.*=.*[^YOUR_]"      # 密码
    "secret.*=.*[^YOUR_]"        # 密钥
    "apikey.*=.*[^YOUR_]"        # API Key
)

# 检查已暂存的文件
if git diff --staged --name-only 2>/dev/null | grep -q .; then
    echo ""
    echo "检查已暂存的文件..."
    
    for pattern in "${SENSITIVE_PATTERNS[@]}"; do
        if git diff --staged | grep -E -i "$pattern" > /dev/null; then
            echo -e "${RED}⚠️  警告: 发现疑似敏感信息 (模式: $pattern)${NC}"
            git diff --staged | grep -E -i --color "$pattern"
            FOUND=1
        fi
    done
fi

# 检查工作区的文件
echo ""
echo "检查未暂存的修改..."

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if git diff | grep -E -i "$pattern" > /dev/null; then
        echo -e "${YELLOW}⚠️  注意: 工作区发现疑似敏感信息 (模式: $pattern)${NC}"
        git diff | grep -E -i --color "$pattern"
        FOUND=1
    fi
done

# 检查特定文件
echo ""
echo "检查配置文件..."

if [ -f "config/config.yaml" ]; then
    # 检查是否包含真实 Token（不是占位符）
    if grep -E "botToken:.*[0-9]+:[A-Za-z0-9_-]+" config/config.yaml | grep -v "YOUR_" > /dev/null; then
        echo -e "${RED}⚠️  警告: config.yaml 包含真实的 Bot Token！${NC}"
        FOUND=1
    fi
    
    # 检查是否包含真实 Chat ID（10位以上数字，且不是示例）
    if grep -E "chatId:.*[0-9]{10,}" config/config.yaml | grep -v "YOUR_\|123456789\|987654321" > /dev/null; then
        echo -e "${RED}⚠️  警告: config.yaml 包含真实的 Chat ID！${NC}"
        FOUND=1
    fi
fi

# 检查 .env 是否被跟踪
if git ls-files | grep -q "^\.env$"; then
    echo -e "${RED}⚠️  错误: .env 文件被 Git 跟踪！${NC}"
    echo "   运行: git rm --cached .env"
    FOUND=1
fi

echo ""
echo "================================"

if [ $FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ 未发现敏感信息，可以安全提交！${NC}"
    exit 0
else
    echo -e "${RED}✗ 发现疑似敏感信息！${NC}"
    echo ""
    echo "建议操作："
    echo "1. 检查上述标记的内容"
    echo "2. 使用占位符替换真实值（如 YOUR_BOT_TOKEN_HERE）"
    echo "3. 将真实值移到 .env 文件或环境变量"
    echo "4. 重新运行此脚本确认"
    echo ""
    echo "如果已经提交："
    echo "- 立即撤销 Token（@BotFather）"
    echo "- 参考 SECURITY_NOTICE.md 清理 Git 历史"
    exit 1
fi
