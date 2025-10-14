#!/bin/bash

# API 速率限制和防护配置脚本
# 防止 API 滥用和 DDoS 攻击

set -e

echo "=========================================="
echo "配置 API 防护措施"
echo "=========================================="

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo "请使用 root 权限运行此脚本"
    echo "使用: sudo ./setup-api-protection.sh"
    exit 1
fi

echo -e "\n选择防护级别:"
echo "1) 基础防护 (推荐)"
echo "2) 严格防护 (适合小流量场景)"
echo "3) 自定义配置"
read -p "选择 (1-3): " PROTECTION_LEVEL

# 设置默认值
RATE_LIMIT="10r/s"
BURST="20"
CONN_LIMIT="10"

case $PROTECTION_LEVEL in
    1)
        RATE_LIMIT="10r/s"
        BURST="20"
        CONN_LIMIT="10"
        echo "✓ 选择了基础防护"
        ;;
    2)
        RATE_LIMIT="5r/s"
        BURST="10"
        CONN_LIMIT="5"
        echo "✓ 选择了严格防护"
        ;;
    3)
        read -p "每秒请求数限制 (默认 10): " CUSTOM_RATE
        read -p "突发请求数 (默认 20): " CUSTOM_BURST
        read -p "单IP并发连接数 (默认 10): " CUSTOM_CONN
        
        RATE_LIMIT="${CUSTOM_RATE:-10}r/s"
        BURST="${CUSTOM_BURST:-20}"
        CONN_LIMIT="${CUSTOM_CONN:-10}"
        echo "✓ 自定义配置完成"
        ;;
    *)
        echo "无效选择，使用基础防护"
        ;;
esac

echo -e "\n[1] 创建 Nginx 限流配置..."

# 创建限流配置文件
cat > /etc/nginx/conf.d/rate-limit.conf << EOF
# API 速率限制配置
# 防止 API 滥用和 DDoS 攻击

# 定义限流区域
limit_req_zone \$binary_remote_addr zone=api_limit:10m rate=${RATE_LIMIT};
limit_req_zone \$binary_remote_addr zone=api_strict:10m rate=5r/s;
limit_conn_zone \$binary_remote_addr zone=conn_limit:10m;

# 限制请求体大小（防止大文件上传攻击）
client_max_body_size 10M;

# 超时设置
client_body_timeout 10s;
client_header_timeout 10s;
send_timeout 10s;

# 缓冲区限制
client_body_buffer_size 128k;
client_header_buffer_size 1k;
large_client_header_buffers 4 4k;
EOF

echo "✓ 限流配置已创建"

echo -e "\n[2] 询问是否需要 IP 黑名单功能..."
read -p "是否启用 IP 黑名单? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 创建黑名单文件
    touch /etc/nginx/conf.d/blacklist.conf
    cat > /etc/nginx/conf.d/blacklist.conf << 'EOF'
# IP 黑名单
# 格式: deny <IP地址>;

# 示例：
# deny 192.168.1.100;
# deny 10.0.0.0/8;

# 在这里添加需要封禁的 IP
EOF
    echo "✓ IP 黑名单文件已创建: /etc/nginx/conf.d/blacklist.conf"
fi

echo -e "\n[3] 询问是否需要地理位置限制..."
read -p "是否启用地理位置限制? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "提示: 需要安装 GeoIP2 模块"
    echo "参考: https://github.com/leev/ngx_http_geoip2_module"
    
    cat > /etc/nginx/conf.d/geo-block.conf << 'EOF'
# 地理位置限制（需要 GeoIP2 模块）
# 
# map $geoip2_data_country_code $allowed_country {
#     default no;
#     CN yes;  # 允许中国
#     US yes;  # 允许美国
# }
#
# 在 server 块中使用:
# if ($allowed_country = no) {
#     return 403;
# }
EOF
    echo "✓ 地理位置限制模板已创建（需手动配置）"
fi

echo -e "\n[4] 创建防护配置片段..."

