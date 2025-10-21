# 🚀 VPS 快速操作命令卡片

## 📦 拉取最新代码

```bash
cd /path/to/CRC_LRC
git checkout DEV
git pull origin DEV
```

## 🔧 快速配置 Telegram

### 方式 1: 自动配置（推荐）

```bash
./scripts/install-or-update.sh
```

### 方式 2: 手动配置

```bash
nano config/config.yaml
# 修改:
#   enabled: true
#   botToken: "你的Token"
#   chatId: "你的ChatID"

docker-compose down && docker-compose up -d --build
```

## 🧪 诊断和测试

```bash
# 1. 完整诊断
./scripts/diagnose-telegram.sh

# 2. 测试 Telegram API
BOT_TOKEN="你的Token"
CHAT_ID="你的ChatID"
curl -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "{\"chat_id\":\"${CHAT_ID}\",\"text\":\"测试\"}"

# 3. 测试 API
curl -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"Test","method":"text"}'

# 4. 查看日志
docker logs -f $(docker ps | grep crc_lrc | awk '{print $1}')
```

## 🔍 获取 Bot Token 和 Chat ID

```bash
# 1. 创建 Bot: 在 Telegram 找 @BotFather，发送 /newbot
# 2. 获取 Token: 创建后会显示
# 3. 启动 Bot: 在 Telegram 搜索你的 Bot，点击 Start
# 4. 获取 Chat ID:
BOT_TOKEN="你的Token"
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates" | jq '.result[0].message.chat.id'
```

## 📋 常见问题快速修复

```bash
# 问题: 配置修改后没生效
docker-compose restart

# 问题: 容器一直重启
./debug-docker.sh

# 问题: 找不到日志中的 Telegram 信息
docker logs $(docker ps | grep crc_lrc | awk '{print $1}') 2>&1 | grep -i telegram

# 问题: 需要重新构建
docker-compose down
docker-compose up -d --build
```

## 📖 详细文档

完整指南：`VPS_TELEGRAM_DEBUG_GUIDE.md`
