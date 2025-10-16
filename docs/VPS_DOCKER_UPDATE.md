# 🚀 VPS Docker 版本更新指南

## 📋 概述

本指南适用于在 VPS 上使用 Docker 部署的 CRC_LRC 项目，教您如何安全地拉取最新代码并更新运行中的服务。

---

## ⚡ 快速更新（3 步）

### 方法一：自动更新脚本（推荐）

```bash
# SSH 登录到 VPS
ssh user@your-vps-ip

# 进入项目目录
cd /path/to/CRC_LRC

# 运行更新脚本
./scripts/update-docker.sh
```

### 方法二：手动更新

```bash
# 1. SSH 登录
ssh user@your-vps-ip

# 2. 进入项目目录
cd /path/to/CRC_LRC

# 3. 拉取最新代码
git pull origin main  # 或 git pull origin DEV

# 4. 重新构建并启动
docker-compose down
docker-compose up -d --build

# 5. 查看日志确认
docker-compose logs -f
```

---

## 🔧 详细更新步骤

### 步骤 1: 备份当前配置

**重要：** 更新前先备份配置文件！

```bash
# 备份配置和数据
cd /path/to/CRC_LRC
cp config/config.yaml config/config.yaml.backup
cp .env .env.backup

# 或使用备份脚本
./scripts/backup.sh
```

### 步骤 2: 拉取最新代码

```bash
# 查看当前状态
git status

# 如果有本地修改，暂存它们
git stash save "本地配置"

# 拉取最新代码
git fetch origin
git pull origin main  # 或你的分支名

# 恢复本地配置
git stash pop
```

### 步骤 3: 更新配置文件

检查是否有新的配置项：

```bash
# 对比配置文件
diff config/config.yaml config/config.yaml.backup

# 如果有新配置项，手动添加
nano config/config.yaml
```

**示例：添加 Telegram 配置**

```yaml
# 在 config.yaml 中添加（如果还没有）
telegram:
  enabled: true
  botToken: "YOUR_BOT_TOKEN_HERE"
  chatId: "YOUR_CHAT_ID_HERE"
  timeout: 5s
```

### 步骤 4: 重新构建 Docker 镜像

```bash
# 停止当前容器
docker-compose down

# 清理旧镜像（可选，节省空间）
docker image prune -f

# 重新构建并启动
docker-compose up -d --build

# --build 参数会强制重新构建镜像
```

### 步骤 5: 验证更新

```bash
# 查看容器状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 测试 API
curl http://localhost:8080/api/checksum?input=test

# 如果配置了 Telegram，测试通知
./scripts/test-telegram.sh
```

---

## 🛡️ 安全更新流程

### 零停机更新（生产环境）

```bash
# 1. 拉取最新代码
git pull origin main

# 2. 构建新镜像（不停止旧容器）
docker-compose build

# 3. 滚动更新
docker-compose up -d --no-deps --build checksum-api

# 4. 验证新容器
docker-compose logs -f checksum-api

# 5. 如果有问题，回滚
docker-compose down
git checkout HEAD~1
docker-compose up -d --build
```

### 回滚到上一版本

```bash
# 查看提交历史
git log --oneline -10

# 回滚到指定版本
git checkout <commit-hash>

# 重新构建
docker-compose down
docker-compose up -d --build

# 或回到最新版本
git checkout main
```

---

## 📊 更新检查清单

### 更新前检查

- [ ] 已备份 `config/config.yaml`
- [ ] 已备份 `.env` 文件
- [ ] 已记录当前 Git 版本：`git rev-parse HEAD`
- [ ] 已通知用户（如果是公共服务）

### 更新中检查

- [ ] Git 拉取成功
- [ ] 没有配置冲突
- [ ] Docker 构建成功
- [ ] 容器启动成功

### 更新后检查

- [ ] API 响应正常
- [ ] 日志无错误
- [ ] Telegram 通知正常（如果启用）
- [ ] Nginx 代理正常
- [ ] 性能无异常

---

## 🔄 自动更新脚本

创建自动更新脚本 `scripts/update-docker.sh`：

