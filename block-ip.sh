#!/bin/bash

# 快速封禁恶意 IP

if [ "$EUID" -ne 0 ]; then 
    echo "请使用 root 权限运行"
    echo "使用: sudo ./block-ip.sh <IP地址>"
    exit 1
fi

if [ -z "$1" ]; then
    echo "用法: sudo ./block-ip.sh <IP地址>"
    echo "示例: sudo ./block-ip.sh 192.168.1.100"
    exit 1
fi

IP=$1

echo "=========================================="
echo "封禁 IP: $IP"
echo "=========================================="

# 验证 IP 格式
if ! [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ 无效的 IP 地址格式"
    exit 1
fi

echo -e "\n[1] 添加到 Nginx 黑名单..."
if [ ! -f /etc/nginx/conf.d/blacklist.conf ]; then
    touch /etc/nginx/conf.d/blacklist.conf
fi

if grep -q "deny $IP;" /etc/nginx/conf.d/blacklist.conf; then
    echo "⚠️  IP 已在黑名单中"
else
    echo "deny $IP;  # 添加于 $(date)" >> /etc/nginx/conf.d/blacklist.conf
    echo "✓ 已添加到 Nginx 黑名单"
fi

echo -e "\n[2] 添加到 iptables..."
if iptables -C INPUT -s $IP -j DROP 2>/dev/null; then
    echo "⚠️  IP 已在 iptables 规则中"
else
    iptables -I INPUT -s $IP -j DROP
    echo "✓ 已添加到 iptables"
    
    # 保存规则
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save
        echo "✓ iptables 规则已保存"
    fi
fi

echo -e "\n[3] 重载 Nginx..."
if nginx -t 2>/dev/null; then
    systemctl reload nginx
    echo "✓ Nginx 已重载"
else
    echo "❌ Nginx 配置测试失败"
fi

echo -e "\n[4] 添加到 Fail2ban（如果已安装）..."
if command -v fail2ban-client &> /dev/null; then
    fail2ban-client set nginx-limit-req banip $IP 2>/dev/null && echo "✓ 已添加到 Fail2ban" || echo "⚠️  Fail2ban 添加失败（可能未配置）"
fi

echo -e "\n=========================================="
echo "IP $IP 已被封禁！"
echo "=========================================="
echo ""
echo "查看该 IP 的历史请求:"
echo "  sudo grep '$IP' /var/log/nginx/api_access.log"
echo ""
echo "解封 IP:"
echo "  sudo ./unblock-ip.sh $IP"
echo "=========================================="
