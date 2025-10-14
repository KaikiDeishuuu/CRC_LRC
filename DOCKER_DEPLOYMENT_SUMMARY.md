# Docker + Nginx + HTTPS 部署总结

## ✅ 已完成的工作

### 📦 Docker 配置文件

1. **Dockerfile** - 多阶段构建

   - 前端构建阶段（Node.js）
   - Go 应用构建阶段
   - 最终运行镜像（Alpine Linux）
   - 包含健康检查

2. **docker-compose.yml** - 容器编排

   - 端口映射：8080:8080
   - 自动重启策略
   - 网络配置
   - 健康检查

3. **.dockerignore** - 优化镜像大小
   - 排除开发文件
   - 排除文档
   - 排除临时文件

### 🌐 Nginx 配置

1. **nginx.conf** - 宿主机 Nginx（推荐方案）

   - HTTP → HTTPS 自动重定向
   - SSL/TLS 配置
   - 反向代理到 localhost:8080
   - 安全头部
   - 静态资源缓存
   - API 路径特殊处理

2. **nginx-docker.conf** - 容器内 Nginx
   - 使用容器名进行代理
   - 适用于完全 Docker 化部署

### 🛠️ 自动化脚本

1. **deploy.sh** - 一键部署脚本

   - 构建前端
   - 构建镜像
   - 启动容器
   - 状态检查
   - 日志查看

2. **test-api.sh** - API 测试脚本

   - 10 个测试用例
   - 标准测试向量验证
   - 错误处理测试
   - 彩色输出

3. **Makefile** - Make 命令集合
   - 简化常用操作
   - 统一命令接口

### 📝 文档

1. **DEPLOYMENT.md** - 完整部署文档

   - 两种部署方案详解
   - 详细步骤说明
   - 故障排查指南
   - 安全加固建议
   - CI/CD 示例

2. **QUICKSTART.md** - 快速参考卡片

   - 命令速查表
   - 配置文件速查
   - 常见问题速查
   - 端口说明

3. **checksum-api.service** - Systemd 服务文件
   - 用于非 Docker 部署
   - 自动启动配置

---

## 🚀 你的部署方案

### 架构图

```
┌─────────────────────────────────────────────────────────┐
│                        互联网                           │
└───────────────────────┬─────────────────────────────────┘
                        │ HTTPS (443)
                        ↓
┌─────────────────────────────────────────────────────────┐
│                    VPS 宿主机                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │              Nginx (宿主机)                       │  │
│  │  - SSL 终止 (Let's Encrypt)                      │  │
│  │  - 反向代理                                       │  │
│  │  - 安全头部                                       │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 │ HTTP (localhost:8080)                 │
│                 ↓                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │           Docker 容器                             │  │
│  │  ┌────────────────────────────────────────────┐  │  │
│  │  │     Go 应用 (checksum-api)                │  │  │
│  │  │     - 监听 0.0.0.0:8080                   │  │  │
│  │  │     - 前端资源 (/web)                     │  │  │
│  │  │     - API 端点 (/api/*)                   │  │  │
│  │  └────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 工作流程

1. **用户访问** `https://your-domain.com`
2. **Nginx 接收**请求（443 端口）
3. **SSL 终止**：Nginx 解密 HTTPS 流量
4. **反向代理**：转发到 `localhost:8080`
5. **Docker 容器**：处理请求
6. **返回响应**：Docker → Nginx → 用户

---

## 📋 部署清单（照着做就行）

### 第一步：准备 VPS

```bash
# 1. 更新系统
sudo apt update && sudo apt upgrade -y

# 2. 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 3. 安装 Docker Compose
sudo apt install docker-compose -y

# 4. 安装 Nginx
sudo apt install nginx -y

# 5. 安装 Certbot
sudo apt install certbot python3-certbot-nginx -y

# 6. 配置防火墙
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw deny 8080/tcp  # 不对外暴露
sudo ufw enable
```

### 第二步：上传项目

```bash
# 在 VPS 上
mkdir -p /home/GoProjects
cd /home/GoProjects

# 克隆或上传项目
git clone <your-repo> CRC_LRC
# 或使用 scp 上传

cd CRC_LRC
```

### 第三步：构建并启动 Docker

```bash
# 给脚本添加执行权限
chmod +x deploy.sh test-api.sh

# 构建前端（首次需要）
cd frontend
yarn install
yarn build
cd ..

# 一键部署
./deploy.sh deploy

# 验证容器运行
docker ps
```

### 第四步：配置 Nginx

