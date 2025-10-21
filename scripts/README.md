# Scripts Directory

本目录包含项目的各类脚本，按功能分类组织。

## 📁 目录结构

### 🚀 deployment/

部署和安装相关脚本

- `fresh-install-vps.sh` - VPS 全新安装脚本
- `quick-rebuild.sh` - 快速重建和测试脚本
- `rebuild-and-test.sh` - 重建并测试服务
- `commit-changes.sh` - Git 提交辅助脚本
- `deploy.sh` - 生产环境部署脚本
- `install-or-update.sh` - 安装或更新脚本
- `update-docker.sh` - Docker 更新脚本
- `install-nginx-config.sh` - Nginx 配置安装
- `fix-nginx-config.sh` - Nginx 配置修复
- `setup-api-protection.sh` - API 保护设置
- `pre-commit-hook.sh` - Git 预提交钩子
- `debug-docker.sh` - Docker 调试工具

### 🧪 testing/

测试和诊断脚本

- `diagnose-telegram.sh` - Telegram 通知诊断工具（完整版）
- `test-telegram.sh` - Telegram 通知快速测试
- `vps-test-telegram.sh` - VPS 上的 Telegram 测试
- `test-api.sh` - API 功能测试
- `test-install-script.sh` - 安装脚本测试
- `check-telegram-setup.sh` - Telegram 配置检查
- `check-sensitive-info.sh` - 敏感信息检查

### 🔧 maintenance/

维护和安全脚本

- `monitor-api.sh` - API 监控脚本
- `restart.sh` - 服务重启脚本
- `clean-docker.sh` - Docker 清理工具
- `block-8080.sh` - 端口 8080 封禁
- `block-ip.sh` - IP 封禁工具
- `unblock-ip.sh` - IP 解封工具
- `cleanup-8080-rules.sh` - 清理 8080 规则

## 🗄️ 已归档脚本

- 所有已归档的脚本都移动到 `scripts/archive/`，按子目录（deployment/testing/maintenance）分类存放。
- 如果需要恢复某个脚本：

```bash
# 将脚本从 archive 恢复到位于相应的目录中
mv scripts/archive/deployment/quick-rebuild.sh scripts/deployment/quick-rebuild.sh
chmod +x scripts/deployment/quick-rebuild.sh
```

## 🎯 常用命令

### 快速部署

```bash
# VPS 全新安装
./scripts/deployment/fresh-install-vps.sh

# 快速重建测试
./scripts/deployment/quick-rebuild.sh

# 常规部署
./scripts/deployment/deploy.sh
```

### 测试诊断

```bash
# Telegram 完整诊断
./scripts/testing/diagnose-telegram.sh

# 快速测试 API
./scripts/testing/test-api.sh

# 快速测试 Telegram
./scripts/testing/test-telegram.sh
```

### 维护操作

```bash
# 监控服务
./scripts/maintenance/monitor-api.sh

# 重启服务
./scripts/maintenance/restart.sh

# 清理 Docker
./scripts/maintenance/clean-docker.sh
```

## 📝 脚本使用说明

所有脚本都需要执行权限，如果遇到权限问题：

```bash
chmod +x scripts/**/*.sh
```

大部分脚本都有详细的输出说明，直接运行即可查看帮助信息。
