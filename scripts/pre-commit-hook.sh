#!/bin/bash
# Git pre-commit hook - 自动检查敏感信息
# 安装: cp pre-commit-hook.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

echo "🔒 Pre-commit: 检查敏感信息..."

# 敏感模式列表
SENSITIVE_PATTERNS=(
    "[0-9]{9,}:[A-Za-z0-9_-]{30,}"  # Telegram Bot Token
    "chatId.*[0-9]{10,}"             # Chat ID
)

FOUND=0

# 检查暂存的更改
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if git diff --cached | grep -E "$pattern" > /dev/null; then
        echo "❌ 错误: 发现疑似敏感信息!"
        echo "   模式: $pattern"
        git diff --cached | grep -E --color "$pattern"
        FOUND=1
    fi
done

# 检查特定文件
if git diff --cached --name-only | grep -q "config/config.yaml"; then
    if git diff --cached config/config.yaml | grep -E "botToken.*[0-9]+:" | grep -v "YOUR_" > /dev/null; then
        echo "❌ 错误: config.yaml 包含真实的 Bot Token!"
        FOUND=1
    fi
fi

if [ $FOUND -eq 1 ]; then
    echo ""
    echo "⚠️  提交被阻止! 请移除敏感信息后重试。"
    echo ""
    echo "建议:"
    echo "1. 使用占位符: YOUR_BOT_TOKEN_HERE"
    echo "2. 将真实值放在 .env 文件中"
    echo "3. 运行: ./check-sensitive-info.sh"
    echo ""
    echo "如需强制提交（不推荐）: git commit --no-verify"
    exit 1
fi

echo "✓ 未发现敏感信息，继续提交..."
exit 0
