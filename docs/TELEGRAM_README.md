# 🚀 快速开始 - Telegram 通知功能

## 🎯 三步配置，立即使用

### 步骤 1️⃣：获取 Telegram 凭据（2分钟）

**获取 Bot Token:**
1. 在 Telegram 搜索 `@BotFather`
2. 发送 `/newbot` 并按提示创建
3. 复制 Token（格式：`123456789:ABC...`）

**获取 Chat ID:**
1. 在 Telegram 搜索 `@userinfobot`
2. 发送 `/start`
3. 复制你的 ID（纯数字）

### 步骤 2️⃣：配置项目（1分钟）

```bash
# 方式 A：使用环境变量（推荐）
cp .env.example .env
nano .env  # 填入真实的 Token 和 Chat ID

# 方式 B：直接修改配置文件
nano config/config.yaml
# 将 YOUR_BOT_TOKEN_HERE 和 YOUR_CHAT_ID_HERE 替换为真实值
# 并将 enabled: false 改为 enabled: true
```

### 步骤 3️⃣：启动并测试（1分钟）

```bash
# 启动服务
go run .

# 在另一个终端测试
./test-telegram.sh
```

**✅ 完成！** 你应该收到 Telegram 通知了！

---

## 📚 详细文档

| 文档 | 用途 |
|------|------|
| [TELEGRAM_QUICKSTART.md](./TELEGRAM_QUICKSTART.md) | 5分钟快速配置指南 ⭐ |
| [TELEGRAM_INTEGRATION_GUIDE.md](./TELEGRAM_INTEGRATION_GUIDE.md) | 完整功能文档 |
| [SECURITY_NOTICE.md](./SECURITY_NOTICE.md) | 安全最佳实践 🔒 |

---

## 🧪 测试工具

```bash
# 功能测试
./test-telegram.sh

# 部署检查
./check-telegram-setup.sh

# 安全检查
./check-sensitive-info.sh
```

---

## ⚙️ 配置示例

### 环境变量方式（推荐）

`.env` 文件：
```bash
TELEGRAM_BOT_TOKEN=你的真实Token
TELEGRAM_CHAT_ID=你的真实ChatID
```

### 配置文件方式

`config/config.yaml`：
```yaml
telegram:
  enabled: true
  botToken: "你的真实Token"
  chatId: "你的真实ChatID"
  timeout: 5s
```

---

## 🔒 安全提示

⚠️ **本项目是公开仓库！**

- ✅ `.env` 文件已在 `.gitignore` 中，不会被提交
- ✅ 提交前运行 `./check-sensitive-info.sh` 检查
- ✅ 建议安装 pre-commit hook：
  ```bash
  cp pre-commit-hook.sh .git/hooks/pre-commit
  chmod +x .git/hooks/pre-commit
  ```

---

## ❓ 常见问题

**Q: 没收到通知？**
1. 检查 `enabled: true`
2. 确认 Token 和 ChatID 正确
3. 查看日志：`journalctl -u checksum-api -f | grep telegram`

**Q: Token 泄露了？**
1. 立即在 @BotFather 撤销旧 Token
2. 参考 [SECURITY_NOTICE.md](./SECURITY_NOTICE.md)

**Q: 影响性能吗？**
不影响！通知是异步发送的，API 响应时间 +0ms

---

## 📞 获取帮助

- 📖 查看 [完整文档](./TELEGRAM_INTEGRATION_GUIDE.md)
- 🐛 [提交 Issue](https://github.com/KaikiDeishuuu/CRC_LRC/issues)
- 💬 [讨论区](https://github.com/KaikiDeishuuu/CRC_LRC/discussions)

---

**🎉 享受 Telegram 通知功能吧！**
