# CRC/LRC 校验计算器

<div align="center">

![Version](https://img.shields.io/badge/version-1.2.0-blue.svg)
![Go Version](https://img.shields.io/badge/Go-1.21+-00ADD8?logo=go)
![License](https://img.shields.io/badge/license-GPL--3.0-green.svg)
![Docker](https://img.shields.io/badge/docker-ready-brightgreen?logo=docker)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Windows%20%7C%20macOS-lightgrey)

一个功能强大的校验值计算工具，提供 RESTful API 和 Web 界面，支持多种常用校验算法。

[🚀 快速开始](#-快速开始) •
[📖 文档](#-文档) •
[🐳 Docker 部署](#-docker-部署) •
[🤝 贡献](#-贡献) •
[📄 许可证](#-许可证)

</div>

---

## ✨ 特性

- 🎯 **多算法支持**: CRC16 MODBUS、CRC16 CCITT、CRC32 IEEE、SUM8、LRC
- 🚀 **一次调用多种结果**: 单次请求返回所有算法的校验值
- 📋 **智能复制**: 自动复制完整数据（输入 + 校验值），无需手动拼接
- 🔧 **双输入模式**: 支持文本和 HEX 两种输入方式
- 🌐 **内置 Web 界面**: 美观的前端界面，开箱即用
- 🔌 **API 友好**: RESTful 设计，易于集成到任何项目
- ⚡ **高性能**: 无状态设计，支持高并发，响应时间 < 10ms

## 🚀 快速开始

### 方式一：直接运行（开发环境）

```bash
cd /home/GoProjects/WebAPI/CRC_LRC
go run .
```

### 方式二：Docker 部署（生产环境推荐）

```bash
# 一键部署
./deploy.sh deploy

# 或手动部署
docker-compose up -d --build
```

### 方式三：Docker + Nginx + HTTPS（VPS 部署推荐）

详见 [DEPLOYMENT.md](./DEPLOYMENT.md) 完整部署文档。

**一键部署脚本**：

```bash
# 1. 克隆项目
git clone https://github.com/KaikiDeishuuu/CRC_LRC.git
cd CRC_LRC

# 2. 完整部署（构建前端 + Docker）
./deploy.sh deploy

# 3. 配置防火墙（关闭 8080 对外访问）
sudo ./block-8080.sh

# 4. 配置 Nginx 反向代理（可选）
sudo ./install-nginx-config.sh
```

**管理命令**：

```bash
./deploy.sh deploy    # 完整部署
./deploy.sh stop      # 停止服务
./deploy.sh logs      # 查看日志
./restart.sh          # 快速重启
./clean-docker.sh     # 清理空间
./debug-docker.sh     # 调试问题
```

访问：`https://your-domain.com`

**安全架构**：

```
外部用户 → HTTPS (443) → Nginx 反向代理 → localhost:8080 → Docker 容器
                                                     ↑
                                            防火墙拒绝外部直接访问
```

### 访问界面

浏览器打开: http://localhost:8080 或 https://your-domain.com

### API 调用示例

```bash
curl -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"Hello","method":"text"}'
```

**响应**:

```json
{
  "crc": "14C4",
  "crc16_ccitt": "9DD6",
  "crc32": "F7D18982",
  "sum8": "FC"
}
```

## 📖 文档

- **完整 API 文档**: [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)
- **Docker 部署文档**: [DEPLOYMENT.md](./DEPLOYMENT.md) ⭐ 新增
- **复制功能说明**: [COPY_FEATURE.md](./COPY_FEATURE.md)

## 🎯 使用场景

### 1. MODBUS RTU 通信

```bash
# 计算完整 MODBUS 帧
输入: 01 03 00 00 00 0A
输出: 01 03 00 00 00 0A C4 09
```

### 2. 串口数据校验

```bash
# 发送带校验的数据包
输入: 01 02 03 04
复制: 01 02 03 04 B448  # 一键复制完整帧
```

### 3. 博客/文档集成

在 React/Next.js 项目中嵌入交互式计算器：

```tsx
<ChecksumWidget apiUrl="http://localhost:8080" />
```

## 🛠️ 支持的算法

| 算法             | 描述          | 应用场景                |
| ---------------- | ------------- | ----------------------- |
| **CRC16 MODBUS** | 多项式 0xA001 | 工业自动化、MODBUS 协议 |
| **CRC16 CCITT**  | 多项式 0x1021 | 电信通讯                |
| **CRC32 IEEE**   | 32 位 CRC     | 网络传输、文件校验      |
| **SUM8**         | 8 位累加和    | 简单校验                |
| **LRC**          | 纵向冗余校验  | 串口通讯                |

## 📋 复制功能

### 完整数据复制

点击"复制"按钮时，自动复制**输入数据 + 校验值**：

**HEX 模式**:

```
输入: 01 02 03 04
CRC16: B448
复制: 01 02 03 04 B448  ✨ 完整帧
```

**文本模式**:

```
输入: Hello
CRC16: 14C4
复制: 48 65 6C 6C 6F 14C4  ✨ 自动转 HEX
```

### 三重降级机制

1. ✅ Clipboard API (现代浏览器)
2. ✅ execCommand (兼容旧浏览器)
3. ✅ 手动复制提示 (最终降级)

## 🔧 配置

编辑 `config/config.yaml`:

```yaml
server:
  port: 8080
  host: localhost

limits:
  max_input_size: 10485760 # 10MB
```

## 📦 项目结构

```
WebAPI/CRC_LRC/
├── main.go                    # 入口文件
├── handler.go                 # HTTP 处理器
├── config/
│   ├── config.go             # 配置管理
│   └── config.yaml           # 配置文件
├── internal/
│   ├── calculator/           # 校验算法实现
│   │   ├── calculator.go
│   │   └── types.go
│   ├── handler/              # API 处理器
│   │   ├── checksum_handler.go
│   │   ├── file_handler.go
│   │   └── home_handler.go
│   └── router/               # 路由配置
│       └── router.go
├── frontend/                 # 前端源码
│   └── src/
│       └── app.ts           # TypeScript 应用
└── web/                     # 编译后的前端资源
    └── index.html
```

## 🧪 测试

### 标准测试向量

| 输入        | CRC16 MODBUS | CRC16 CCITT | CRC32 IEEE |
| ----------- | ------------ | ----------- | ---------- |
| "123456789" | 4B37         | 31C3        | CBF43926   |
| "Hello"     | 14C4         | 9DD6        | F7D18982   |
| "ABCDEFGH"  | E688         | 9738        | 3FD0F7E5   |

### 运行测试

```bash
# API 测试
./test_api.sh

# 单元测试
go test ./...
```

## 🌐 CORS 配置

如需跨域访问，在 `internal/router/router.go` 中启用 CORS：

```go
r.Use(corsMiddleware)
```

支持的源可在配置文件中设置。

## 📚 API 端点

| 端点            | 方法 | 描述             |
| --------------- | ---- | ---------------- |
| `/api/checksum` | POST | 综合校验（推荐） |
| `/api/lrc`      | POST | LRC 校验         |
| `/api/crc`      | POST | 兼容旧版本       |
| `/`             | GET  | Web 界面         |

详细文档: [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)

## 🎨 前端集成

### JavaScript 示例

```javascript
async function calculate(data, method = "text") {
  const res = await fetch("http://localhost:8080/api/checksum", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ data, method }),
  });
  return await res.json();
}
```

### React 组件

参考 [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) 中的完整示例。

## 📊 性能

- 小数据（< 1KB）: **< 5ms**
- 中等数据（1-100KB）: **< 50ms**
- 最大输入: **10MB**（可配置）

## ⚙️ 技术栈

**后端**:

- Go 1.x
- Gorilla Mux (路由)
- YAML 配置

**前端**:

- TypeScript 5.2
- Vite 4.5
- Tailwind CSS 3.3

## � Docker 部署

### 快速部署命令

```bash
# 使用部署脚本（推荐）
./deploy.sh deploy

# 或手动部署
docker-compose up -d --build

# 查看状态
./deploy.sh status

# 查看日志
./deploy.sh logs
```

### 架构说明

```
互联网 (HTTPS 443)
    ↓
Nginx (反向代理 + SSL)
    ↓
localhost:8080 (端口映射)
    ↓
Docker 容器
    ↓
Go 应用 (监听 8080)
```

### 主要文件

- `Dockerfile` - 多阶段构建配置
- `docker-compose.yml` - 容器编排配置
- `nginx.conf` - Nginx 反向代理配置
- `deploy.sh` - 一键部署脚本
- `DEPLOYMENT.md` - 详细部署文档

详细部署说明请参考 [DEPLOYMENT.md](./DEPLOYMENT.md)

---

## �📝 更新日志

### v1.2.0 (2025-10-14)

- 🐳 **新增**: Docker 支持（Dockerfile + docker-compose）
- 🚀 **新增**: Nginx 反向代理配置
- 📝 **新增**: 完整部署文档（DEPLOYMENT.md）
- 🛠️ **新增**: 一键部署脚本（deploy.sh）
- 🔒 **新增**: HTTPS/SSL 配置示例

### v1.1.0 (2025-10-14)

- ✨ 新增完整数据复制功能
- ✨ 三重降级复制机制
- 📝 更新 API 文档
- 🎨 优化前端界面

### v1.0.0 (2025-10-14)

- 🎉 初始版本发布
- ✅ 5 种校验算法
- ✅ RESTful API
- ✅ Web 界面

## 🤝 贡献

欢迎所有形式的贡献！无论是报告 Bug、提出新功能建议、改进文档，还是提交代码。

### 快速开始

1. **Fork 本仓库**
2. **创建特性分支** (`git checkout -b feature/AmazingFeature`)
3. **提交更改** (`git commit -m 'feat: add some amazing feature'`)
4. **推送到分支** (`git push origin feature/AmazingFeature`)
5. **提交 Pull Request**

### 详细指南

请阅读 [CONTRIBUTING.md](./CONTRIBUTING.md) 了解：

- 开发环境设置
- 代码规范和风格
- 提交消息规范
- Pull Request 流程
- 如何添加新算法

### 添加新算法

1. 在 `internal/calculator/types.go` 添加算法常量
2. 在 `internal/calculator/calculator.go` 实现算法函数
3. 更新 `internal/handler/` 中的 handler 返回新算法结果
4. 在 `API_DOCUMENTATION.md` 中添加文档
5. 添加测试用例并运行 `go test ./...`
6. 更新前端 `frontend/src/app.ts` 显示新算法

### 代码规范

- Go 代码遵循 `gofmt` 标准格式
- TypeScript 代码使用 ESLint 规则
- 提交信息遵循 [Conventional Commits](https://www.conventionalcommits.org/)
- 为新功能添加测试

### 报告 Bug

请使用 [GitHub Issues](https://github.com/KaikiDeishuuu/CRC_LRC/issues) 报告 Bug，并包含：

- 操作系统和版本
- Go 版本
- 重现步骤
- 期望行为
- 实际行为
- 错误日志（如有）

### 功能请求

欢迎提出新功能建议！请在 Issue 中详细描述：

- 功能描述
- 使用场景
- 期望的 API/界面设计
- 是否愿意贡献代码实现

---

## 📄 许可证

本项目采用 **GNU General Public License v3.0** 许可证。

这意味着您可以：

- ✅ **自由使用** - 将本软件用于任何目的
- ✅ **自由研究** - 学习程序工作原理并根据需求修改
- ✅ **自由分发** - 重新分发副本
- ✅ **自由改进** - 改进程序并向公众发布改进版本

但必须遵守以下条款：

- 📋 **开源要求** - 修改后的版本也必须以 GPL-3.0 许可发布
- 📝 **声明修改** - 必须标注对原作品的修改
- 🔗 **保留许可** - 必须保留原始许可证和版权声明
- 💼 **无担保** - 软件按"原样"提供，不提供任何明示或暗示的担保

详细信息请查看 [LICENSE](./LICENSE) 文件。

### 为什么选择 GPL-3.0？

我们选择 GPL-3.0 许可证是为了：

1. 保证软件始终保持开源和自由
2. 确保所有改进都能回馈社区
3. 防止专有软件闭源使用
4. 保护用户的自由权利

### 第三方许可

本项目使用的开源库：

- [Gorilla Mux](https://github.com/gorilla/mux) - BSD-3-Clause License
- [Viper](https://github.com/spf13/viper) - MIT License
- [Vite](https://github.com/vitejs/vite) - MIT License
- [Tailwind CSS](https://github.com/tailwindlabs/tailwindcss) - MIT License

### 商业使用

如需在专有/闭源软件中使用本项目，请联系作者讨论商业许可选项。

## �‍💻 作者

**KaikiDeishuuu**

- GitHub: [@KaikiDeishuuu](https://github.com/KaikiDeishuuu)
- Repository: [CRC_LRC](https://github.com/KaikiDeishuuu/CRC_LRC)

## 🌟 Star 历史

如果这个项目对你有帮助，请给个 ⭐ Star 支持一下！

## �🔗 相关资源

### 技术文档

- [MODBUS 协议规范](https://modbus.org)
- [CRC 算法详解](https://en.wikipedia.org/wiki/Cyclic_redundancy_check)
- [RFC 1071 - Computing the Internet Checksum](https://tools.ietf.org/html/rfc1071)

### 开源项目

- [Gorilla Mux](https://github.com/gorilla/mux) - HTTP 路由器
- [Vite](https://vitejs.dev/) - 前端构建工具
- [Tailwind CSS](https://tailwindcss.com/) - CSS 框架

### 相关工具

- [CRC RevEng](https://reveng.sourceforge.io/) - CRC 参数查找工具
- [Online CRC Calculator](https://crccalc.com/) - 在线 CRC 计算器

## 💬 社区与支持

- **问题反馈**: [GitHub Issues](https://github.com/KaikiDeishuuu/CRC_LRC/issues)
- **功能建议**: [GitHub Discussions](https://github.com/KaikiDeishuuu/CRC_LRC/discussions)
- **安全问题**: 请私下联系维护者

## 🙏 致谢

感谢所有为本项目做出贡献的开发者！

特别感谢以下开源项目：

- Go 编程语言团队
- Gorilla Web Toolkit 团队
- Vite 和 Tailwind CSS 社区

## 📈 项目统计

![GitHub stars](https://img.shields.io/github/stars/KaikiDeishuuu/CRC_LRC?style=social)
![GitHub forks](https://img.shields.io/github/forks/KaikiDeishuuu/CRC_LRC?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/KaikiDeishuuu/CRC_LRC?style=social)

---

<div align="center">

**项目路径**: `/home/GoProjects/WebAPI/CRC_LRC`  
**当前版本**: v1.2.0  
**更新日期**: 2025-10-14

Made with ❤️ by [KaikiDeishuuu](https://github.com/KaikiDeishuuu)

如果这个项目对你有帮助，请考虑给个 ⭐ Star！

[⬆ 回到顶部](#crc-lrc-校验计算器)

</div>
