#!/bin/bash
# CRC_LRC 傻瓜式安装/更新脚本
# 适用于首次安装或更新现有部署

set -e  # 遇到错误立即退出

echo "╔════════════════════════════════════════════╗"
echo "║   CRC_LRC 傻瓜式安装/更新脚本             ║"
echo "║   支持 Docker 自动部署                     ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 获取脚本所在目录的父目录（项目根目录）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo -e "${CYAN}项目目录: $PROJECT_DIR${NC}"
echo ""

# ============================================
# 步骤 1: 检测环境
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}步骤 1/8: 检测环境${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ 未安装 Docker${NC}"
    echo ""
    echo "请先安装 Docker:"
    echo "  curl -fsSL https://get.docker.com | sh"
    echo "  sudo systemctl start docker"
    echo "  sudo systemctl enable docker"
    exit 1
fi
echo -e "${GREEN}✓ Docker 已安装${NC}"

# 检查 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}✗ 未安装 Docker Compose${NC}"
    echo ""
    echo "请先安装 Docker Compose:"
    echo "  sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
    echo "  sudo chmod +x /usr/local/bin/docker-compose"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose 已安装${NC}"

# 检查是否为首次安装
IS_FIRST_INSTALL=false
if [ ! -f "config/config.yaml" ] || [ ! -f ".env" ]; then
    IS_FIRST_INSTALL=true
    echo -e "${YELLOW}⚠ 检测到首次安装${NC}"
else
    echo -e "${CYAN}ℹ 检测到已有配置，将进行更新${NC}"
fi

echo ""

# ============================================
# 步骤 2: 备份现有配置（如果存在）
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}步骤 2/8: 备份配置${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"

if [ "$IS_FIRST_INSTALL" = false ]; then
    mkdir -p "$BACKUP_DIR"
    
    if [ -f "config/config.yaml" ]; then
        cp config/config.yaml "$BACKUP_DIR/"
        echo -e "${GREEN}✓ 已备份 config.yaml${NC}"
    fi
    
    if [ -f ".env" ]; then
        cp .env "$BACKUP_DIR/"
        echo -e "${GREEN}✓ 已备份 .env${NC}"
    fi
    
    echo -e "${CYAN}备份位置: $BACKUP_DIR${NC}"
else
    echo -e "${YELLOW}首次安装，跳过备份${NC}"
fi

echo ""

# ============================================
# 步骤 3: Telegram 配置
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}步骤 3/8: 配置 Telegram 通知（可选）${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 尝试从现有配置读取
EXISTING_TOKEN=""
EXISTING_CHATID=""
TELEGRAM_ENABLED="false"

if [ -f ".env" ]; then
    EXISTING_TOKEN=$(grep "^TELEGRAM_BOT_TOKEN=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "")
    EXISTING_CHATID=$(grep "^TELEGRAM_CHAT_ID=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "")
fi

if [ -z "$EXISTING_TOKEN" ] && [ -f "config/config.yaml" ]; then
    EXISTING_TOKEN=$(grep "botToken:" config/config.yaml 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "")
    EXISTING_CHATID=$(grep "chatId:" config/config.yaml 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "")
fi

# 过滤掉占位符
if [[ "$EXISTING_TOKEN" == "YOUR_BOT_TOKEN_HERE" ]] || [[ "$EXISTING_TOKEN" == "" ]]; then
    EXISTING_TOKEN=""
fi
if [[ "$EXISTING_CHATID" == "YOUR_CHAT_ID_HERE" ]] || [[ "$EXISTING_CHATID" == "" ]]; then
    EXISTING_CHATID=""
fi

# 询问是否配置 Telegram
echo -e "${CYAN}Telegram 通知可以在用户使用 API 时发送消息到您的手机。${NC}"
echo ""

if [ -n "$EXISTING_TOKEN" ] && [ -n "$EXISTING_CHATID" ]; then
    echo -e "${GREEN}检测到已有 Telegram 配置：${NC}"
    echo "  Bot Token: ${EXISTING_TOKEN:0:20}...${EXISTING_TOKEN: -10}"
    echo "  Chat ID: $EXISTING_CHATID"
    echo ""
    read -p "是否保留现有配置？(Y/n) " -n 1 -r USE_EXISTING
    echo
    if [[ $USE_EXISTING =~ ^[Yy]$ ]] || [[ -z $USE_EXISTING ]]; then
        BOT_TOKEN="$EXISTING_TOKEN"
        CHAT_ID="$EXISTING_CHATID"
        TELEGRAM_ENABLED="true"
        echo -e "${GREEN}✓ 将使用现有 Telegram 配置${NC}"
    else
        EXISTING_TOKEN=""
        EXISTING_CHATID=""
    fi
fi

if [ -z "$BOT_TOKEN" ]; then
    read -p "是否配置 Telegram 通知？(y/N) " -n 1 -r ENABLE_TELEGRAM
    echo
    
    if [[ $ENABLE_TELEGRAM =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}如何获取 Telegram 凭据：${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "📱 获取 Bot Token:"
        echo "  1. 在 Telegram 搜索 @BotFather"
        echo "  2. 发送 /newbot 并按提示创建机器人"
        echo "  3. 复制 Token（格式：123456789:ABC...）"
        echo ""
        echo "📱 获取 Chat ID:"
        echo "  1. 在 Telegram 搜索 @userinfobot"
        echo "  2. 发送 /start"
        echo "  3. 复制你的 ID（纯数字）"
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        # 输入 Bot Token
        while true; do
            read -p "请输入 Telegram Bot Token: " BOT_TOKEN
            if [ -z "$BOT_TOKEN" ]; then
                echo -e "${RED}Token 不能为空，请重新输入${NC}"
                continue
            fi
            if [[ ! $BOT_TOKEN =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
                echo -e "${YELLOW}⚠ Token 格式可能不正确（应该是：数字:字母数字）${NC}"
                read -p "是否继续使用此 Token？(y/N) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    continue
                fi
            fi
            break
        done
        
        # 输入 Chat ID
        while true; do
            read -p "请输入 Telegram Chat ID: " CHAT_ID
            if [ -z "$CHAT_ID" ]; then
                echo -e "${RED}Chat ID 不能为空，请重新输入${NC}"
                continue
            fi
            if [[ ! $CHAT_ID =~ ^-?[0-9]+$ ]]; then
                echo -e "${YELLOW}⚠ Chat ID 格式可能不正确（应该是纯数字）${NC}"
                read -p "是否继续使用此 Chat ID？(y/N) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    continue
                fi
            fi
            break
        done
        
        TELEGRAM_ENABLED="true"
        echo ""
        echo -e "${GREEN}✓ Telegram 配置已完成${NC}"
        
        # 测试连接（可选）
        echo ""
        read -p "是否测试 Telegram 连接？(Y/n) " -n 1 -r TEST_TG
        echo
        if [[ $TEST_TG =~ ^[Yy]$ ]] || [[ -z $TEST_TG ]]; then
            echo -e "${CYAN}正在测试连接...${NC}"
            TEST_RESULT=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
                -H "Content-Type: application/json" \
                -d "{\"chat_id\":\"${CHAT_ID}\",\"text\":\"🎉 CRC_LRC 安装测试消息\"}")
            
            if echo "$TEST_RESULT" | grep -q '"ok":true'; then
                echo -e "${GREEN}✓ Telegram 连接测试成功！请查看手机${NC}"
            else
                echo -e "${RED}✗ Telegram 连接测试失败${NC}"
                echo "错误信息: $TEST_RESULT"
                echo ""
                read -p "是否继续安装？(Y/n) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
                    echo "安装已取消"
                    exit 1
                fi
            fi
        fi
    else
        echo -e "${YELLOW}跳过 Telegram 配置（可稍后配置）${NC}"
        TELEGRAM_ENABLED="false"
    fi
fi

echo ""

# ============================================
# 步骤 4: 生成配置文件
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}步骤 4/8: 生成配置文件${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 确保配置目录存在
mkdir -p config

# 生成 .env 文件
if [ "$TELEGRAM_ENABLED" = "true" ]; then
    cat > .env << EOF
# Telegram 配置
TELEGRAM_BOT_TOKEN=${BOT_TOKEN}
TELEGRAM_CHAT_ID=${CHAT_ID}
EOF
    echo -e "${GREEN}✓ 已生成 .env 文件（包含 Telegram 配置）${NC}"
else
    cat > .env << EOF
# Telegram 配置（未启用）
# TELEGRAM_BOT_TOKEN=YOUR_BOT_TOKEN_HERE
# TELEGRAM_CHAT_ID=YOUR_CHAT_ID_HERE
EOF
    echo -e "${YELLOW}✓ 已生成 .env 文件（Telegram 未启用）${NC}"
fi

# 更新 config.yaml
if [ ! -f "config/config.yaml" ]; then
    echo -e "${CYAN}创建新的 config.yaml...${NC}"
    cp config/config.yaml.example config/config.yaml 2>/dev/null || true
fi

# 更新 config.yaml 中的 Telegram 配置
if [ -f "config/config.yaml" ]; then
    # 使用 sed 更新配置
    sed -i "s/enabled: .*/enabled: ${TELEGRAM_ENABLED}/" config/config.yaml
    if [ "$TELEGRAM_ENABLED" = "true" ]; then
        sed -i "s|botToken:.*|botToken: \"${BOT_TOKEN}\"|" config/config.yaml
        sed -i "s|chatId:.*|chatId: \"${CHAT_ID}\"|" config/config.yaml
    fi
    echo -e "${GREEN}✓ 已更新 config.yaml${NC}"
fi

echo ""

# ============================================
# 步骤 5: 停止旧容器（如果存在）
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}步骤 5/8: 停止旧容器${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if docker-compose ps 2>/dev/null | grep -q "Up"; then
    echo -e "${YELLOW}检测到运行中的容器，正在停止...${NC}"
    docker-compose down
    echo -e "${GREEN}✓ 旧容器已停止${NC}"
else
    echo -e "${CYAN}未检测到运行中的容器${NC}"
fi

echo ""

# ============================================
# 步骤 6: 清理旧镜像（可选）
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}步骤 6/8: 清理旧镜像${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$IS_FIRST_INSTALL" = false ]; then
    read -p "是否清理旧的 Docker 镜像？(节省空间) (y/N) " -n 1 -r CLEAN_IMAGES
    echo
    if [[ $CLEAN_IMAGES =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}正在清理旧镜像...${NC}"
        docker image prune -f
        # 删除旧的 CRC_LRC 镜像
        docker images | grep crc_lrc | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
        echo -e "${GREEN}✓ 旧镜像已清理${NC}"
    else
        echo -e "${YELLOW}跳过清理${NC}"
    fi
else
    echo -e "${CYAN}首次安装，跳过清理${NC}"
fi

echo ""

# ============================================
# 步骤 7: 构建并启动新容器
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}步骤 7/8: 构建并启动容器${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${CYAN}正在构建 Docker 镜像（可能需要几分钟）...${NC}"
docker-compose build --no-cache || {
    echo -e "${RED}✗ Docker 构建失败${NC}"
    echo ""
    echo "可能的原因："
    echo "  1. 网络连接问题"
    echo "  2. Docker 磁盘空间不足"
    echo "  3. Dockerfile 配置错误"
    echo ""
    echo "请检查错误信息并重试"
    exit 1
}
echo -e "${GREEN}✓ Docker 镜像构建成功${NC}"

echo ""
echo -e "${CYAN}正在启动容器...${NC}"
docker-compose up -d || {
    echo -e "${RED}✗ 容器启动失败${NC}"
    echo ""
    echo "尝试查看日志："
    echo "  docker-compose logs"
    exit 1
}
echo -e "${GREEN}✓ 容器已启动${NC}"

echo ""

# ============================================
# 步骤 8: 健康检查
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}步骤 8/8: 健康检查${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${CYAN}等待服务启动...${NC}"
sleep 5

MAX_RETRIES=10
RETRY=0
API_OK=false

while [ $RETRY -lt $MAX_RETRIES ]; do
    if curl -f http://localhost:8080/api/checksum?input=test > /dev/null 2>&1; then
        API_OK=true
        break
    else
        RETRY=$((RETRY+1))
        if [ $RETRY -lt $MAX_RETRIES ]; then
            echo -e "${YELLOW}等待 API 就绪... ($RETRY/$MAX_RETRIES)${NC}"
            sleep 3
        fi
    fi
done

echo ""

if [ "$API_OK" = true ]; then
    echo -e "${GREEN}✓ API 健康检查通过${NC}"
else
    echo -e "${RED}✗ API 健康检查失败${NC}"
    echo ""
    echo "请检查日志："
    echo "  docker-compose logs -f"
    echo ""
    read -p "按回车键查看日志..." 
    docker-compose logs --tail=50
    exit 1
fi

# ============================================
# 完成
# ============================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                            ║${NC}"
echo -e "${GREEN}║    ✓ 安装/更新完成！                      ║${NC}"
echo -e "${GREEN}║                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""

# 显示访问信息
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}访问信息${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "🌐 本地访问:"
echo "   http://localhost:8080"
echo ""
echo "🔌 API 端点:"
echo "   http://localhost:8080/api/checksum?input=Hello"
echo ""

# 获取服务器公网 IP（如果是 VPS）
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "")
if [ -n "$PUBLIC_IP" ]; then
    echo "🌍 公网访问（如果开放了端口）:"
    echo "   http://$PUBLIC_IP:8080"
    echo ""
fi

if [ "$TELEGRAM_ENABLED" = "true" ]; then
    echo "📱 Telegram 通知: ${GREEN}已启用${NC}"
else
    echo "📱 Telegram 通知: ${YELLOW}未启用${NC}"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}常用命令${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "查看日志:"
echo "  docker-compose logs -f"
echo ""
echo "查看状态:"
echo "  docker-compose ps"
echo ""
echo "停止服务:"
echo "  docker-compose down"
echo ""
echo "重启服务:"
echo "  docker-compose restart"
echo ""
echo "更新服务:"
echo "  ./scripts/update-docker.sh"
echo ""
echo "测试 API:"
echo "  curl http://localhost:8080/api/checksum?input=test"
echo ""

if [ "$TELEGRAM_ENABLED" = "true" ]; then
    echo "测试 Telegram:"
    echo "  ./scripts/test-telegram.sh"
    echo ""
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}备份信息${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
if [ "$IS_FIRST_INSTALL" = false ]; then
    echo "配置备份位置: $BACKUP_DIR"
else
    echo "配置文件位置:"
    echo "  .env (包含 Telegram 凭据)"
    echo "  config/config.yaml"
fi
echo ""
echo -e "${YELLOW}⚠️  重要：请妥善保管 .env 文件，不要提交到公开仓库！${NC}"
echo ""

# 记录安装信息
INSTALL_LOG="logs/install.log"
mkdir -p logs
echo "[$(date)] 安装/更新完成 | Telegram: $TELEGRAM_ENABLED | 备份: $BACKUP_DIR" >> "$INSTALL_LOG"

echo -e "${GREEN}安装完成！祝使用愉快！ 🎉${NC}"
echo ""
