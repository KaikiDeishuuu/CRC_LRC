# CRC/LRC 校验计算器

一个功能强大的校验值计算工具，提供 RESTful API 和 Web 界面，支持多种常用校验算法。

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

### 方式三：Docker + Nginx + HTTPS（VPS 部署）

详见 [DEPLOYMENT.md](./DEPLOYMENT.md) 完整部署文档。

**快速步骤**：

```bash
# 1. 构建并启动容器
docker-compose up -d --build

# 2. 配置 Nginx 反向代理
sudo cp nginx.conf /etc/nginx/sites-available/checksum-api
sudo ln -s /etc/nginx/sites-available/checksum-api /etc/nginx/sites-enabled/

# 3. 修改域名并测试
sudo nano /etc/nginx/sites-available/checksum-api
sudo nginx -t
sudo systemctl reload nginx

# 4. 配置 SSL（Let's Encrypt）
sudo certbot --nginx -d your-domain.com
```

访问：`https://your-domain.com`

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

欢迎提交 Issue 和 Pull Request！

### 添加新算法

1. 在 `internal/calculator/types.go` 添加常量
2. 在 `internal/calculator/calculator.go` 实现算法
3. 更新 handler 返回结果
4. 添加测试用例

## 📄 许可

MIT License

## 🔗 相关资源

- [MODBUS 协议规范](https://modbus.org)
- [CRC 算法详解](https://en.wikipedia.org/wiki/Cyclic_redundancy_check)
- [Gorilla Mux 文档](https://github.com/gorilla/mux)

---

**项目路径**: `/home/GoProjects/WebAPI/CRC_LRC`  
**API 版本**: v1.1.0  
**更新日期**: 2025-10-14
