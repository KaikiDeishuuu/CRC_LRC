# Telegram 通知集成指南

## 📋 功能概述

当用户使用 CRC/LRC 计算器时，系统会自动向 Telegram 发送通知，包含以下信息：

- 🛠 工具名称
- 📊 输入数据
- 🔢 方法类型
- ✅ 计算结果
- 📍 用户 IP 地址
- 🌐 User-Agent
- ⏰ 访问时间

**特点：异步发送，不阻塞 API 响应！**

---

## 🚀 快速开始

### 1. 配置 Telegram

编辑 `config/config.yaml`：

```yaml
telegram:
  enabled: true  # 启用通知
  botToken: "你的机器人Token"
  chatId: "你的Chat ID"
  timeout: 5s
```

### 2. 重启服务

```bash
# 如果使用 systemd
sudo systemctl restart checksum-api.service

# 或直接运行
make run

# 或 Docker
docker-compose restart
```

### 3. 测试

```bash
# 赋予执行权限
chmod +x test-telegram.sh

# 运行测试
./test-telegram.sh
```

---

## 🔧 详细配置

### Telegram 配置项说明

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `enabled` | bool | `false` | 是否启用 Telegram 通知 |
| `botToken` | string | `""` | Telegram Bot Token |
| `chatId` | string | `""` | 接收消息的 Chat ID |
| `timeout` | duration | `5s` | 发送超时时间 |

### 如何获取 Bot Token 和 Chat ID

#### 获取 Bot Token

1. 在 Telegram 中搜索 `@BotFather`
2. 发送 `/newbot` 创建新机器人
3. 按提示设置机器人名称
4. 获得 Token，格式类似：`123456789:ABCdefGHIjklMNOpqrsTUVwxyz`

#### 获取 Chat ID

**方法 1：使用 userinfobot**
1. 在 Telegram 搜索 `@userinfobot`
2. 发送 `/start`
3. 获得你的 Chat ID

**方法 2：使用 API**
1. 向你的机器人发送任意消息
2. 访问：`https://api.telegram.org/bot<YourBOTToken>/getUpdates`
3. 在返回的 JSON 中找到 `"chat":{"id":123456789}`

---

## 📊 通知消息格式

```
🔧 工具使用通知

🛠 工具名称: CRC/LRC Calculator
📊 输入数据: Hello World
🔢 方法: API Query
✅ 结果: CRC16-MODBUS: 0x4842, CRC16-CCITT: 0x1B0F, CRC32-IEEE: 0x4A17B156, SUM8: 0x4F

📍 来源信息:
• IP: 192.168.1.100
• User-Agent: Mozilla/5.0...
• 时间: 2025-10-17 15:30:45
```

---

## 🔒 安全建议

### 1. 使用环境变量（推荐）

不要将敏感信息硬编码在配置文件中：

```bash
# 设置环境变量
export TELEGRAM_BOT_TOKEN="你的Token"
export TELEGRAM_CHAT_ID="你的ChatID"
```

修改 `config/config.go` 支持环境变量：

```go
import "os"

func LoadConfig() error {
    // ... 现有代码 ...
    
    // 从环境变量读取（优先级高于配置文件）
    if token := os.Getenv("TELEGRAM_BOT_TOKEN"); token != "" {
        Cfg.Telegram.BotToken = token
    }
    if chatId := os.Getenv("TELEGRAM_CHAT_ID"); chatId != "" {
        Cfg.Telegram.ChatId = chatId
    }
    
    return nil
}
```

### 2. 配置文件权限

```bash
# 限制配置文件权限
chmod 600 config/config.yaml
```

### 3. Git 忽略配置

确保 `.gitignore` 包含：

```gitignore
config/config.yaml
.env
```

---

## 🧪 测试和调试

### 手动测试

```bash
# 测试基本功能
curl "http://localhost:8080/api/checksum?input=Hello"

# 测试十六进制输入
curl "http://localhost:8080/api/checksum?input=0x414243"

# 测试中文
curl "http://localhost:8080/api/checksum?input=测试"
```

### 查看日志

```bash
# systemd 日志
journalctl -u checksum-api.service -f

# Docker 日志
docker-compose logs -f

# 或直接运行时的控制台输出
```

