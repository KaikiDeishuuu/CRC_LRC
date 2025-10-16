# 傻瓜式安装/更新指南

## 🚀 一键安装/更新脚本

我们提供了一个完全自动化的脚本，**无需任何技术背景**即可完成部署！

### 📋 脚本功能

✅ **自动检测环境** - 检查 Docker 和 Docker Compose 是否安装  
✅ **交互式配置** - 在命令行中输入 Telegram 凭据  
✅ **智能备份** - 更新前自动备份现有配置  
✅ **配置保留** - 检测到已有配置时可选择保留  
✅ **删除旧版本** - 清理旧 Docker 镜像，使用全新版本  
✅ **健康检查** - 启动后自动测试 API 是否正常  
✅ **Telegram 测试** - 可选择测试 Telegram 连接  
✅ **错误回滚** - 如果失败会提供详细错误信息

---

## 📦 使用方法

### 首次安装

```bash
# 1. 克隆项目（如果还没有）
git clone https://github.com/KaikiDeishuuu/CRC_LRC.git
cd CRC_LRC

# 2. 运行安装脚本
./scripts/install-or-update.sh
```

### 更新已有部署

```bash
# 1. 进入项目目录
cd CRC_LRC

# 2. 拉取最新代码
git pull origin main

# 3. 运行安装脚本（会自动备份并更新）
./scripts/install-or-update.sh
```

---

## 🎯 脚本执行流程

### 步骤 1/8: 检测环境

- 检查 Docker 是否安装
- 检查 Docker Compose 是否安装
- 判断是首次安装还是更新

### 步骤 2/8: 备份配置

- 如果是更新，自动备份 `config.yaml` 和 `.env`
- 备份位置：`backups/YYYYMMDD_HHMMSS/`

### 步骤 3/8: Telegram 配置（可选）

**首次安装时：**

```
是否配置 Telegram 通知？(y/N) y

如何获取 Telegram 凭据：
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📱 获取 Bot Token:
  1. 在 Telegram 搜索 @BotFather
  2. 发送 /newbot 并按提示创建机器人
  3. 复制 Token（格式：123456789:ABC...）

📱 获取 Chat ID:
  1. 在 Telegram 搜索 @userinfobot
  2. 发送 /start
  3. 复制你的 ID（纯数字）

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

请输入 Telegram Bot Token: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz
请输入 Telegram Chat ID: 987654321

是否测试 Telegram 连接？(Y/n) y
✓ Telegram 连接测试成功！请查看手机
```

**更新时检测到已有配置：**

```
检测到已有 Telegram 配置：
  Bot Token: 123456789:ABCdefGH...wxyz
  Chat ID: 987654321

是否保留现有配置？(Y/n) y
✓ 将使用现有 Telegram 配置
```

### 步骤 4/8: 生成配置文件

- 生成 `.env` 文件（包含 Telegram 凭据）
- 更新 `config/config.yaml`

### 步骤 5/8: 停止旧容器

- 自动检测并停止运行中的容器

### 步骤 6/8: 清理旧镜像

```
是否清理旧的 Docker 镜像？(节省空间) (y/N) y
✓ 旧镜像已清理
```

### 步骤 7/8: 构建并启动新容器

- 使用 `--no-cache` 强制重新构建（确保使用最新代码）
- 后台启动容器

### 步骤 8/8: 健康检查

- 自动测试 API 是否可访问
- 如果失败会显示日志

---

## ✅ 安装完成后

脚本会显示：

```
╔════════════════════════════════════════════╗
║                                            ║
║    ✓ 安装/更新完成！                      ║
║                                            ║
╚════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
访问信息
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌐 本地访问:
   http://localhost:8080

🔌 API 端点:
   http://localhost:8080/api/checksum?input=Hello

🌍 公网访问（如果开放了端口）:
   http://YOUR_IP:8080

📱 Telegram 通知: 已启用

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
常用命令
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

查看日志:
  docker-compose logs -f

查看状态:
  docker-compose ps

停止服务:
  docker-compose down

重启服务:
  docker-compose restart

更新服务:
  ./scripts/update-docker.sh

测试 API:
  curl http://localhost:8080/api/checksum?input=test

测试 Telegram:
  ./scripts/test-telegram.sh
```

---

## 🎨 脚本特性

### 1. 智能配置保留

- **首次安装**：交互式输入所有配置
- **更新部署**：检测到已有配置时可选择保留
- **重新配置**：也可以选择重新输入新的配置

### 2. 格式验证

脚本会验证输入格式：

- **Bot Token**：应该是 `数字:字母数字` 格式
- **Chat ID**：应该是纯数字（可能带负号）

如果格式不对会提示警告，但仍可选择继续。

### 3. 连接测试

配置 Telegram 后可以选择立即测试：

```bash
是否测试 Telegram 连接？(Y/n) y
正在测试连接...
✓ Telegram 连接测试成功！请查看手机
```

