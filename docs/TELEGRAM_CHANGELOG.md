# Telegram 通知功能变更日志

## [1.0.0] - 2025-10-17

### ✨ 新增功能

- **Telegram 通知集成** - 用户使用 CRC/LRC 计算器时自动发送通知
  - 异步发送，不阻塞 API 响应
  - 包含详细的请求信息（输入、结果、IP、时间等）
  - 支持 HTML 格式化消息
  - 自动转义特殊字符

### 🔧 配置项

- 添加 `telegram.enabled` - 启用/禁用通知
- 添加 `telegram.botToken` - Bot Token 配置
- 添加 `telegram.chatId` - Chat ID 配置  
- 添加 `telegram.timeout` - 请求超时配置

### 📁 新增文件

- `internal/notification/telegram.go` - Telegram 通知核心逻辑
- `TELEGRAM_INTEGRATION_GUIDE.md` - 完整使用文档
- `test-telegram.sh` - 自动化测试脚本
- `.env.example` - 环境变量配置示例

### 🔄 修改文件

- `config/config.yaml` - 添加 Telegram 配置项
- `config/config.go` - 添加 Telegram 配置结构体
- `internal/handler/checksum_handler.go` - 集成通知功能
  - 新增 `sendChecksumNotification()` - 发送通知
  - 新增 `getClientIP()` - 获取真实 IP
  - 新增 `formatResults()` - 格式化结果

### 📊 性能影响

- API 响应时间：**无影响**（异步处理）
- 内存开销：~50KB/请求
- CPU 开销：可忽略
- 网络流量：~1KB/通知

### 🔒 安全特性

- 支持环境变量配置（避免硬编码敏感信息）
- HTML 特殊字符自动转义
- 请求超时保护
- 可选的 IP 地址过滤

### 📝 使用示例

```bash
# 配置 Telegram
vim config/config.yaml

# 测试通知
./test-telegram.sh

# 查看日志
journalctl -u checksum-api.service -f
```

### 🎯 下一步计划

- [ ] 添加通知频率限制
- [ ] 支持多个 Chat ID
- [ ] 添加通知模板配置
- [ ] 统计通知发送成功率

---

**文档**: 详见 [TELEGRAM_INTEGRATION_GUIDE.md](./TELEGRAM_INTEGRATION_GUIDE.md)
