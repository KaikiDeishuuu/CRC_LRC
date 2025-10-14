#!/bin/bash

# API 监控脚本
# 监控异常请求和潜在攻击

echo "=========================================="
echo "API 安全监控"
echo "=========================================="

echo -e "\n[1] 最近的访问统计 (最近 1000 条):"
echo "---"

if [ -f /var/log/nginx/api_access.log ]; then
    # 请求次数最多的 IP
    echo "请求次数最多的 10 个 IP:"
    awk '{print $1}' /var/log/nginx/api_access.log | tail -1000 | sort | uniq -c | sort -rn | head -10
    
    echo -e "\n状态码分布:"
    awk '{print $9}' /var/log/nginx/api_access.log | tail -1000 | sort | uniq -c | sort -rn
    
    echo -e "\n最常访问的路径:"
    awk '{print $7}' /var/log/nginx/api_access.log | tail -1000 | sort | uniq -c | sort -rn | head -10
    
    echo -e "\n4xx 错误 (客户端错误):"
    grep -E ' (4[0-9]{2}) ' /var/log/nginx/api_access.log | tail -20
    
    echo -e "\n5xx 错误 (服务器错误):"
    grep -E ' (5[0-9]{2}) ' /var/log/nginx/api_access.log | tail -20
else
    echo "⚠️  未找到 API 访问日志"
fi

echo -e "\n[2] 错误日志 (最近 20 条):"
echo "---"
if [ -f /var/log/nginx/api_error.log ]; then
    tail -20 /var/log/nginx/api_error.log
else
    echo "⚠️  未找到 API 错误日志"
fi

echo -e "\n[3] Fail2ban 状态:"
echo "---"
if command -v fail2ban-client &> /dev/null; then
    fail2ban-client status nginx-limit-req 2>/dev/null || echo "未配置 nginx-limit-req"
    fail2ban-client status nginx-badbots 2>/dev/null || echo "未配置 nginx-badbots"
else
    echo "⚠️  Fail2ban 未安装"
fi

echo -e "\n[4] 当前被封禁的 IP:"
echo "---"
if [ -f /etc/nginx/conf.d/blacklist.conf ]; then
    grep -E '^deny' /etc/nginx/conf.d/blacklist.conf | wc -l | xargs echo "黑名单 IP 数量:"
    grep -E '^deny' /etc/nginx/conf.d/blacklist.conf
else
    echo "未配置黑名单"
fi

echo -e "\n[5] Docker 容器状态:"
echo "---"
docker ps --filter "name=checksum-api" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n[6] 容器资源使用:"
echo "---"
docker stats --no-stream checksum-api 2>/dev/null || echo "容器未运行"

echo -e "\n=========================================="
echo "监控完成"
echo "=========================================="
echo ""
echo "建议操作:"
echo "  • 如发现异常 IP，使用: sudo ./block-ip.sh <IP>"
echo "  • 查看实时日志: sudo tail -f /var/log/nginx/api_access.log"
echo "  • 检查 Fail2ban: sudo fail2ban-client status"
echo "=========================================="
