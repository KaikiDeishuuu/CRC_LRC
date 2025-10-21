# 🚀 快速开始

一键安装/更新 CRC_LRC 项目，自动配置 Telegram 通知！

## 📦 一键安装

```bash
# 克隆项目
git clone https://github.com/KaikiDeishuuu/CRC_LRC.git
cd CRC_LRC

# 运行安装脚本
./scripts/install-or-update.sh
```

## 🔄 一键更新

```bash
cd CRC_LRC
git pull origin main
./scripts/install-or-update.sh
```

## ✨ 脚本功能

- ✅ 自动检测环境（Docker、Docker Compose）
- ✅ 交互式配置 Telegram（Bot Token、Chat ID）
- ✅ 智能保留现有配置
- ✅ 自动备份旧配置
- ✅ 删除旧版本，构建新版本
- ✅ 健康检查和测试
- ✅ 错误自动提示

## 📱 Telegram 配置

### 获取 Bot Token

1. 在 Telegram 搜索 `@BotFather`
2. 发送 `/newbot` 创建机器人
3. 复制 Token（格式：`123456789:ABCdef...`）

### 获取 Chat ID

1. 在 Telegram 搜索 `@userinfobot`
2. 发送 `/start`
3. 复制你的 ID（纯数字）

## 🎯 使用流程

```
运行脚本
    ↓
检测环境 ← Docker、Docker Compose
    ↓
备份配置 ← 自动备份到 backups/
    ↓
配置 Telegram ← 交互式输入或保留现有
    ↓
生成配置文件 ← .env、config.yaml
    ↓
停止旧容器 ← docker-compose down
    ↓
清理旧镜像 ← 可选，节省空间
    ↓
构建新容器 ← docker-compose build --no-cache
    ↓
启动服务 ← docker-compose up -d
    ↓
健康检查 ← 自动测试 API
    ↓
完成！
```

## 🛠️ 常用命令

```bash
# 查看日志
docker-compose logs -f

# 查看状态
docker-compose ps

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 测试 API
curl http://localhost:8080/api/checksum?input=test

# 测试 Telegram
./scripts/test-telegram.sh
```

## 📚 详细文档

- [完整安装指南](./EASY_INSTALL.md)
- [VPS Docker 更新指南](./VPS_DOCKER_UPDATE.md)
- [Telegram 配置指南](./TELEGRAM_QUICKSTART.md)
- [项目结构说明](../PROJECT_STRUCTURE.md)

## 💡 提示

- 首次安装时会引导输入 Telegram 配置
- 更新时会询问是否保留现有配置
- 配置错了？重新运行脚本即可
- 不想配置 Telegram？选择 `N` 跳过

## 🎉 就是这么简单！

一行命令，完成所有配置：

```bash
./scripts/install-or-update.sh
```
