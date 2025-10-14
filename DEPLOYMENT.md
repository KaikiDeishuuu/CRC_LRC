# Docker 部署文档

## 🚀 快速部署

### 前提条件

- Docker 已安装
- Docker Compose 已安装
- Nginx 已安装（在宿主机）
- 域名已解析到 VPS
- （可选）SSL 证书（Let's Encrypt）

---

## 📦 方案一：Docker + Nginx 反向代理（推荐）

### 架构图

```
互联网 (HTTPS 443)
    ↓
Nginx (宿主机，SSL 终止)
    ↓
localhost:8080 (端口映射)
    ↓
Docker 容器 (checksum-api)
    ↓
Go 应用 (监听 8080)
```

### 步骤 1: 构建并启动 Docker 容器

```bash
# 进入项目目录
cd /home/GoProjects/WebAPI/CRC_LRC

# 构建并启动容器
docker-compose up -d --build

# 查看容器状态
docker-compose ps

# 查看日志
docker-compose logs -f checksum-api
```

### 步骤 2: 验证容器运行

```bash
# 测试容器内的服务
curl http://localhost:8080/

# 测试 API
curl -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"Hello","method":"text"}'
```

### 步骤 3: 配置 Nginx

#### 3.1 复制 Nginx 配置文件

```bash
# 复制配置文件到 Nginx 目录
sudo cp nginx.conf /etc/nginx/sites-available/checksum-api

# 创建软链接
sudo ln -s /etc/nginx/sites-available/checksum-api /etc/nginx/sites-enabled/

# 或者直接复制到 conf.d（取决于你的 Nginx 配置）
sudo cp nginx.conf /etc/nginx/conf.d/checksum-api.conf
```

#### 3.2 修改配置文件

编辑 `/etc/nginx/sites-available/checksum-api`：

```bash
sudo nano /etc/nginx/sites-available/checksum-api
```

**必须修改的地方**：

1. `server_name your-domain.com;` → 改为你的域名
2. SSL 证书路径（如果已有证书）

#### 3.3 测试并重载 Nginx

```bash
# 测试配置
sudo nginx -t

# 重载配置
sudo systemctl reload nginx

# 或重启 Nginx
sudo systemctl restart nginx
```

### 步骤 4: 配置 SSL 证书（Let's Encrypt）

#### 使用 Certbot 自动获取证书

```bash
# 安装 Certbot（Ubuntu/Debian）
sudo apt update
sudo apt install certbot python3-certbot-nginx

# 自动配置 SSL
sudo certbot --nginx -d your-domain.com

# 测试自动续期
sudo certbot renew --dry-run
```

证书会自动安装到：

- `/etc/letsencrypt/live/your-domain.com/fullchain.pem`
- `/etc/letsencrypt/live/your-domain.com/privkey.pem`

### 步骤 5: 验证部署

```bash
# 测试 HTTPS 访问
curl https://your-domain.com/

# 测试 API
curl -X POST https://your-domain.com/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"Hello","method":"text"}'
```

在浏览器访问：

- `https://your-domain.com` → 前端界面
- `https://your-domain.com/api/checksum` → API 端点

---

## 🔧 Docker 常用命令

### 容器管理

```bash
# 启动容器
docker-compose up -d

# 停止容器
docker-compose down

# 重启容器
docker-compose restart

# 查看日志
docker-compose logs -f

# 进入容器
docker exec -it checksum-api sh
```

### 更新部署

```bash
# 拉取最新代码
git pull

# 重新构建前端
cd frontend && yarn build && cd ..

# 重新构建并启动容器
docker-compose up -d --build

# 清理旧镜像
docker image prune -f
```

### 资源监控

```bash
# 查看容器资源使用
docker stats checksum-api

# 查看容器详细信息
docker inspect checksum-api
```

---

## 🛠️ 方案二：完全 Docker 化（Nginx 也在容器内）

如果你想让 Nginx 也运行在 Docker 中：

### docker-compose-full.yml

