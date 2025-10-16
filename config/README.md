# 配置文件说明

## 📋 配置文件使用指南

### 1️⃣ 首次配置

复制示例配置文件并修改：

```bash
cp config/config.yaml.example config/config.yaml
```

### 2️⃣ 配置 Telegram 通知

编辑 `config/config.yaml`：

```yaml
telegram:
  enabled: true # 启用通知
  botToken: "YOUR_BOT_TOKEN" # 替换为你的 Bot Token
  chatId: "YOUR_CHAT_ID" # 替换为你的 Chat ID
  timeout: 5s
```

#### 获取 Bot Token：

1. 在 Telegram 搜索 `@BotFather`
2. 发送 `/newbot` 创建新 bot
3. 按提示设置 bot 名称
4. 复制获得的 Token

#### 获取 Chat ID：

1. 在 Telegram 搜索 `@userinfobot`
2. 点击 Start
3. 复制显示的 ID 数字

### 3️⃣ 其他配置项

```yaml
server:
  port: 8080 # 服务端口
  readTimeout: 5s # 读取超时
  writeTimeout: 10s # 写入超时
  idleTimeout: 15s # 空闲超时
  maxHeaderBytes: 1048576 # 最大请求头大小 (1MB)

log:
  level: info # 日志级别: debug, info, warn, error

checksum:
  maxInputLengthBytes: 1048576 # 最大输入长度 (1MB)
  maxFileUploadSizeMB: 10 # 最大文件上传大小 (10MB)
```

## ⚠️ 安全提示

- **切勿提交** `config/config.yaml` 到 Git！
- 文件已添加到 `.gitignore`
- 生产环境使用环境变量更安全
- 定期更换敏感 Token

## 🔧 环境变量支持

如需使用环境变量，在代码中已支持覆盖配置文件的值。

示例：

```bash
export TELEGRAM_BOT_TOKEN="your_token"
export TELEGRAM_CHAT_ID="your_chat_id"
```

## 📝 配置文件位置

- `config/config.yaml` - 实际配置文件（不提交到 Git）
- `config/config.yaml.example` - 示例模板（提交到 Git）
- `config/config.go` - 配置加载代码

## 🆘 常见问题

### Q: 配置文件不存在？

A: 运行 `cp config/config.yaml.example config/config.yaml`

### Q: Telegram 通知不工作？

A: 检查：

1. `enabled: true`
2. Token 和 Chat ID 正确
3. 网络能访问 Telegram API
4. 运行诊断脚本：`./scripts/testing/diagnose-telegram.sh`

### Q: 如何禁用 Telegram 通知？

A: 设置 `telegram.enabled: false`
