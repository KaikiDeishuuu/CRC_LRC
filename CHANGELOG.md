# 更新日志

本项目的所有重要变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [未发布]

### 计划中的功能

- [ ] 支持更多校验算法（CRC64、Fletcher-16 等）
- [ ] 批量文件校验
- [ ] 国际化支持（英文）
- [ ] WebSocket 实时计算
- [ ] 计算历史记录

---

## [1.3.1] - 2025-10-14

### 修复

- 🔧 **Nginx 配置兼容性**
  - 移除对 nginx-extras 模块的依赖
  - 使用标准 Nginx 指令替代 `more_clear_headers`
  - 添加 `fix-nginx-config.sh` 自动修复脚本
  - 更新 `setup-api-protection.sh` 使用兼容配置

### 改进

- 📖 使用 `server_tokens off` 隐藏 Nginx 版本
- 📖 使用 `proxy_hide_header` 替代 `more_clear_headers`
- 📖 配置文件注释说明可选的 headers-more 模块

---

## [1.3.0] - 2025-10-14

### 新增 - 安全防护 ⭐

- 🛡️ **API 防护工具**
  - 添加 `setup-api-protection.sh` 一键配置防护
  - 添加 `monitor-api.sh` 安全监控脚本
  - 添加 `block-ip.sh` 快速封禁恶意 IP
  - 添加 `unblock-ip.sh` IP 解封工具
  - 添加 `block-8080.sh` 端口防火墙配置
  - 添加 `cleanup-8080-rules.sh` 防火墙规则清理
- 🔒 **安全特性**
  - Nginx 速率限制（防 DDoS）
  - 连接数限制
  - 请求体大小限制
  - Fail2ban 自动封禁
  - IP 黑名单功能
  - 防火墙规则自动配置
- 📝 **安全文档**
  - 添加 SECURITY.md 完整安全指南
  - 详细的防护配置说明
  - 监控和应急响应流程

### 改进

- 📖 更新 DEPLOYMENT.md
  - 添加防火墙配置章节
  - 添加管理脚本说明
  - 完善安全加固指南
- 📖 更新 README.md
  - 添加安全架构图
  - 简化文档索引
- 🧹 **文档整理**
  - 删除冗余文档（COPY_SOLUTION.md, QUICKSTART.md 等）
  - 合并重复内容
  - 优化文档结构

### 安全

- 🔐 Docker 端口绑定到 127.0.0.1（只允许本地访问）
- 🔐 iptables 规则防止 8080 端口对外暴露
- 🔐 Nginx 安全响应头配置
- 🔐 自动化安全配置工具

---

## [1.2.0] - 2025-10-14

### 新增

- 🐳 **Docker 支持**
  - 添加 Dockerfile 多阶段构建配置
  - 添加 docker-compose.yml 容器编排
  - 添加 .dockerignore 优化镜像大小
