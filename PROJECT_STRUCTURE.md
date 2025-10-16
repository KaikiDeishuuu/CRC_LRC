# 📁 项目结构说明

## 🗂️ 目录结构

```
CRC_LRC/
├── 📄 核心文件
│   ├── main.go                    # 程序入口
│   ├── handler.go                 # HTTP 处理器
│   ├── go.mod                     # Go 模块定义
│   ├── Dockerfile                 # Docker 构建文件
│   └── docker-compose.yml         # Docker 编排配置
│
├── ⚙️ config/                     # 配置目录
│   ├── config.yaml               # 主配置文件
│   └── config.go                 # 配置加载逻辑
│
├── 🔧 internal/                   # 内部包目录
│   ├── calculator/               # 校验算法实现
│   │   ├── calculator.go
│   │   └── types.go
│   ├── handler/                  # API 处理器
│   │   ├── api_handler.go
│   │   ├── checksum_handler.go
│   │   ├── file_handler.go
│   │   └── home_handler.go
│   ├── notification/             # 通知模块
│   │   └── telegram.go          # Telegram 通知
│   └── router/                   # 路由配置
│       └── router.go
│
├── 🌐 frontend/                   # 前端源码
│   ├── src/
│   │   ├── app.ts               # TypeScript 应用
│   │   └── styles/              # 样式文件
│   ├── package.json
│   ├── vite.config.ts
│   └── tailwind.config.js
│
├── 📦 web/                        # 编译后的前端资源
│   └── index.html
│
├── 📜 scripts/                    # 脚本工具目录 🆕
│   ├── deploy.sh                # 部署脚本
│   ├── update-docker.sh         # Docker 更新脚本 🆕
│   ├── restart.sh               # 重启服务
│   ├── test-telegram.sh         # Telegram 测试
│   ├── test-api.sh              # API 测试
│   ├── check-telegram-setup.sh  # Telegram 配置检查
│   ├── check-sensitive-info.sh  # 敏感信息检查
│   ├── pre-commit-hook.sh       # Git 提交钩子
│   ├── clean-docker.sh          # Docker 清理
│   ├── debug-docker.sh          # Docker 调试
│   ├── block-8080.sh            # 防火墙配置
│   ├── unblock-ip.sh            # IP 解封
│   ├── block-ip.sh              # IP 封禁
│   ├── cleanup-8080-rules.sh    # 清理防火墙规则
│   ├── setup-api-protection.sh  # API 保护设置
│   ├── monitor-api.sh           # API 监控
│   ├── install-nginx-config.sh  # Nginx 配置安装
│   └── fix-nginx-config.sh      # Nginx 配置修复
│
├── 📚 docs/                       # 文档目录 🆕
│   ├── TELEGRAM_README.md                      # Telegram 快速开始
│   ├── TELEGRAM_QUICKSTART.md                  # 5分钟配置指南
│   ├── TELEGRAM_INTEGRATION_GUIDE.md           # 完整集成文档
│   ├── TELEGRAM_IMPLEMENTATION_SUMMARY.md      # 技术实现细节
│   ├── TELEGRAM_CHANGELOG.md                   # 功能变更日志
│   ├── SECURITY.md                             # 安全配置指南
│   ├── SECURITY_NOTICE.md                      # 安全注意事项
│   ├── SECURITY_CHECKLIST.md                   # 安全检查清单
│   ├── VPS_DOCKER_UPDATE.md                    # VPS Docker 更新指南 🆕
│   ├── COMPLETE_IMPLEMENTATION_REPORT.md       # 完整实施报告
│   └── IMPLEMENTATION_DONE.md                  # 实施完成报告
│
├── 📖 根目录文档
│   ├── README.md                # 项目主文档
│   ├── API_DOCUMENTATION.md     # API 接口文档
│   ├── DEPLOYMENT.md            # 部署指南
│   ├── CHANGELOG.md             # 版本更新日志
│   ├── CONTRIBUTING.md          # 贡献指南
│   ├── COPY_FEATURE.md          # 复制功能说明
│   ├── LICENSE                  # 开源许可证
│   └── PROJECT_STRUCTURE.md     # 本文件
│
├── 🔧 Nginx 配置
│   ├── nginx.conf               # 主配置
│   ├── nginx-docker.conf        # Docker 专用
│   └── nginx-api-config.conf    # API 配置
│
├── 📋 其他配置
│   ├── .env.example             # 环境变量模板
│   ├── .gitignore               # Git 忽略规则
│   ├── Makefile                 # Make 构建脚本
│   └── checksum-api.service     # Systemd 服务配置
│
└── 📁 运行时目录
    ├── bin/                     # 编译产物
    ├── logs/                    # 日志文件（运行时创建）
    └── backups/                 # 备份文件（运行时创建）
```

---

## 📋 文件分类

### 🚀 快速开始必读

1. **README.md** - 项目概述和快速开始
2. **docs/TELEGRAM_README.md** - Telegram 功能快速配置
3. **DEPLOYMENT.md** - 部署指南
4. **docs/VPS_DOCKER_UPDATE.md** - VPS 更新指南

### 📖 详细文档

#### API 相关

- `API_DOCUMENTATION.md` - 完整 API 文档

#### Telegram 通知

