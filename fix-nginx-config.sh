#!/bin/bash

# 修复 Nginx 配置中的 headers-more 模块问题

echo "=========================================="
echo "修复 Nginx 配置"
echo "=========================================="

if [ "$EUID" -ne 0 ]; then 
    echo "请使用 root 权限运行"
    echo "使用: sudo ./fix-nginx-config.sh"
    exit 1
fi

echo -e "\n[1] 检查 headers-more 模块..."
if nginx -V 2>&1 | grep -q "headers-more"; then
    echo "✓ headers-more 模块已安装"
    HAS_MODULE=true
else
    echo "⚠️  headers-more 模块未安装"
    HAS_MODULE=false
fi

echo -e "\n[2] 修复 API 防护配置..."

if [ -f /etc/nginx/snippets/api-protection.conf ]; then
    # 备份原文件
    cp /etc/nginx/snippets/api-protection.conf /etc/nginx/snippets/api-protection.conf.backup
    
    if [ "$HAS_MODULE" = false ]; then
        # 注释掉 more_* 指令
        sed -i 's/^more_clear_headers/#more_clear_headers/g' /etc/nginx/snippets/api-protection.conf
        sed -i 's/^more_set_headers/#more_set_headers/g' /etc/nginx/snippets/api-protection.conf
        
        echo "✓ 已注释掉 more_* 指令"
        
        # 添加标准的 header 隐藏方法
        if ! grep -q "proxy_hide_header" /etc/nginx/snippets/api-protection.conf; then
            sed -i '/# 隐藏服务器信息/a\
# 使用标准方法隐藏头信息（需在 http 块中设置 server_tokens off）\
proxy_hide_header X-Powered-By;' /etc/nginx/snippets/api-protection.conf
        fi
    fi
    
    echo "✓ API 防护配置已修复"
else
    echo "⚠️  未找到 /etc/nginx/snippets/api-protection.conf"
fi

echo -e "\n[3] 检查并修复速率限制配置..."

if [ -f /etc/nginx/conf.d/rate-limit.conf ]; then
    echo "✓ 速率限制配置存在"
else
    echo "⚠️  未找到速率限制配置，跳过"
fi

echo -e "\n[4] 在主配置中设置 server_tokens..."

# 检查是否已设置
if grep -q "server_tokens off" /etc/nginx/nginx.conf; then
    echo "✓ server_tokens 已设置"
else
    echo "添加 server_tokens off 到 http 块..."
    sed -i '/http {/a\    server_tokens off;' /etc/nginx/nginx.conf
    echo "✓ 已添加 server_tokens off"
fi

echo -e "\n[5] 测试 Nginx 配置..."
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
    
    if [ -f /etc/nginx/snippets/api-protection.conf.backup ]; then
        echo "恢复备份..."
        mv /etc/nginx/snippets/api-protection.conf.backup /etc/nginx/snippets/api-protection.conf
    fi
    
    exit 1
fi

echo -e "\n=========================================="
echo "修复完成！"
echo "=========================================="
echo ""
echo "如需安装 headers-more 模块（可选）："
echo "  Ubuntu/Debian: sudo apt install nginx-extras"
echo "  CentOS/RHEL: sudo yum install nginx-mod-http-headers-more"
echo ""
echo "备份文件: /etc/nginx/snippets/api-protection.conf.backup"
echo "=========================================="
