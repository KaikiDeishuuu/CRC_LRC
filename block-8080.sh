#!/bin/bash

# 关闭 8080 端口对外访问的脚本
# 只允许本地访问，阻止外部访问

set -e

echo "=========================================="
echo "配置防火墙 - 关闭 8080 端口对外访问"
echo "=========================================="

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo "请使用 root 权限运行此脚本"
    echo "使用: sudo ./block-8080.sh"
    exit 1
fi

echo -e "\n[1] 当前 8080 端口相关规则:"
iptables -L INPUT -n -v | grep 8080 || echo "没有现有规则"

echo -e "\n[2] 检查是否已有规则..."

# 检查是否已经配置过
if iptables -L INPUT -n | grep -q "dpt:8080"; then
    echo "⚠️  发现已有 8080 端口规则"
    read -p "是否清理旧规则并重新配置? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "清理旧规则..."
        # 删除所有 8080 规则
        while iptables -L INPUT -n | grep -q "dpt:8080"; do
            iptables -D INPUT -p tcp --dport 8080 -j DROP 2>/dev/null || true
            iptables -D INPUT -i lo -p tcp --dport 8080 -j ACCEPT 2>/dev/null || true
        done
        echo "✓ 旧规则已清理"
    else
        echo "取消配置"
        exit 0
    fi
fi

echo -e "\n[3] 添加防火墙规则..."

# 允许本地回环访问 8080（插入到第1行）
iptables -I INPUT 1 -i lo -p tcp --dport 8080 -j ACCEPT

# 拒绝所有其他来源访问 8080（插入到第2行）
iptables -I INPUT 2 -p tcp --dport 8080 -j DROP

echo "✓ 规则已添加"

echo -e "\n[4] 新的 8080 端口规则:"
iptables -L INPUT -n -v --line-numbers | grep 8080

echo -e "\n[5] 保存规则（重启后依然生效）..."

# 检测系统类型并保存规则
if command -v netfilter-persistent &> /dev/null; then
    # Debian/Ubuntu with netfilter-persistent
    netfilter-persistent save
    echo "✓ 使用 netfilter-persistent 保存"
elif command -v iptables-save &> /dev/null; then
    # 通用方法
    iptables-save > /etc/iptables/rules.v4
    echo "✓ 规则已保存到 /etc/iptables/rules.v4"
else
    echo "⚠️  警告: 无法自动保存规则，重启后可能失效"
    echo "请手动运行: iptables-save > /etc/iptables/rules.v4"
fi

echo -e "\n[6] 测试配置..."
echo "✓ 本地访问测试:"
curl -s http://localhost:8080/ > /dev/null && echo "  - localhost:8080 可访问" || echo "  - localhost:8080 无法访问"

echo -e "\n=========================================="
echo "配置完成！"
echo "=========================================="
echo ""
echo "8080 端口现在:"
echo "  ✓ 允许本地访问 (localhost/127.0.0.1)"
echo "  ✗ 拒绝外部访问 (公网 IP)"
echo ""
echo "Nginx 反向代理仍然可以正常访问 localhost:8080"
echo ""
echo "如需撤销，运行:"
echo "  sudo iptables -D INPUT -p tcp --dport 8080 -j DROP"
echo "  sudo iptables -D INPUT -i lo -p tcp --dport 8080 -j ACCEPT"
echo "=========================================="
