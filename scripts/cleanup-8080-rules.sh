#!/bin/bash

# 清理 8080 端口的重复防火墙规则

set -e

echo "=========================================="
echo "清理 8080 端口防火墙规则"
echo "=========================================="

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo "请使用 root 权限运行此脚本"
    echo "使用: sudo ./cleanup-8080-rules.sh"
    exit 1
fi

echo -e "\n[1] 当前 8080 端口规则:"
iptables -L INPUT -n -v --line-numbers | grep 8080

echo -e "\n[2] 删除所有 8080 相关规则..."

# 循环删除所有 8080 规则
while iptables -L INPUT -n | grep -q "dpt:8080"; do
    iptables -D INPUT -p tcp --dport 8080 -j DROP 2>/dev/null || true
    iptables -D INPUT -i lo -p tcp --dport 8080 -j ACCEPT 2>/dev/null || true
done

echo "✓ 所有规则已删除"

echo -e "\n[3] 添加正确的规则（只添加一次）..."

# 允许本地访问
iptables -I INPUT 1 -i lo -p tcp --dport 8080 -j ACCEPT

# 拒绝外部访问
iptables -I INPUT 2 -p tcp --dport 8080 -j DROP

echo "✓ 规则已添加"

echo -e "\n[4] 验证新规则:"
iptables -L INPUT -n -v --line-numbers | grep 8080

echo -e "\n[5] 保存规则..."
netfilter-persistent save
echo "✓ 规则已保存"

echo -e "\n=========================================="
echo "清理完成！"
echo "=========================================="
echo ""
echo "当前配置:"
echo "  ✓ 允许本地访问 8080 (localhost)"
echo "  ✗ 拒绝外部访问 8080 (公网)"
echo "=========================================="