### 调试模式

启用调试日志：

```yaml
log:
  level: debug  # 从 info 改为 debug
```

---

## 🔧 高级配置

### 自定义通知内容

编辑 `internal/notification/telegram.go` 中的 `formatMessage` 函数：

```go
func formatMessage(data NotificationData) string {
    return fmt.Sprintf(
        "🎯 自定义标题\n\n"+
        "输入: %s\n"+
        "结果: %s\n"+
        "来自: %s",
        data.InputData,
        data.Result,
        data.IP,
    )
}
```

### 添加更多通知场景

在其他 handler 中也可以使用：

```go
import "CRC_LRC/internal/notification"

func SomeHandler(w http.ResponseWriter, r *http.Request) {
    // ... 你的逻辑 ...
    
    notification.SendTelegramNotification(notification.NotificationData{
        ToolName:  "其他工具",
        InputData: "输入数据",
        Method:    "方法",
        Result:    "结果",
        IP:        getClientIP(r),
        UserAgent: r.Header.Get("User-Agent"),
    })
}
```

### 禁用特定 IP 的通知

在 `checksum_handler.go` 中添加过滤：

```go
func sendChecksumNotification(r *http.Request, input string, result Result) {
    ip := getClientIP(r)
    
    // 跳过本地请求
    if ip == "127.0.0.1" || ip == "::1" {
        return
    }
    
    // 跳过内网 IP
    if strings.HasPrefix(ip, "192.168.") || strings.HasPrefix(ip, "10.") {
        return
    }
    
    // ... 发送通知 ...
}
```

---

## ⚠️ 常见问题

### Q1: 通知没有发送

**检查清单：**
1. ✅ `telegram.enabled` 设置为 `true`
2. ✅ Token 和 ChatID 正确
3. ✅ 机器人可以发送消息（不是被封禁）
4. ✅ 网络连接正常（可访问 api.telegram.org）

**调试方法：**
```bash
# 测试 Telegram API 连通性
curl "https://api.telegram.org/bot<YourToken>/getMe"

# 手动发送测试消息
curl -X POST "https://api.telegram.org/bot<YourToken>/sendMessage" \
  -H "Content-Type: application/json" \
  -d '{"chat_id":"<YourChatID>","text":"测试"}'
```

### Q2: 通知延迟很高

通知是异步的，通常在 1-3 秒内送达。如果延迟过高：

1. 检查网络连接
2. 增加 `timeout` 配置
3. 查看日志是否有错误

### Q3: 消息格式错误

如果消息显示异常：

1. 检查输入数据是否包含特殊字符
2. `formatMessage` 中已包含 HTML 转义
3. 可以切换到 `parse_mode: "Markdown"` 或去掉 `parse_mode`

### Q4: 影响 API 性能

通知是**异步发送**的，不会阻塞 API 响应。如果仍有性能问题：

1. 临时禁用：`telegram.enabled: false`
2. 减少 `timeout` 值
3. 添加 IP 过滤（见高级配置）

---

## 📈 性能影响

| 指标 | 值 |
|------|-----|
| API 响应延迟增加 | **0ms**（异步） |
| 内存开销 | ~50KB/请求（goroutine） |
| CPU 开销 | 可忽略 |
| 网络带宽 | ~1KB/通知 |

**结论：对 API 性能几乎无影响！**

---

## 🎯 最佳实践

1. ✅ **启用日志** - 便于排查问题
2. ✅ **使用环境变量** - 保护敏感信息
3. ✅ **合理设置超时** - 避免长时间等待
4. ✅ **监控通知状态** - 定期检查日志
5. ✅ **限制通知频率** - 避免被 Telegram 限流

---

## 📚 相关文档

- [Telegram Bot API 官方文档](https://core.telegram.org/bots/api)
- [项目 API 文档](./API_DOCUMENTATION.md)
- [部署指南](./DEPLOYMENT.md)
- [配置说明](./config/README.md)

---

## 🤝 贡献

如果你有改进建议：

1. Fork 项目
2. 创建特性分支
3. 提交 Pull Request

---

## 📄 许可

本项目遵循 MIT 许可证。

---

**祝使用愉快！** 🎉

有问题请提交 Issue 或联系维护者。