```yaml
version: "3.8"

services:
  checksum-api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: checksum-api
    restart: unless-stopped
    expose:
      - "8080"
    networks:
      - app-network

  nginx:
    image: nginx:alpine
    container_name: nginx-proxy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
      - /var/www/certbot:/var/www/certbot:ro
    depends_on:
      - checksum-api
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

**修改 nginx.conf 中的代理地址**：

```nginx
proxy_pass http://checksum-api:8080;  # 使用容器名而非 localhost
```

**启动**：

```bash
docker-compose -f docker-compose-full.yml up -d --build
```

---

## 🔒 安全加固

### 1. 限制 Docker 容器权限

在 `docker-compose.yml` 中添加：

```yaml
services:
  checksum-api:
    # ... 其他配置 ...
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
```

### 2. Nginx 限流配置

在 `nginx.conf` 的 `http` 块中添加：

```nginx
# 限制请求速率
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

server {
    # ...
    location /api/ {
        limit_req zone=api_limit burst=20 nodelay;
        # ... 其他配置
    }
}
```

### 3. 防火墙配置

```bash
# 只开放必要端口
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw deny 8080/tcp  # 不对外暴露 8080
sudo ufw enable
```

---

## 📊 监控和日志

### 查看 Nginx 日志

```bash
# 访问日志
sudo tail -f /var/log/nginx/checksum-api-access.log

# 错误日志
sudo tail -f /var/log/nginx/checksum-api-error.log
```

### 查看 Docker 日志

```bash
# 实时查看
docker-compose logs -f checksum-api

# 查看最近 100 行
docker-compose logs --tail=100 checksum-api
```

### 日志轮转

创建 `/etc/logrotate.d/checksum-api`：

```bash
/var/log/nginx/checksum-api-*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
    endscript
}
```

---

## 🚨 故障排查

### 问题 1: 容器无法启动

```bash
# 查看详细错误
docker-compose logs checksum-api

# 检查端口占用
sudo netstat -tulpn | grep 8080

# 检查镜像构建
docker-compose build --no-cache
```

### 问题 2: Nginx 502 Bad Gateway

```bash
# 检查容器是否运行
docker ps

# 检查容器内服务
curl http://localhost:8080/

# 检查 Nginx 配置
sudo nginx -t

# 查看 SELinux 状态（CentOS/RHEL）
sestatus
sudo setsebool -P httpd_can_network_connect 1
```

### 问题 3: SSL 证书问题

```bash
# 测试证书
sudo certbot certificates

# 强制更新证书
sudo certbot renew --force-renewal

# 检查证书文件权限
ls -la /etc/letsencrypt/live/your-domain.com/
```

### 问题 4: CORS 错误

确保 Go 应用启用了 CORS。检查 `internal/router/router.go`：

```go
func corsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Access-Control-Allow-Origin", "*")
        w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
        w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

        if r.Method == "OPTIONS" {
            w.WriteHeader(http.StatusOK)
            return
        }

        next.ServeHTTP(w, r)
    })
}
```

---

## 🔄 CI/CD 自动部署（可选）

### GitHub Actions 示例

创建 `.github/workflows/deploy.yml`：

```yaml
name: Deploy to VPS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to VPS
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd /home/GoProjects/WebAPI/CRC_LRC
            git pull
            cd frontend && yarn install && yarn build && cd ..
            docker-compose up -d --build
            docker image prune -f
```

---

## 📝 配置清单

部署前检查：

- [ ] 修改 `nginx.conf` 中的域名
- [ ] 修改 SSL 证书路径
- [ ] 确保 Docker 和 Docker Compose 已安装
- [ ] 确保端口 80、443 未被占用
- [ ] 域名 DNS 已正确解析
- [ ] 防火墙规则已配置
- [ ] 前端已构建（`cd frontend && yarn build`）
- [ ] 测试本地容器运行正常

---

## 🎯 性能优化

### 1. 启用 Nginx 缓存

```nginx
http {
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m max_size=1g inactive=60m;

    server {
        location /api/ {
            proxy_cache api_cache;
            proxy_cache_valid 200 5m;
            add_header X-Cache-Status $upstream_cache_status;
        }
    }
}
```

### 2. 启用 Gzip 压缩

```nginx
http {
    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    gzip_min_length 1000;
}
```

### 3. 限制 Docker 资源

在 `docker-compose.yml` 中：

```yaml
services:
  checksum-api:
    deploy:
      resources:
        limits:
          cpus: "0.5"
          memory: 256M
        reservations:
          memory: 128M
```

---

## 📞 支持

如有问题，请检查：

1. Docker 日志: `docker-compose logs -f`
2. Nginx 日志: `/var/log/nginx/checksum-api-error.log`
3. 系统日志: `sudo journalctl -u nginx -f`

**项目地址**: `/home/GoProjects/WebAPI/CRC_LRC`