- 🌐 **Nginx 配置**
  - 添加 nginx.conf 反向代理配置
  - 支持 HTTPS/SSL (Let's Encrypt)
  - 添加 nginx-docker.conf 容器内 Nginx 配置
- 🛠️ **自动化工具**
  - 添加 deploy.sh 一键部署脚本
  - 添加 test-api.sh API 测试脚本
  - 添加 Makefile 简化常用命令
- 📝 **文档完善**
  - 添加 DEPLOYMENT.md 完整部署指南
  - 添加 DOCKER_DEPLOYMENT_SUMMARY.md 部署总结
  - 添加 QUICKSTART.md 快速参考卡片
  - 添加 FILE_STRUCTURE.md 文件结构说明
  - 添加 CONTRIBUTING.md 贡献指南
  - 添加 CHANGELOG.md 更新日志
- ⚙️ **系统服务**
  - 添加 checksum-api.service Systemd 服务文件
- 📋 **GitHub 模板**
  - 添加 Bug 报告模板
  - 添加功能请求模板
  - 添加 Pull Request 模板
- 🔧 **配置文件**
  - 添加 .gitignore 文件

### 改进

- 📖 更新 README.md
  - 添加项目徽章
  - 添加 GPL-3.0 许可证说明
  - 完善贡献指南
  - 添加作者信息和致谢
- 📝 更新 API_DOCUMENTATION.md
  - 添加 Docker 部署说明
  - 完善 FAQ 章节

### 架构

- 生产环境部署架构：互联网 → Nginx (HTTPS) → Docker → Go 应用
- 支持三种部署方式：直接运行 / Docker / Docker + Nginx + HTTPS

---

## [1.1.0] - 2025-10-14

### 新增

- ✨ **完整数据复制功能**
  - 点击复制按钮自动复制输入数据 + 校验值
  - HEX 模式：格式化为空格分隔的 HEX + 校验值
  - 文本模式：自动转换为 HEX + 校验值
- 🔄 **三重降级复制机制**
  - 优先使用 Clipboard API (现代浏览器)
  - 降级到 execCommand (兼容旧浏览器)
  - 最终降级到手动复制提示对话框
- 📝 **文档更新**
  - 添加 COPY_FEATURE.md 复制功能详细说明
  - 更新 API_DOCUMENTATION.md 添加复制功能章节

### 改进

- 🎨 前端界面优化
  - 添加复制提示信息
  - 优化手动复制对话框显示
  - 改进用户体验

### 技术

- 前端新增 `stringToHex()` 辅助函数
- 前端新增 `currentInputDataForCopy` 全局变量
- 优化 `copyToClipboard()` 函数支持完整数据复制

---

## [1.0.0] - 2025-10-14

### 新增

- 🎉 **初始版本发布**
- 🎯 **多算法支持**
  - CRC16 MODBUS (多项式 0xA001，低字节在前)
  - CRC16 CCITT (多项式 0x1021，高字节在前)
  - CRC32 IEEE (32 位循环冗余校验)
  - SUM8 (8 位累加和)
  - LRC (纵向冗余校验，取反加 1)
- 🔌 **RESTful API**
  - POST `/api/checksum` - 综合校验（一次返回多种算法）
  - POST `/api/lrc` - LRC 校验
  - POST `/api/crc` - 兼容旧版本
  - GET `/` - Web 界面
- 🔧 **双输入模式**
  - 文本输入模式
  - HEX 输入模式（支持空格分隔）
- 🌐 **Web 界面**
  - TypeScript + Vite + Tailwind CSS
  - 响应式设计
  - 实时计算
  - 结果展示
- 📋 **复制功能**
  - 一键复制校验值
  - 支持所有算法
- ⚡ **高性能**
  - 无状态设计
  - 响应时间 < 10ms
  - 支持高并发
- 📝 **完整文档**
  - README.md 项目说明
  - API_DOCUMENTATION.md API 文档
  - 代码注释

### 技术栈

- **后端**: Go 1.x + Gorilla Mux + YAML 配置
- **前端**: TypeScript 5.2 + Vite 4.5 + Tailwind CSS 3.3
- **部署**: 支持直接运行

### 测试

- 标准测试向量验证
- 支持单元测试

---

## 版本说明

### 语义化版本格式

- **主版本号 (MAJOR)**: 不兼容的 API 变更
- **次版本号 (MINOR)**: 向下兼容的功能新增
- **修订号 (PATCH)**: 向下兼容的 Bug 修复

### 变更类型

- `新增` (Added) - 新功能
- `改进` (Changed) - 现有功能的变更
- `废弃` (Deprecated) - 即将移除的功能
- `移除` (Removed) - 已移除的功能
- `修复` (Fixed) - Bug 修复
- `安全` (Security) - 安全性相关修复

---

## 链接

- [未发布]: https://github.com/KaikiDeishuuu/CRC_LRC/compare/v1.2.0...HEAD
- [1.2.0]: https://github.com/KaikiDeishuuu/CRC_LRC/compare/v1.1.0...v1.2.0
- [1.1.0]: https://github.com/KaikiDeishuuu/CRC_LRC/compare/v1.0.0...v1.1.0
- [1.0.0]: https://github.com/KaikiDeishuuu/CRC_LRC/releases/tag/v1.0.0