- `docs/TELEGRAM_QUICKSTART.md` - 5 分钟配置
- `docs/TELEGRAM_INTEGRATION_GUIDE.md` - 完整指南
- `docs/TELEGRAM_IMPLEMENTATION_SUMMARY.md` - 技术细节
- `docs/TELEGRAM_CHANGELOG.md` - 变更记录

#### 安全相关

- `docs/SECURITY.md` - 安全配置
- `docs/SECURITY_NOTICE.md` - 安全注意事项
- `docs/SECURITY_CHECKLIST.md` - 安全检查清单

#### 开发相关

- `CONTRIBUTING.md` - 贡献指南
- `CHANGELOG.md` - 版本历史
- `COPY_FEATURE.md` - 功能说明

### 🔧 脚本工具

#### 部署和更新

- `scripts/deploy.sh` - 完整部署
- `scripts/update-docker.sh` - Docker 更新 ⭐
- `scripts/restart.sh` - 快速重启

#### 测试工具

- `scripts/test-telegram.sh` - Telegram 功能测试
- `scripts/test-api.sh` - API 接口测试
- `scripts/check-telegram-setup.sh` - 配置检查

#### 安全工具

- `scripts/check-sensitive-info.sh` - 敏感信息检查
- `scripts/pre-commit-hook.sh` - Git 提交保护
- `scripts/block-8080.sh` - 防火墙配置
- `scripts/block-ip.sh` - IP 封禁
- `scripts/unblock-ip.sh` - IP 解封

#### 维护工具

- `scripts/clean-docker.sh` - Docker 清理
- `scripts/debug-docker.sh` - Docker 调试
- `scripts/monitor-api.sh` - API 监控

#### Nginx 工具

- `scripts/install-nginx-config.sh` - 安装配置
- `scripts/fix-nginx-config.sh` - 修复配置

---

## 🎯 常用操作快速索引

### 首次部署

```bash
# 1. 阅读部署文档
cat DEPLOYMENT.md

# 2. 使用部署脚本
./scripts/deploy.sh deploy

# 3. 配置 Telegram（可选）
cat docs/TELEGRAM_README.md
cp .env.example .env
# 编辑 .env 填入真实值
```

### VPS Docker 更新

```bash
# 阅读更新指南
cat docs/VPS_DOCKER_UPDATE.md

# 运行更新脚本
./scripts/update-docker.sh
```

### 测试功能

```bash
# API 测试
./scripts/test-api.sh

# Telegram 测试
./scripts/test-telegram.sh

# 配置检查
./scripts/check-telegram-setup.sh
```

### 安全检查

```bash
# 检查敏感信息
./scripts/check-sensitive-info.sh

# 安装 Git hook
cp scripts/pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### 日常维护

```bash
# 重启服务
./scripts/restart.sh

# 查看日志
docker-compose logs -f

# 清理 Docker
./scripts/clean-docker.sh

# 监控 API
./scripts/monitor-api.sh
```

---

## 📂 目录说明

### `/config`

配置文件目录，包含应用程序的所有配置。

**重要文件：**

- `config.yaml` - 主配置文件（包含 Telegram 等配置）
- `config.go` - 配置加载逻辑

**注意：** 此目录包含敏感信息，不要将真实配置提交到公开仓库。

### `/internal`

内部包目录，遵循 Go 项目标准布局。

**子目录：**

- `calculator/` - 核心算法实现（CRC、LRC 等）
- `handler/` - HTTP 请求处理器
- `notification/` - 通知模块（Telegram 等）
- `router/` - 路由配置和中间件

### `/frontend`

前端源代码，使用 TypeScript + Vite。

**构建命令：**

```bash
cd frontend
npm install
npm run build  # 输出到 /web
```

### `/web`

编译后的前端静态资源，由服务器直接提供。

### `/scripts` 🆕

所有脚本工具的统一存放位置。

**优势：**

- 便于管理和查找
- 避免根目录混乱
- 统一的执行路径

### `/docs` 🆕

所有文档的统一存放位置。

**优势：**

- 文档集中管理
- 易于维护更新
- 清晰的文档结构

---

## 🔗 相关链接

- [项目主页](../README.md)
- [API 文档](../API_DOCUMENTATION.md)
- [部署指南](../DEPLOYMENT.md)
- [Telegram 快速开始](./TELEGRAM_README.md)
- [VPS 更新指南](./VPS_DOCKER_UPDATE.md)

---

## 📝 维护说明

### 添加新脚本

```bash
# 1. 创建脚本
nano scripts/new-script.sh

# 2. 添加执行权限
chmod +x scripts/new-script.sh

# 3. 更新本文档
```

### 添加新文档

```bash
# 1. 创建文档
nano docs/NEW_FEATURE.md

# 2. 更新 README.md 中的文档索引
# 3. 更新本文档
```

### 文件命名规范

**脚本文件：**

- 使用小写字母和连字符：`update-docker.sh`
- 功能清晰：`check-sensitive-info.sh`

**文档文件：**

- 使用大写字母和下划线：`VPS_DOCKER_UPDATE.md`
- 相关文档使用统一前缀：`TELEGRAM_*.md`、`SECURITY_*.md`

---

**最后更新：** 2025-10-17  
**版本：** v1.3.0