cat > /etc/nginx/snippets/api-protection.conf << EOF
# API 防护配置片段
# 在 location /api/ 块中引入此文件

# 应用速率限制
limit_req zone=api_limit burst=${BURST} nodelay;
limit_conn conn_limit ${CONN_LIMIT};

# 隐藏服务器信息
more_clear_headers 'Server';
more_clear_headers 'X-Powered-By';

# 安全头
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "DENY" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;

# 只允许特定方法
limit_except GET POST OPTIONS {
    deny all;
}

# 超时设置
proxy_connect_timeout 5s;
proxy_send_timeout 10s;
proxy_read_timeout 30s;

# 缓冲设置
proxy_buffering off;
proxy_request_buffering off;

# 日志格式（包含更多信息）
access_log /var/log/nginx/api_access.log combined;
error_log /var/log/nginx/api_error.log warn;
EOF

echo "✓ 防护配置片段已创建"

echo -e "\n[5] 安装 Fail2ban（防暴力攻击）..."
if ! command -v fail2ban-client &> /dev/null; then
    read -p "Fail2ban 未安装，是否安装? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apt update
        apt install -y fail2ban
        echo "✓ Fail2ban 已安装"
    else
        echo "跳过 Fail2ban 安装"
    fi
else
    echo "✓ Fail2ban 已安装"
fi

if command -v fail2ban-client &> /dev/null; then
    echo -e "\n[6] 配置 Fail2ban 保护 Nginx..."
    
    cat > /etc/fail2ban/jail.d/nginx-api.conf << EOF
# Nginx API 保护规则

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
action = iptables-multiport[name=ReqLimit, port="http,https", protocol=tcp]
logpath = /var/log/nginx/api_error.log
findtime = 600
bantime = 3600
maxretry = 10

[nginx-badbots]
enabled = true
filter = nginx-badbots
action = iptables-multiport[name=BadBots, port="http,https", protocol=tcp]
logpath = /var/log/nginx/api_access.log
findtime = 86400
bantime = 86400
maxretry = 5
EOF

    echo "✓ Fail2ban 规则已配置"
    
    # 重启 Fail2ban
    systemctl restart fail2ban
    echo "✓ Fail2ban 已重启"
fi

echo -e "\n[7] 测试 Nginx 配置..."
if nginx -t; then
    echo "✓ Nginx 配置测试通过"
    
    read -p "是否重载 Nginx? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl reload nginx
        echo "✓ Nginx 已重载"
    fi
else
    echo "❌ Nginx 配置测试失败"
    echo "请检查配置文件"
    exit 1
fi

echo -e "\n=========================================="
echo "API 防护配置完成！"
echo "=========================================="
echo ""
echo "配置摘要:"
echo "  • 速率限制: $RATE_LIMIT"
echo "  • 突发请求: $BURST"
echo "  • 连接限制: $CONN_LIMIT"
echo "  • 请求体限制: 10MB"
echo ""
echo "配置文件位置:"
echo "  • /etc/nginx/conf.d/rate-limit.conf"
echo "  • /etc/nginx/snippets/api-protection.conf"
[ -f /etc/nginx/conf.d/blacklist.conf ] && echo "  • /etc/nginx/conf.d/blacklist.conf"
[ -f /etc/fail2ban/jail.d/nginx-api.conf ] && echo "  • /etc/fail2ban/jail.d/nginx-api.conf"
echo ""
echo "下一步:"
echo "  1. 在 Nginx 站点配置中引入防护配置:"
echo "     location /api/ {"
echo "         include snippets/api-protection.conf;"
echo "         proxy_pass http://localhost:8080/api/;"
echo "     }"
echo ""
echo "  2. 监控日志:"
echo "     sudo tail -f /var/log/nginx/api_access.log"
echo "     sudo fail2ban-client status nginx-limit-req"
echo ""
echo "  3. 封禁恶意 IP:"
echo "     echo 'deny <IP地址>;' | sudo tee -a /etc/nginx/conf.d/blacklist.conf"
echo "     sudo systemctl reload nginx"
echo ""
echo "=========================================="