```bash
#!/bin/bash
# VPS Docker 自动更新脚本

set -e  # 遇到错误立即退出

echo "🚀 开始更新 CRC_LRC Docker 服务..."
echo "================================"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 项目目录
PROJECT_DIR="/path/to/CRC_LRC"  # 修改为你的实际路径
cd "$PROJECT_DIR"

# 1. 备份配置
echo -e "${YELLOW}步骤 1: 备份配置...${NC}"
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp config/config.yaml "$BACKUP_DIR/" 2>/dev/null || true
cp .env "$BACKUP_DIR/" 2>/dev/null || true
echo -e "${GREEN}✓ 配置已备份到 $BACKUP_DIR${NC}"

# 2. 记录当前版本
CURRENT_VERSION=$(git rev-parse HEAD)
echo -e "${YELLOW}步骤 2: 当前版本: $CURRENT_VERSION${NC}"

# 3. 暂存本地修改
echo -e "${YELLOW}步骤 3: 检查本地修改...${NC}"
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}发现本地修改，暂存中...${NC}"
    git stash save "自动更新前备份 $(date)"
fi

# 4. 拉取最新代码
echo -e "${YELLOW}步骤 4: 拉取最新代码...${NC}"
git fetch origin
git pull origin main || {
    echo -e "${RED}✗ Git 拉取失败！${NC}"
    exit 1
}
NEW_VERSION=$(git rev-parse HEAD)
echo -e "${GREEN}✓ 更新到版本: $NEW_VERSION${NC}"

# 5. 恢复本地修改
if git stash list | grep -q "自动更新前备份"; then
    echo -e "${YELLOW}步骤 5: 恢复本地配置...${NC}"
    git stash pop || true
fi

# 6. 停止旧容器
echo -e "${YELLOW}步骤 6: 停止旧容器...${NC}"
docker-compose down
echo -e "${GREEN}✓ 容器已停止${NC}"

# 7. 清理旧镜像
echo -e "${YELLOW}步骤 7: 清理旧镜像...${NC}"
docker image prune -f
echo -e "${GREEN}✓ 旧镜像已清理${NC}"

# 8. 重新构建
echo -e "${YELLOW}步骤 8: 重新构建镜像...${NC}"
docker-compose build --no-cache || {
    echo -e "${RED}✗ 构建失败！回滚...${NC}"
    git checkout "$CURRENT_VERSION"
    docker-compose up -d
    exit 1
}
echo -e "${GREEN}✓ 镜像构建成功${NC}"

# 9. 启动新容器
echo -e "${YELLOW}步骤 9: 启动新容器...${NC}"
docker-compose up -d || {
    echo -e "${RED}✗ 启动失败！回滚...${NC}"
    git checkout "$CURRENT_VERSION"
    docker-compose build
    docker-compose up -d
    exit 1
}
echo -e "${GREEN}✓ 容器已启动${NC}"

# 10. 等待服务就绪
echo -e "${YELLOW}步骤 10: 等待服务就绪...${NC}"
sleep 5

# 11. 健康检查
echo -e "${YELLOW}步骤 11: 健康检查...${NC}"
if curl -f http://localhost:8080/api/checksum?input=test > /dev/null 2>&1; then
    echo -e "${GREEN}✓ API 响应正常${NC}"
else
    echo -e "${RED}✗ API 无响应！请检查日志${NC}"
    docker-compose logs --tail=50
    exit 1
fi

# 12. 显示日志
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✓ 更新完成！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "版本变化: $CURRENT_VERSION -> $NEW_VERSION"
echo "备份位置: $BACKUP_DIR"
echo ""
echo "查看日志: docker-compose logs -f"
echo "查看状态: docker-compose ps"
echo ""
```

**使用方法：**

```bash
# 1. 创建脚本
nano scripts/update-docker.sh
# 粘贴上面的内容

# 2. 修改项目路径
# 将 PROJECT_DIR="/path/to/CRC_LRC" 改为实际路径

# 3. 添加执行权限
chmod +x scripts/update-docker.sh

# 4. 运行更新
./scripts/update-docker.sh
```

---

## 🔍 故障排查

### 问题 1: Git 拉取冲突