```bash
# 1. 复制配置文件
sudo cp nginx.conf /etc/nginx/sites-available/checksum-api

# 2. 编辑配置，修改域名
sudo nano /etc/nginx/sites-available/checksum-api
# 将所有 "your-domain.com" 改为你的实际域名

# 3. 创建软链接
sudo ln -s /etc/nginx/sites-available/checksum-api /etc/nginx/sites-enabled/

# 4. 删除默认配置（可选）
sudo rm /etc/nginx/sites-enabled/default

# 5. 测试配置
sudo nginx -t

# 6. 重载 Nginx
sudo systemctl reload nginx
```

### 第五步：配置 SSL（Let's Encrypt）

```bash
# 1. 确保域名已解析到 VPS IP

# 2. 申请证书
sudo certbot --nginx -d your-domain.com

# 按提示操作：
# - 输入邮箱
# - 同意服务条款
# - 选择是否重定向 HTTP 到 HTTPS（推荐选择 2）

# 3. 测试自动续期
sudo certbot renew --dry-run

# 证书会自动配置到 Nginx
```

### 第六步：验证部署

```bash
# 1. 测试本地 API
curl http://localhost:8080/

# 2. 测试 HTTPS 访问
curl https://your-domain.com/

# 3. 测试 API 端点
curl -X POST https://your-domain.com/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"Hello","method":"text"}'

# 4. 使用测试脚本
API_URL=https://your-domain.com ./test-api.sh

# 5. 浏览器访问
# 打开 https://your-domain.com
```

---

## 🎉 成功标志

如果看到以下结果，说明部署成功：

### 1. Docker 容器运行正常

```bash
$ docker ps
CONTAINER ID   IMAGE              STATUS         PORTS
abc123...      checksum-api:latest   Up 5 minutes   0.0.0.0:8080->8080/tcp
```

### 2. 本地 API 响应

```bash
$ curl http://localhost:8080/
<!DOCTYPE html>
<html>...（前端页面）
```

### 3. HTTPS 访问正常

```bash
$ curl https://your-domain.com/
<!DOCTYPE html>
<html>...（前端页面）
```

### 4. API 测试通过

```bash
$ curl -X POST https://your-domain.com/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"Hello","method":"text"}'

{"crc":"14C4","crc16_ccitt":"9DD6","crc32":"F7D18982","sum8":"FC"}
```

### 5. SSL 证书有效

浏览器访问 `https://your-domain.com`，地址栏显示 🔒 锁图标

---

## 🔧 日常维护

### 更新代码

```bash
cd /home/GoProjects/CRC_LRC
git pull
./deploy.sh update
```

### 查看日志

```bash
# Docker 日志
./deploy.sh logs

# Nginx 日志
sudo tail -f /var/log/nginx/checksum-api-access.log
sudo tail -f /var/log/nginx/checksum-api-error.log
```

### 重启服务

```bash
# 重启 Docker 容器
./deploy.sh restart

# 重启 Nginx
sudo systemctl restart nginx
```

### 查看状态

```bash
# Docker 状态
./deploy.sh status

# Nginx 状态
sudo systemctl status nginx

# SSL 证书状态
sudo certbot certificates
```

---

## 🚨 故障排查速查

### 问题：502 Bad Gateway

```bash
# 1. 检查 Docker 容器是否运行
docker ps

# 2. 如果没运行，启动它
./deploy.sh start

# 3. 查看容器日志
docker logs checksum-api
```

### 问题：无法访问 HTTPS

```bash
# 1. 检查防火墙
sudo ufw status

# 2. 检查 Nginx
sudo systemctl status nginx
sudo nginx -t

# 3. 检查证书
sudo certbot certificates
```

### 问题：容器无法启动

```bash
# 1. 查看详细日志
docker-compose logs

# 2. 检查端口占用
sudo netstat -tulpn | grep 8080

# 3. 重新构建
docker-compose build --no-cache
docker-compose up -d
```

---

## 📞 需要帮助？

1. 查看详细文档：[DEPLOYMENT.md](./DEPLOYMENT.md)
2. 快速参考：[QUICKSTART.md](./QUICKSTART.md)
3. API 文档：[API_DOCUMENTATION.md](./API_DOCUMENTATION.md)

---

## ✨ 总结

你的部署方案完全可行且推荐！核心优势：

✅ **隔离性好**：应用在 Docker 容器中，与宿主机隔离  
✅ **易维护**：一键部署、更新、重启  
✅ **安全性高**：Nginx 处理 SSL，8080 端口不对外暴露  
✅ **性能好**：Nginx 高效反向代理，静态资源缓存  
✅ **可扩展**：可轻松添加负载均衡、多实例

**现在就可以开始部署了！** 🚀

按照上面的"部署清单"一步步执行即可。