如果测试失败会显示错误信息，并询问是否继续安装。

### 4. 自动备份

每次更新都会备份配置文件到：

```
backups/20251017_143025/
  ├── config.yaml
  └── .env
```

如果新版本有问题，可以从备份恢复。

### 5. 完全清理旧版本

选择清理旧镜像时，会：

```bash
# 清理未使用的镜像
docker image prune -f

# 删除旧的 CRC_LRC 镜像
docker rmi -f <old_image_id>
```

然后使用 `--no-cache` 重新构建，确保使用全新代码。

---

## 🔧 前置条件

### 必需安装

1. **Docker**

   ```bash
   curl -fsSL https://get.docker.com | sh
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

2. **Docker Compose**
   ```bash
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

### 可选配置

3. **Telegram Bot**（用于接收通知）
   - 在 Telegram 搜索 `@BotFather` 创建机器人
   - 在 Telegram 搜索 `@userinfobot` 获取你的 Chat ID

---

## 🐛 常见问题

### 问：如果不想配置 Telegram 怎么办？

答：直接选择 `N`（不配置），脚本会跳过 Telegram 配置，不影响其他功能。

```bash
是否配置 Telegram 通知？(y/N) n
跳过 Telegram 配置（可稍后配置）
```

### 问：配置错了怎么办？

答：重新运行脚本，选择不保留现有配置，重新输入即可。

```bash
是否保留现有配置？(Y/n) n
# 然后重新输入正确的配置
```

### 问：如何稍后配置 Telegram？

答：手动编辑 `.env` 文件：

```bash
nano .env
```

修改：

```env
TELEGRAM_BOT_TOKEN=YOUR_ACTUAL_TOKEN
TELEGRAM_CHAT_ID=YOUR_ACTUAL_CHAT_ID
```

然后重启：

```bash
docker-compose restart
```

### 问：如何验证安装成功？

答：运行测试命令：

```bash
# 测试 API
curl http://localhost:8080/api/checksum?input=test

# 测试 Telegram（如果已配置）
./scripts/test-telegram.sh
```

### 问：健康检查失败怎么办？

答：脚本会自动显示日志，也可以手动查看：

```bash
docker-compose logs -f
```

常见原因：

- 端口 8080 被占用
- 配置文件格式错误
- Docker 资源不足

### 问：如何卸载？

答：运行清理命令：

```bash
# 停止并删除容器
docker-compose down

# 删除镜像
docker rmi crc_lrc:latest

# 删除项目文件
cd ..
rm -rf CRC_LRC
```

---

## 📝 配置文件说明

### .env（敏感信息，不要提交到 Git）

```env
# Telegram 配置
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_CHAT_ID=987654321
```

### config/config.yaml

```yaml
telegram:
  enabled: true # 是否启用 Telegram 通知
  botToken: "YOUR_BOT_TOKEN_HERE" # Bot Token（会被 .env 覆盖）
  chatId: "YOUR_CHAT_ID_HERE" # Chat ID（会被 .env 覆盖）
```

**优先级**：`.env` > `config.yaml`

---

## 🎓 VPS 部署示例

### 完整流程

```bash
# 1. SSH 连接到 VPS
ssh user@your-vps-ip

# 2. 安装 Docker（如果未安装）
curl -fsSL https://get.docker.com | sh
sudo systemctl start docker
sudo systemctl enable docker

# 3. 安装 Docker Compose（如果未安装）
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 4. 克隆项目
git clone https://github.com/KaikiDeishuuu/CRC_LRC.git
cd CRC_LRC

# 5. 运行安装脚本
./scripts/install-or-update.sh

# 6. 按提示配置 Telegram（可选）

# 7. 测试访问
curl http://localhost:8080/api/checksum?input=test
```

### 后续更新

```bash
# 1. SSH 连接到 VPS
ssh user@your-vps-ip

# 2. 进入项目目录
cd CRC_LRC

# 3. 拉取最新代码
git pull origin main

# 4. 运行更新脚本（会自动备份配置）
./scripts/install-or-update.sh

# 5. 选择保留现有配置
是否保留现有配置？(Y/n) y

# 6. 选择清理旧镜像
是否清理旧的 Docker 镜像？(y/N) y

# 7. 等待自动完成
```

---

## 🔐 安全提示

⚠️ **重要**：

1. **.env 文件包含敏感信息**，不要提交到公开仓库
2. **备份目录可能包含配置**，注意保护
3. **定期更新 Bot Token**，避免泄露
4. **使用防火墙**限制 8080 端口访问（如需公网访问）

---

## 🎉 总结

这个脚本让部署变得**极其简单**：

1. ✅ 无需手动编辑配置文件
2. ✅ 无需记忆复杂的 Docker 命令
3. ✅ 自动处理更新和备份
4. ✅ 一键完成从安装到测试的全流程

**一行命令搞定一切**：

```bash
./scripts/install-or-update.sh
```

祝使用愉快！🚀
