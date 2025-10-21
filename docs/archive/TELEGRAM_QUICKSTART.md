# Telegram 通知 - 5 分钟快速配置

## 🎯 目标

只需 3 个步骤，让你的 CRC_LRC API 自动发送 Telegram 通知！

---

## ⚡ 快速配置（3 步）

### 步骤 1: 获取 Telegram 凭据（2 分钟）

#### 1.1 创建 Bot 并获取 Token

1. 在 Telegram 搜索 **@BotFather**
2. 发送 `/newbot`
3. 按提示设置机器人名称
4. **复制 Token**（格式：`123456789:ABCdefGHI...`）

#### 1.2 获取 Chat ID

1. 在 Telegram 搜索 **@userinfobot**
2. 发送 `/start`
3. **复制你的 ID**（纯数字，如：`123456789`）

### 步骤 2: 配置项目（1 分钟）

编辑 `config/config.yaml`：

```yaml
telegram:
  enabled: true  # ⚠️ 改为 true
  botToken: "你的Token"  # ⚠️ 粘贴步骤 1.1 的 Token
  chatId: "你的ChatID"    # ⚠️ 粘贴步骤 1.2 的 ID
  timeout: 5s
```

**示例：**

```yaml
telegram:
  enabled: true
  botToken: "123456789:ABCdefGHIjklMNOpqrsTUVwxyz"  # 你的 Bot Token
  chatId: "987654321"  # 你的 Chat ID
  timeout: 5s
```

### 步骤 3: 重启服务（1 分钟）

```bash
# 方式 1: 如果使用 systemd
sudo systemctl restart checksum-api.service

# 方式 2: 如果使用 Docker
docker-compose restart

# 方式 3: 如果直接运行
# Ctrl+C 停止，然后重新运行
go run .
```

---

## ✅ 测试

### 方法 1: 使用测试脚本（推荐）

```bash
./test-telegram.sh
```

### 方法 2: 手动测试

```bash
curl "http://localhost:8080/api/checksum?input=Hello"
```

**预期结果：**
- ✅ API 正常返回 JSON 结果
- ✅ 几秒内收到 Telegram 消息

---

## 📱 通知示例

你会收到这样的消息：

```
🔧 工具使用通知

🛠 工具名称: CRC/LRC Calculator
📊 输入数据: Hello
🔢 方法: API Query
✅ 结果: CRC16-MODBUS: 0x14C4, CRC32-IEEE: 0xF7D18982

📍 来源信息:
• IP: 192.168.1.100
• User-Agent: curl/7.68.0
• 时间: 2025-10-17 15:30:45
```

---

## 🔧 故障排查

### 问题 1: 没收到通知

**检查清单：**

```bash
# 1. 确认配置正确
cat config/config.yaml | grep -A 4 telegram

# 2. 查看日志
# systemd
journalctl -u checksum-api.service -f | grep -i telegram

# Docker
docker-compose logs -f | grep -i telegram

# 直接运行
# 看控制台输出
```

**常见原因：**
- ❌ `enabled: false` 没改成 `true`
- ❌ Token 或 ChatID 复制错误（多了空格/引号）
- ❌ 网络无法访问 `api.telegram.org`
- ❌ 服务没有重启

### 问题 2: Token 无效

**测试 Token 是否有效：**

```bash
curl "https://api.telegram.org/bot<YourToken>/getMe"
```

**正确返回示例：**
```json
{
  "ok": true,
  "result": {
    "id": 123456789,
    "is_bot": true,
    "first_name": "Your Bot Name"
  }
}
```

### 问题 3: Chat ID 错误

**手动发送测试消息：**

```bash
curl -X POST "https://api.telegram.org/bot<YourToken>/sendMessage" \
  -H "Content-Type: application/json" \
  -d '{"chat_id":"<YourChatID>","text":"测试消息"}'
```

如果收到测试消息，说明 ChatID 正确。

---

## 🔒 安全建议（可选）

### 使用环境变量（推荐）

不要将 Token 硬编码在配置文件中：

```bash
# 1. 创建 .env 文件
cp .env.example .env

# 2. 编辑 .env
nano .env

# 3. 添加内容
TELEGRAM_BOT_TOKEN=你的Token
TELEGRAM_CHAT_ID=你的ChatID

# 4. 加载环境变量
source .env

# 5. 启动服务
go run .
```

### 配置文件权限

```bash
chmod 600 config/config.yaml
```

---

## 📚 下一步

配置成功后，可以：

1. 📖 阅读 [完整文档](./TELEGRAM_INTEGRATION_GUIDE.md)
2. 🎨 自定义通知格式
3. 🔧 添加 IP 过滤
4. 📊 查看使用统计

---

## 💡 提示

- ✅ **异步发送** - 不影响 API 性能
- ✅ **自动重试** - 网络异常时不会报错
- ✅ **灵活配置** - 可随时启用/禁用
- ✅ **隐私保护** - 只记录必要信息

---

## ❓ 需要帮助？

- 📖 [完整文档](./TELEGRAM_INTEGRATION_GUIDE.md)
- 🐛 [提交 Issue](https://github.com/KaikiDeishuuu/CRC_LRC/issues)
- 💬 [讨论区](https://github.com/KaikiDeishuuu/CRC_LRC/discussions)

---

**祝使用愉快！** 🎉
