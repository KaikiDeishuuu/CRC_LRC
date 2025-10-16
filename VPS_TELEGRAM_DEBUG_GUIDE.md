# VPS Telegram 通知调试指南

## 📋 目录

- [代码已推送](#代码已推送)
- [VPS 端操作步骤](#vps-端操作步骤)
- [配置 Telegram](#配置-telegram)
- [测试和验证](#测试和验证)
- [常见问题排查](#常见问题排查)

---

## ✅ 代码已推送

最新代码已推送到 `DEV` 分支，包含：

- ✅ Telegram 通知功能完整实现
- ✅ 诊断脚本 `scripts/diagnose-telegram.sh`
- ✅ 所有文档和测试工具

---

## 🚀 VPS 端操作步骤

### 1️⃣ 登录 VPS 并进入项目目录

```bash
# SSH 登录 VPS
ssh your_user@your_vps_ip

# 进入项目目录
cd /path/to/CRC_LRC
```

### 2️⃣ 拉取最新代码

```bash
# 确保在 DEV 分支
git checkout DEV

# 拉取最新代码
git pull origin DEV

# 验证新文件
ls -la scripts/diagnose-telegram.sh
```

### 3️⃣ 运行诊断脚本（第一次检查）

```bash
# 给脚本执行权限
chmod +x scripts/diagnose-telegram.sh

# 运行诊断
./scripts/diagnose-telegram.sh
```

**预期输出**：脚本会检查并提示哪些配置缺失

---

## 🔧 配置 Telegram

### 方式一：使用一键配置脚本（推荐）

```bash
# 运行配置脚本
./scripts/install-or-update.sh

# 按照提示操作：
# 1. 输入 Bot Token
# 2. 输入 Chat ID
# 3. 脚本会自动更新 config.yaml 并重启容器
```

### 方式二：手动编辑配置文件

```bash
# 编辑配置文件
nano config/config.yaml

# 修改以下部分：
telegram:
  enabled: true                          # 改为 true
  botToken: "你的真实Token"               # 替换为真实 Token
  chatId: "你的真实ChatID"                # 替换为真实 Chat ID
  timeout: 5s
```

保存后重启容器：

```bash
docker-compose down
docker-compose up -d --build
```

### 方式三：使用环境变量（Docker 推荐）

如果你的服务器使用 Docker 部署，可以创建 `.env` 文件：

```bash
# 在项目根目录创建 .env 文件
cat > .env << 'EOF'
TELEGRAM_BOT_TOKEN=你的真实Token
TELEGRAM_CHAT_ID=你的真实ChatID
TELEGRAM_ENABLED=true
EOF

# 确保 .env 文件权限安全
chmod 600 .env
```

然后修改 `docker-compose.yml` 使用环境变量：

```yaml
services:
  checksum-api:
    # ... 其他配置 ...
    environment:
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
      - TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID}
      - TELEGRAM_ENABLED=${TELEGRAM_ENABLED:-true}
```

**注意**：如果使用环境变量，需要修改 `config/config.go` 来读取环境变量（见下方补充代码）

---

## 🧪 测试和验证

### 1️⃣ 再次运行诊断脚本

```bash
./scripts/diagnose-telegram.sh
```

**检查以下输出**：

- ✅ `enabled: true` 已设置
- ✅ Bot Token 已配置
- ✅ Chat ID 已配置
- ✅ Telegram API 连接测试成功
- ✅ 测试消息发送成功

### 2️⃣ 直接测试 Telegram API

```bash
# 替换为你的实际值
BOT_TOKEN="你的Token"
CHAT_ID="你的ChatID"

# 发送测试消息
curl -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "{\"chat_id\":\"${CHAT_ID}\",\"text\":\"🧪 VPS 测试消息 - $(date)\"}"
```

**如果收到消息**，说明 Token 和 Chat ID 配置正确！

### 3️⃣ 测试 API 并验证通知

```bash
# 调用 API
curl -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"Hello World","method":"text"}'

# 查看日志
docker logs -f $(docker ps | grep crc_lrc | awk '{print $1}')
```

**检查日志中是否有**：

- `✅ Telegram notification sent successfully`
- 或错误信息以便调试

### 4️⃣ 查看实时日志

```bash
# 实时查看所有日志
docker logs -f $(docker ps | grep crc_lrc | awk '{print $1}')

# 只看 Telegram 相关日志
docker logs -f $(docker ps | grep crc_lrc | awk '{print $1}') 2>&1 | grep -i telegram
```

---

## 🔍 常见问题排查

### ❌ 问题 1: "Telegram notification is disabled"

**原因**：`config.yaml` 中 `enabled: false`

**解决**：

```bash
# 修改配置
sed -i 's/enabled: false/enabled: true/' config/config.yaml

# 重启容器
docker-compose restart
```

---

### ❌ 问题 2: "chat not found"

**原因**：Chat ID 不正确，或未向 Bot 发送过消息

**解决**：

1. 在 Telegram 中搜索你的 Bot（使用 `@BotFather` 创建时的用户名）
2. 点击 **Start** 按钮
3. 发送任意消息给 Bot
4. 重新获取 Chat ID：

```bash
BOT_TOKEN="你的Token"
curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates" | jq '.result[0].message.chat.id'
```

---

### ❌ 问题 3: "Unauthorized" 或 401 错误

**原因**：Bot Token 无效或过期

**解决**：

1. 在 Telegram 中找到 `@BotFather`
2. 发送 `/mybots` 查看你的 Bot
3. 选择你的 Bot → API Token → 复制新 Token
4. 更新配置文件

---

### ❌ 问题 4: "Forbidden: bot was blocked by the user"

**原因**：你在 Telegram 中屏蔽了 Bot

**解决**：

1. 在 Telegram 中找到 Bot
2. 点击 Bot 头像 → 解除屏蔽
3. 重新发送 `/start`

---

### ❌ 问题 5: 配置正确但没收到通知

**可能原因**：

1. **Docker 容器未重启**：配置修改后需要重启

   ```bash
   docker-compose restart
   ```

2. **代码未读取环境变量**：如果使用 `.env`，检查代码是否支持

3. **网络问题**：VPS 可能无法访问 Telegram API

   ```bash
   # 测试网络连通性
   curl -I https://api.telegram.org
   ```

4. **日志级别太高**：修改 `config.yaml` 设置日志为 `debug`

   ```yaml
   log:
     level: debug
   ```

---

## 🛠️ 补充代码（可选）

如果你想让代码支持从环境变量读取配置，需要修改 `config/config.go`：

### 修改 `config/config.go` 的 `LoadConfig` 函数

在 `LoadConfig()` 函数的最后，添加环境变量覆盖：

```go
func LoadConfig() error {
    // ... 现有代码 ...

    if err := viper.Unmarshal(&Cfg); err != nil {
        return fmt.Errorf("failed to unmarshal config: %w", err)
    }

    // 🆕 环境变量覆盖
    if token := os.Getenv("TELEGRAM_BOT_TOKEN"); token != "" {
        Cfg.Telegram.BotToken = token
    }
    if chatId := os.Getenv("TELEGRAM_CHAT_ID"); chatId != "" {
        Cfg.Telegram.ChatId = chatId
    }
    if enabled := os.Getenv("TELEGRAM_ENABLED"); enabled != "" {
        Cfg.Telegram.Enabled = (enabled == "true")
    }

    return nil
}
```

记得添加 `import "os"` 在文件顶部。

---

## 📊 完整测试流程

### 一键测试脚本

在 VPS 上运行以下命令完成所有测试：

```bash
#!/bin/bash
echo "🚀 开始 Telegram 通知完整测试"
echo "================================"

# 1. 诊断配置
echo -e "\n📋 1. 运行诊断脚本"
./scripts/diagnose-telegram.sh

# 2. 测试 API
echo -e "\n🧪 2. 调用 API 测试"
curl -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"VPS Test","method":"text"}'

# 3. 查看日志
echo -e "\n📋 3. 查看最近 20 条日志"
docker logs --tail 20 $(docker ps | grep crc_lrc | awk '{print $1}')

echo -e "\n✅ 测试完成！请检查 Telegram 是否收到通知"
```

保存为 `test-vps-telegram.sh` 并运行：

```bash
chmod +x test-vps-telegram.sh
./test-vps-telegram.sh
```

---

## 📞 需要帮助？

如果按照以上步骤仍无法解决问题，请提供以下信息：

1. 诊断脚本的完整输出：`./scripts/diagnose-telegram.sh`
2. Docker 日志：`docker logs $(docker ps | grep crc_lrc | awk '{print $1}') --tail 50`
3. 配置文件内容：`cat config/config.yaml`
4. Telegram API 测试结果

---

## 🎉 成功标志

当你看到以下内容时，说明配置成功：

1. ✅ 诊断脚本所有检查通过
2. ✅ Telegram 收到测试消息
3. ✅ API 调用后收到通知
4. ✅ 日志显示 `✅ Telegram notification sent successfully`

---

**祝调试顺利！🚀**
