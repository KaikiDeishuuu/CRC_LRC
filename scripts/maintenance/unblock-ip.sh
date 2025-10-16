#!/bin/bash

# 解封 IP 地址

if [ "$EUID" -ne 0 ]; then 
    echo "请使用 root 权限运行"
    echo "使用: sudo ./unblock-ip.sh <IP地址>"
    exit 1
fi

if [ -z "$1" ]; then
    echo "用法: sudo ./unblock-ip.sh <IP地址>"
    exit 1
fi

IP=$1

echo "=========================================="
echo "解封 IP: $IP"
echo "=========================================="

echo -e "\n[1] 从 Nginx 黑名单移除..."
if [ -f /etc/nginx/conf.d/blacklist.conf ]; then
    sed -i "/deny $IP;/d" /etc/nginx/conf.d/blacklist.conf
    echo "✓ 已从 Nginx 黑名单移除"
fi

echo -e "\n[2] 从 iptables 移除..."
if iptables -C INPUT -s $IP -j DROP 2>/dev/null; then
    iptables -D INPUT -s $IP -j DROP
    echo "✓ 已从 iptables 移除"
    
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save
        echo "✓ iptables 规则已保存"
    fi
else
    echo "⚠️  IP 不在 iptables 规则中"
fi

echo -e "\n[3] 重载 Nginx..."
systemctl reload nginx
echo "✓ Nginx 已重载"

echo -e "\n[4] 从 Fail2ban 解封..."
if command -v fail2ban-client &> /dev/null; then
    fail2ban-client set nginx-limit-req unbanip $IP 2>/dev/null && echo "✓ 已从 Fail2ban 解封" || echo "⚠️  Fail2ban 操作失败"
fi

echo -e "\n=========================================="
echo "IP $IP 已解封！"
echo "=========================================="
