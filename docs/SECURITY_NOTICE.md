# 🔒 安全注意事项

## ⚠️ 重要提醒

本项目是**公开仓库**，请**务必注意保护敏感信息**！

---

## 🚨 敏感信息清单

以下信息**绝对不能**提交到公开仓库：

### 1. Telegram 配置
- ❌ `TELEGRAM_BOT_TOKEN` - 机器人令牌
- ❌ `TELEGRAM_CHAT_ID` - 聊天 ID
- ❌ 任何包含真实 Token 的配置文件

### 2. 其他敏感信息
- ❌ API 密钥
- ❌ 数据库密码
- ❌ SSL 证书私钥
- ❌ 服务器 IP 地址（如果是生产环境）

---

## ✅ 正确的做法

### 方法 1：使用环境变量（推荐）

**步骤 1：** 创建本地配置文件

```bash
# 复制示例文件
cp .env.example .env

# 编辑并填入真实值
nano .env
```

**步骤 2：** 修改 `.env` 文件

```bash
TELEGRAM_BOT_TOKEN=你的真实Token
TELEGRAM_CHAT_ID=你的真实ChatID
```

**步骤 3：** 加载环境变量

```bash
# 临时加载（当前终端有效）
source .env

# 或者在启动脚本中自动加载
```

`.env` 文件已经在 `.gitignore` 中，不会被提交！

### 方法 2：使用 Git 忽略本地修改

如果你必须在 `config/config.yaml` 中存储敏感信息：

```bash
# 告诉 Git 忽略此文件的本地修改
git update-index --assume-unchanged config/config.yaml

# 如果需要恢复跟踪
git update-index --no-assume-unchanged config/config.yaml
```

**注意：** 这只是忽略本地修改，文件本身仍在仓库中。

### 方法 3：使用配置文件模板

仓库中只保存模板文件：

```bash
# 仓库中的文件（安全）
config/config.yaml.example  ← 包含占位符

# 本地使用的文件（不提交）
config/config.yaml          ← 包含真实值
```

在 `.gitignore` 中添加：

```gitignore
config/config.yaml
```

---

## 🔍 检查是否泄露

### 提交前检查

```bash
# 1. 查看将要提交的内容
git diff

# 2. 搜索敏感信息
git diff | grep -i "token\|chatid\|password\|secret"

# 3. 查看暂存区
git diff --staged
```

### 使用检查脚本

```bash
# 运行安全检查
./check-sensitive-info.sh
```

---

## 🚑 已经泄露了怎么办？

### 1. 立即撤销 Token

如果 Telegram Token 已经泄露：

1. 打开 Telegram，搜索 `@BotFather`
2. 发送 `/mybots`
3. 选择你的机器人
4. 点击 `API Token`
5. 点击 `Revoke current token` 撤销旧 Token
6. 获取新 Token 并更新配置

### 2. 清理 Git 历史

**警告：** 这会重写历史记录！

```bash
# 使用 git-filter-repo（推荐）
git filter-repo --invert-paths --path config/config.yaml

# 或使用 BFG Repo-Cleaner
bfg --delete-files config.yaml
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 强制推送（谨慎！）
git push origin --force --all
```

### 3. 通知相关方

如果是生产环境泄露：
- 通知团队成员
- 更换所有相关密钥
- 检查是否有未授权访问
- 记录事件并改进流程

---

## 📋 提交前检查清单

在每次 `git push` 之前，请确认：

- [ ] 已检查 `git diff` 输出
- [ ] 没有包含真实的 Token 或密钥
- [ ] 敏感文件在 `.gitignore` 中
- [ ] 配置文件使用占位符（如 `YOUR_TOKEN_HERE`）
- [ ] `.env` 文件未被跟踪
- [ ] 已运行 `./check-sensitive-info.sh`（如果有）

---

## 🛡️ 最佳实践

### 1. 开发环境

```bash
# 使用本地 .env 文件
cp .env.example .env
# 编辑 .env，填入真实值
# .env 已在 .gitignore 中，不会被提交
```

### 2. 生产环境

```bash
# 使用系统环境变量
export TELEGRAM_BOT_TOKEN="..."
export TELEGRAM_CHAT_ID="..."

# 或使用 systemd EnvironmentFile
[Service]
EnvironmentFile=/etc/checksum-api/.env
```

### 3. 团队协作

- 通过安全渠道分享敏感信息（如加密的密码管理器）
- 每个开发者使用独立的测试 Token
- 生产环境 Token 只有必要人员知道
- 定期轮换密钥

### 4. CI/CD

```yaml
# GitHub Actions 示例
env:
  TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
  TELEGRAM_CHAT_ID: ${{ secrets.TELEGRAM_CHAT_ID }}
```

使用 GitHub Secrets 存储敏感信息，不要硬编码！

---

## 📚 相关资源

- [GitHub - 移除敏感数据](https://docs.github.com/cn/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [OWASP - 密钥管理](https://cheatsheetseries.owasp.org/cheatsheets/Key_Management_Cheat_Sheet.html)
- [12-Factor App - 配置](https://12factor.net/config)

---

## 🔗 相关文档

- [Telegram 集成指南](./TELEGRAM_INTEGRATION_GUIDE.md)
- [快速入门](./TELEGRAM_QUICKSTART.md)
- [部署文档](./DEPLOYMENT.md)

---

**记住：一旦泄露到公开仓库，即使删除提交，信息也可能已被爬虫抓取。预防永远好于补救！**

🔒 **保护好你的密钥，保护好你的项目！**
