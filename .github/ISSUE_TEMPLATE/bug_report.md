---
name: Bug 报告
about: 创建一个报告来帮助我们改进
title: "[BUG] "
labels: "bug"
assignees: ""
---

## 🐛 Bug 描述

简洁明了地描述这个 Bug 是什么。

## 📋 环境信息

- **操作系统**: [如 Ubuntu 22.04, Windows 11, macOS 14]
- **Go 版本**: [运行 `go version`]
- **项目版本**: [如 v1.2.0]
- **部署方式**: [直接运行 / Docker / Docker + Nginx]
- **浏览器** (如涉及前端): [如 Chrome 120]

## 🔄 重现步骤

详细描述重现 Bug 的步骤：

1. 启动服务 '...'
2. 发送请求 '...'
3. 观察结果 '...'
4. 看到错误

## ✅ 期望行为

清晰简洁地描述你期望发生什么。

## ❌ 实际行为

清晰简洁地描述实际发生了什么。

## 📸 截图或日志

如果适用，添加截图或日志来帮助解释你的问题。

```
# 粘贴错误日志或终端输出
```

## 🔍 附加信息

添加关于该问题的任何其他上下文。

### API 请求示例（如适用）

```bash
curl -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"test","method":"text"}'
```

### 预期响应

```json
{
  "crc": "XXXX"
}
```

### 实际响应

```json
{
  "error": "..."
}
```

## 💡 可能的解决方案

如果你有解决建议，请在此描述。
