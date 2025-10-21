#!/bin/bash

# Nginx 配置安装脚本
# 将 API 反向代理配置添加到现有的 Nginx 配置中

set -e

echo "=========================================="
echo "配置 Nginx 反向代理"
echo "=========================================="

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo "请使用 root 权限运行此脚本"
    echo "使用: sudo ./install-nginx-config.sh"
    exit 1
fi

# 询问是否配置 Nginx
echo -e "\n是否需要配置 Nginx 反向代理？"
echo "如果你已经手动配置或不需要配置，可以跳过。"
read -p "配置 Nginx? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "跳过 Nginx 配置"
    echo ""
    echo "你可以手动添加以下配置到你的 Nginx 站点配置中:"
    echo ""
    cat << 'EOF'
location /api/ {
    proxy_pass http://localhost:8080/api/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
EOF
    exit 0
fi

# 询问域名
echo -e "\n请输入你的域名（例如: www.example.com）"
read -p "域名: " DOMAIN_NAME

if [ -z "$DOMAIN_NAME" ]; then
    echo "❌ 域名不能为空"
    exit 1
fi

echo "将配置反向代理到域名: $DOMAIN_NAME"

# 查找 Nginx 配置文件
echo -e "\n[1] 查找现有 Nginx 配置..."
NGINX_CONF=""

# 可能的配置文件位置
POSSIBLE_CONFIGS=(
    "/etc/nginx/sites-available/$DOMAIN_NAME"
    "/etc/nginx/sites-available/default"
    "/etc/nginx/conf.d/$DOMAIN_NAME.conf"
    "/etc/nginx/conf.d/default.conf"
)

for conf in "${POSSIBLE_CONFIGS[@]}"; do
    if [ -f "$conf" ]; then
        echo "找到配置文件: $conf"
        NGINX_CONF="$conf"
        break
    fi
done

if [ -z "$NGINX_CONF" ]; then
    echo "❌ 未找到 Nginx 配置文件"
    echo "请手动指定配置文件路径:"
    read -p "输入配置文件完整路径: " NGINX_CONF
    
    if [ ! -f "$NGINX_CONF" ]; then
        echo "❌ 配置文件不存在: $NGINX_CONF"
        exit 1
    fi
fi

# 备份原配置
echo -e "\n[2] 备份原配置文件..."
BACKUP_FILE="${NGINX_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$NGINX_CONF" "$BACKUP_FILE"
echo "✓ 备份保存到: $BACKUP_FILE"

# 检查是否已经配置过
echo -e "\n[3] 检查现有配置..."
if grep -q "location /api/" "$NGINX_CONF"; then
    echo "⚠️  警告: 配置文件中已存在 /api/ location 块"
    read -p "是否继续（会注释掉旧配置）? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "取消配置"
        exit 0
    fi
    
    # 注释掉旧的 API 配置
    sed -i '/location \/api\//,/}/s/^/# /' "$NGINX_CONF"
fi

# 读取配置模板
API_CONFIG=$(cat nginx-api-config.conf | grep -A 50 "location /api/")

# 找到合适的插入位置（在 server 块内，最后一个 location 之后）
echo -e "\n[4] 添加 API 代理配置..."

# 创建临时文件
TEMP_FILE=$(mktemp)

# 在最后一个 } 之前插入配置
awk -v api_config="$API_CONFIG" '
    # 记录每一行
    {lines[NR] = $0}
    END {
        # 从后往前找第一个 }
        for (i=NR; i>=1; i--) {
            if (lines[i] ~ /^}/) {
                # 在这个 } 之前插入 API 配置
                for (j=1; j<i; j++) {
                    print lines[j]
                }
                print ""
                print "    # =========================================="
                print "    # API 反向代理配置 (自动添加)"
                print "    # =========================================="
                print api_config
                print ""
                for (j=i; j<=NR; j++) {
                    print lines[j]
                }
                exit
            }
        }
        # 如果没找到，直接输出原文件
        for (j=1; j<=NR; j++) {
            print lines[j]
        }
    }
' "$NGINX_CONF" > "$TEMP_FILE"

# 应用新配置
mv "$TEMP_FILE" "$NGINX_CONF"

echo "✓ 配置已添加"

# 测试配置
echo -e "\n[5] 测试 Nginx 配置..."
if nginx -t; then
    echo "✓ Nginx 配置测试通过"
else
    echo "❌ Nginx 配置测试失败"
    echo "正在恢复备份..."
    cp "$BACKUP_FILE" "$NGINX_CONF"
    echo "已恢复原配置"
    exit 1
fi

# 重载 Nginx
echo -e "\n[6] 重载 Nginx..."
systemctl reload nginx
echo "✓ Nginx 已重载"

echo -e "\n=========================================="
echo "配置完成！"
echo "=========================================="
echo ""
echo "现在可以通过以下地址访问:"
echo "  • API: https://$DOMAIN_NAME/api/checksum"
echo "  • Web UI: https://$DOMAIN_NAME/checksum-tool/"
echo ""
echo "测试命令:"
echo "  curl -X POST https://$DOMAIN_NAME/api/checksum \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"data\":\"Hello\",\"method\":\"text\"}'"
echo ""
echo "备份文件: $BACKUP_FILE"
echo "=========================================="
