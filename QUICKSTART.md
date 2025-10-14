# 快速部署参考卡片

## 🚀 部署方案对比

| 方案               | 适用场景  | 复杂度 | HTTPS | 性能     |
| ------------------ | --------- | ------ | ----- | -------- |
| **直接运行**       | 开发/测试 | ⭐     | ❌    | ⭐⭐⭐   |
| **Docker**         | 单机部署  | ⭐⭐   | ❌    | ⭐⭐⭐   |
| **Docker + Nginx** | 生产环境  | ⭐⭐⭐ | ✅    | ⭐⭐⭐⭐ |

---

## 📋 方案一：Docker + 宿主机 Nginx（推荐）

### 架构

```
Internet → Nginx (VPS:443) → Docker (localhost:8080) → App
```

### 快速步骤

```bash
# 1. 启动 Docker 容器
cd /home/GoProjects/WebAPI/CRC_LRC
./deploy.sh deploy

# 2. 配置 Nginx
sudo cp nginx.conf /etc/nginx/sites-available/checksum-api
sudo ln -s /etc/nginx/sites-available/checksum-api /etc/nginx/sites-enabled/
sudo nano /etc/nginx/sites-available/checksum-api  # 修改域名

# 3. 配置 SSL
sudo certbot --nginx -d your-domain.com

# 4. 重载 Nginx
sudo nginx -t && sudo systemctl reload nginx
```

### 访问

- 🌐 Web: `https://your-domain.com`
- 🔌 API: `https://your-domain.com/api/checksum`

---

## 📋 方案二：完全 Docker 化（Nginx 也在容器）

### 使用场景

- 需要完全隔离
- 多服务编排
- 跨平台一致性

### 步骤

```bash
# 1. 使用 docker-compose-full.yml
docker-compose -f docker-compose-full.yml up -d --build

# 2. 配置 SSL 证书挂载
# 编辑 docker-compose-full.yml，确保证书路径正确

# 3. 修改 nginx-docker.conf 中的域名

# 4. 重启容器
docker-compose -f docker-compose-full.yml restart nginx
```

---

## 🔑 核心命令速查

### Docker 操作

```bash
# 部署
./deploy.sh deploy          # 完整部署
./deploy.sh update          # 快速更新
./deploy.sh status          # 检查状态
./deploy.sh logs            # 查看日志
./deploy.sh stop            # 停止服务

# 或使用 Makefile
make deploy                 # 完整部署
make docker-logs            # 查看日志
make docker-down            # 停止服务
```

### Nginx 操作

```bash
sudo nginx -t               # 测试配置
sudo systemctl reload nginx # 重载配置
sudo systemctl status nginx # 查看状态
```

### SSL 证书

```bash
sudo certbot --nginx -d your-domain.com        # 申请证书
sudo certbot renew                             # 更新证书
sudo certbot certificates                      # 查看证书
```

---

## 🧪 测试验证

### 本地测试

```bash
# 方式1: 使用测试脚本
./test-api.sh

# 方式2: 手动测试
curl http://localhost:8080/
curl -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"Hello","method":"text"}'
```

### 生产环境测试

```bash
# HTTPS 测试
curl https://your-domain.com/

# API 测试
curl -X POST https://your-domain.com/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"Hello","method":"text"}'
```

### 期望结果

```json
{
  "crc": "14C4",
  "crc16_ccitt": "9DD6",
  "crc32": "F7D18982",
  "sum8": "FC"
}
```

---

## 🔧 配置文件速查

### 必须修改的配置

#### nginx.conf

```nginx
# 第9行和第26行
server_name your-domain.com;  # 改为你的域名

# 第29-30行
ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
```

#### config/config.yaml

```yaml
server:
  port: 8080 # 容器内端口，通常不需要改
  host: 0.0.0.0 # Docker 中必须是 0.0.0.0
```

#### docker-compose.yml

```yaml
ports:
  - "8080:8080" # 宿主机:容器 端口映射
```

---

## 🚨 常见问题速查

### 1. 502 Bad Gateway

```bash
# 检查容器是否运行
docker ps

# 检查容器日志
docker logs checksum-api

# 检查 Nginx 配置
sudo nginx -t
```

### 2. 无法访问 HTTPS

```bash
# 检查防火墙
sudo ufw status
sudo ufw allow 443/tcp

# 检查 SSL 证书
sudo certbot certificates

# 查看 Nginx 错误日志
sudo tail -f /var/log/nginx/error.log
```

### 3. CORS 错误

在 `internal/router/router.go` 中确保已启用 CORS：

```go
r.Use(corsMiddleware)
```

### 4. 容器无法启动

```bash
# 查看详细日志
docker-compose logs checksum-api

# 重新构建
docker-compose build --no-cache
docker-compose up -d
```

---

## 📊 端口说明

| 端口 | 用途               | 是否暴露        |
| ---- | ------------------ | --------------- |
| 8080 | 应用端口（容器内） | ✅ 映射到宿主机 |
| 8080 | 应用端口（宿主机） | ❌ 仅 localhost |
| 80   | HTTP（Nginx）      | ✅ 重定向到 443 |
| 443  | HTTPS（Nginx）     | ✅ 对外服务     |

### 防火墙配置

```bash
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw deny 8080/tcp   # 不对外暴露应用端口
```

---

## 🔄 更新流程

### 代码更新

```bash
# 1. 拉取代码
git pull

# 2. 重新构建前端
cd frontend && yarn build && cd ..

# 3. 重启容器
./deploy.sh update

# 或手动
docker-compose up -d --build
```

### 配置更新

```bash
# 1. 修改配置文件
nano config/config.yaml

# 2. 重启容器
docker-compose restart
```

### Nginx 配置更新

```bash
# 1. 修改配置
sudo nano /etc/nginx/sites-available/checksum-api

# 2. 测试配置
sudo nginx -t

# 3. 重载 Nginx
sudo systemctl reload nginx
```

---

## 📦 文件清单

### 部署相关文件

```
├── Dockerfile              # Docker 镜像构建
├── docker-compose.yml      # 容器编排（推荐）
├── nginx.conf             # Nginx 配置（宿主机）
├── nginx-docker.conf      # Nginx 配置（容器内）
├── deploy.sh              # 一键部署脚本
├── test-api.sh            # API 测试脚本
├── Makefile               # Make 命令集合
├── checksum-api.service   # Systemd 服务文件
├── .dockerignore          # Docker 忽略文件
└── DEPLOYMENT.md          # 详细部署文档
```

---

## 🎯 性能优化提示

### Docker

```yaml
# docker-compose.yml 中添加资源限制
deploy:
  resources:
    limits:
      cpus: "0.5"
      memory: 256M
```

### Nginx

```nginx
# 启用缓存
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m;

# 启用 Gzip
gzip on;
gzip_types text/plain application/json;
```

---

## 📚 相关文档

- 📖 [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) - API 详细文档
- 🚀 [DEPLOYMENT.md](./DEPLOYMENT.md) - 完整部署指南
- 📋 [COPY_FEATURE.md](./COPY_FEATURE.md) - 复制功能说明
- 📝 [README.md](./README.md) - 项目总览

---

**版本**: v1.2.0  
**更新日期**: 2025-10-14