```bash
# 解决方案 1: 强制覆盖本地修改
git fetch origin
git reset --hard origin/main

# 解决方案 2: 保留本地修改
git stash
git pull origin main
git stash pop
# 手动解决冲突
```

### 问题 2: Docker 构建失败

```bash
# 查看详细错误
docker-compose build --no-cache

# 清理所有 Docker 缓存
docker system prune -a -f
docker-compose build --no-cache

# 检查磁盘空间
df -h
```

### 问题 3: 容器无法启动

```bash
# 查看日志
docker-compose logs checksum-api

# 检查端口占用
sudo netstat -tlnp | grep 8080

# 检查配置文件
docker-compose config

# 重新启动
docker-compose down
docker-compose up -d
```

### 问题 4: API 无响应

```bash
# 检查容器状态
docker-compose ps

# 进入容器检查
docker-compose exec checksum-api sh
# 在容器内测试
wget -O- http://localhost:8080/api/checksum?input=test

# 检查 Nginx 代理（如果使用）
sudo nginx -t
sudo systemctl status nginx
```

---

## 📅 定期维护

### 每周检查

```bash
# 检查是否有新版本
cd /path/to/CRC_LRC
git fetch origin
git log HEAD..origin/main --oneline

# 查看 Docker 资源使用
docker stats --no-stream

# 清理日志
docker-compose logs --tail=0
```

### 每月维护

```bash
# 清理 Docker 系统
docker system prune -a -f

# 检查磁盘空间
df -h

# 备份配置
./scripts/backup.sh

# 检查安全更新
./scripts/check-sensitive-info.sh
```

---

## 🚦 环境变量更新

如果添加了新的环境变量（如 Telegram 配置）：

### 方法一：修改 .env 文件

```bash
# 编辑 .env
nano .env

# 添加新变量
TELEGRAM_BOT_TOKEN=your_token
TELEGRAM_CHAT_ID=your_chat_id

# 重启容器使其生效
docker-compose down
docker-compose up -d
```

### 方法二：使用 docker-compose.yml

```yaml
# docker-compose.yml
services:
  checksum-api:
    environment:
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
      - TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID}
```

```bash
# 重启应用配置
docker-compose up -d --force-recreate
```

---

## 📊 监控更新

### 设置更新通知

```bash
# 创建 cron 任务检查更新
crontab -e

# 添加（每天检查一次）
0 2 * * * cd /path/to/CRC_LRC && git fetch origin && git log HEAD..origin/main --oneline | mail -s "CRC_LRC 有新更新" your@email.com
```

### Telegram 通知更新

在 `update-docker.sh` 末尾添加：

```bash
# 发送 Telegram 通知
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "{
    \"chat_id\": \"${TELEGRAM_CHAT_ID}\",
    \"text\": \"✅ CRC_LRC 已更新\n\n版本: $CURRENT_VERSION -> $NEW_VERSION\n时间: $(date)\",
    \"parse_mode\": \"HTML\"
  }"
```

---

## 📋 更新记录模板

创建更新日志：

```bash
# /path/to/CRC_LRC/logs/update.log
echo "[$(date)] 更新: $CURRENT_VERSION -> $NEW_VERSION" >> logs/update.log
```

---

## 🎯 最佳实践

1. **总是备份** - 更新前备份配置
2. **测试环境** - 先在测试环境验证
3. **监控日志** - 更新后持续监控
4. **记录版本** - 保存每次更新的版本号
5. **准备回滚** - 知道如何快速回滚
6. **通知用户** - 如果是公共服务，提前通知

---

## 🔗 相关文档

- [DEPLOYMENT.md](../DEPLOYMENT.md) - 完整部署指南
- [SECURITY.md](./SECURITY.md) - 安全配置
- [TELEGRAM_README.md](./TELEGRAM_README.md) - Telegram 配置

---

## 📞 获取帮助

遇到问题？

1. 查看 [故障排查](#-故障排查) 部分
2. 检查 [Issues](https://github.com/KaikiDeishuuu/CRC_LRC/issues)
3. 提交新 [Issue](https://github.com/KaikiDeishuuu/CRC_LRC/issues/new)

---

**更新愉快！** 🚀
