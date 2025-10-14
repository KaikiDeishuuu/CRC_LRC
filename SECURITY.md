# 安全配置指南

本文档描述了如何安全地部署 CRC/LRC 校验计算器到生产环境。

---

## 🔒 安全架构

### 推荐架构

```
互联网 (公网)
    ↓
HTTPS (443) - SSL 终止
    ↓
Nginx 反向代理 (宿主机)
    ↓
localhost:8080 - 防火墙保护
    ↓
Docker 容器 (checksum-api)
    ↓
Go 应用服务
```

### 安全层级

1. **SSL/TLS 加密** - 所有外部通信使用 HTTPS
2. **Nginx 反向代理** - 隐藏内部服务，提供额外保护
3. **防火墙规则** - 限制 8080 端口只能本地访问
4. **Docker 隔离** - 容器化运行，限制资源访问
5. **只读文件系统** - 容器文件系统只读（可选）

---

## 🛡️ 防火墙配置

### 使用自动化脚本（推荐）

```bash
# 关闭 8080 端口对外访问
sudo ./block-8080.sh
```

**脚本功能**：
- ✅ 允许本地（localhost）访问 8080
- ❌ 拒绝外部（公网）访问 8080
- ✅ Nginx 反向代理仍然正常工作
- ✅ 规则自动保存，重启后生效

### 验证防火墙规则

```bash
# 查看 8080 端口规则
sudo iptables -L INPUT -n -v --line-numbers | grep 8080

# 期望输出（规则顺序很重要）：
# 1. ACCEPT  tcp  --  lo  *  0.0.0.0/0  0.0.0.0/0  tcp dpt:8080
# 2. DROP    tcp  --  *   *  0.0.0.0/0  0.0.0.0/0  tcp dpt:8080
```

**规则解释**：
- 第1条：允许本地回环接口（lo）访问 → Nginx 可以访问
- 第2条：拒绝所有其他接口访问 → 公网无法直接访问

### 手动配置防火墙

如果无法使用脚本，手动配置：

```bash
# 1. 允许本地访问 8080
sudo iptables -I INPUT 1 -i lo -p tcp --dport 8080 -j ACCEPT

# 2. 拒绝外部访问 8080
sudo iptables -I INPUT 2 -p tcp --dport 8080 -j DROP

# 3. 保存规则（Debian/Ubuntu）
sudo netfilter-persistent save

# 或者（其他系统）
sudo iptables-save > /etc/iptables/rules.v4
```

### 清理重复规则

如果规则被重复添加：

```bash
sudo ./cleanup-8080-rules.sh
```

### 测试防火墙

**在 VPS 上测试本地访问（应该成功）**：

```bash
curl http://localhost:8080/
# ✅ 应该返回 HTML 页面
```

**在本地电脑测试外部访问（应该失败）**：

```bash
curl http://<VPS公网IP>:8080
# ❌ 应该超时或连接被拒绝
```

**通过 Nginx 访问（应该成功）**：

```bash
curl https://your-domain.com/
# ✅ 应该返回页面
```

---

## 🚪 Docker 端口绑定

### 安全配置（推荐）

在 `docker-compose.yml` 中：

```yaml
services:
  checksum-api:
    ports:
      - "127.0.0.1:8080:8080"  # ✅ 只绑定到 localhost
```

**效果**：
- Docker 只监听 `127.0.0.1:8080`
- 外部无法直接访问，即使防火墙规则失效
- Nginx 仍然可以通过 `localhost:8080` 访问

### 不安全配置（不推荐）

```yaml
ports:
  - "8080:8080"              # ❌ 绑定到所有接口
  - "0.0.0.0:8080:8080"      # ❌ 显式绑定到所有接口
```

**风险**：
- Docker 监听所有网络接口
- 如果防火墙配置失败，8080 端口将暴露到公网
- 潜在的安全漏洞

---

## 🌐 Nginx 安全配置

### 限流保护

在 Nginx 配置中添加限流：

```nginx
http {
    # 定义限流区域
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    
    server {
        location /api/ {
            # 应用限流（每秒 10 个请求，突发 20 个）
            limit_req zone=api_limit burst=20 nodelay;
            
            proxy_pass http://localhost:8080/api/;
            # ... 其他配置
        }
    }
}
```

### 隐藏版本信息

```nginx
http {
    # 隐藏 Nginx 版本号
    server_tokens off;
    
    # 自定义 Server 头
    more_set_headers "Server: WebServer";
}
```

### 添加安全头

```nginx
server {
    # XSS 保护
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # 内容安全策略
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;
    
    # HTTPS 强制
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}
```

### IP 白名单（可选）

如果只允许特定 IP 访问：

```nginx
location /api/ {
    # 允许特定 IP
    allow 192.168.1.0/24;
    allow 10.0.0.1;
    
    # 拒绝其他所有
    deny all;
    
    proxy_pass http://localhost:8080/api/;
}
```

---

## 🔐 SSL/TLS 配置

### 使用 Let's Encrypt（推荐）

```bash
# 安装 Certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx

# 自动配置 SSL
sudo certbot --nginx -d your-domain.com

# 测试自动续期
sudo certbot renew --dry-run
```

### SSL 最佳实践

在 Nginx 配置中：

```nginx
server {
    listen 443 ssl http2;
    
    # SSL 证书
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    # SSL 协议（只允许 TLS 1.2+）
    ssl_protocols TLSv1.2 TLSv1.3;
    
    # 强加密套件
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # SSL 会话缓存
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
}
```

---

## 🐳 Docker 安全加固

### 限制容器权限

在 `docker-compose.yml` 中：

```yaml
services:
  checksum-api:
    # 只读文件系统
    read_only: true
    
    # 临时目录（只读文件系统需要）
    tmpfs:
      - /tmp
    
    # 禁止权限提升
    security_opt:
      - no-new-privileges:true
    
    # 删除所有 Linux 能力
    cap_drop:
      - ALL
    
    # 限制资源
    deploy:
      resources:
        limits:
          cpus: "0.5"
          memory: 256M
```

### 使用非 root 用户

在 `Dockerfile` 中：

```dockerfile
# 创建非 root 用户
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

# 切换到非 root 用户
USER appuser

CMD ["./checksum-api"]
```

---

## 📊 安全监控

### 日志监控

**Nginx 访问日志**：

```bash
# 实时监控访问
sudo tail -f /var/log/nginx/access.log

# 查找异常请求
sudo grep "POST /api/" /var/log/nginx/access.log | grep -v "200"
```

**Docker 容器日志**：

```bash
# 实时查看应用日志
docker-compose logs -f checksum-api

# 查找错误
docker-compose logs checksum-api | grep -i error
```

### 入侵检测

安装 Fail2ban 防止暴力攻击：

```bash
# 安装 Fail2ban
sudo apt install fail2ban

# 配置 Nginx 保护
sudo nano /etc/fail2ban/jail.local
```

添加配置：

```ini
[nginx-limit-req]
enabled = true
filter = nginx-limit-req
action = iptables-multiport[name=ReqLimit, port="http,https", protocol=tcp]
logpath = /var/log/nginx/error.log
findtime = 600
bantime = 7200
maxretry = 10
```

---

## ✅ 安全检查清单

部署前检查：

- [ ] 防火墙规则已配置（8080 只允许本地访问）
- [ ] Docker 端口绑定到 127.0.0.1
- [ ] Nginx 反向代理配置正确
- [ ] SSL/TLS 证书已安装且有效
- [ ] Nginx 安全头已添加
- [ ] 限流规则已配置
- [ ] 容器资源限制已设置
- [ ] 日志轮转已配置
- [ ] 定期更新 Docker 镜像
- [ ] 定期更新系统包

---

## 🔍 安全审计

### 端口扫描测试

```bash
# 从外部扫描 VPS（在本地电脑运行）
nmap -p 80,443,8080 <VPS公网IP>

# 期望结果：
# 80/tcp   open     http
# 443/tcp  open     https
# 8080/tcp filtered http-proxy  ← 应该是 filtered 或 closed
```

### SSL 测试

使用 SSL Labs 测试：
https://www.ssllabs.com/ssltest/analyze.html?d=your-domain.com

目标评级：**A 或 A+**

---

## 🆘 安全事件响应

### 如果发现异常访问

```bash
# 1. 立即查看日志
sudo tail -100 /var/log/nginx/access.log

# 2. 检查防火墙规则
sudo iptables -L -n -v

# 3. 临时封禁 IP
sudo iptables -I INPUT -s <恶意IP> -j DROP

# 4. 重启服务
docker-compose restart
sudo systemctl restart nginx
```

### 如果 8080 端口暴露

```bash
# 立即关闭端口
sudo ./block-8080.sh

# 或手动配置
sudo iptables -I INPUT -p tcp --dport 8080 -j DROP
sudo netfilter-persistent save
```

---

## 📞 获取帮助

如有安全问题，请：
1. 查看 [DEPLOYMENT.md](./DEPLOYMENT.md) 完整部署文档
2. 运行 `./debug-docker.sh` 诊断脚本
3. 检查防火墙规则：`sudo iptables -L -n -v`
4. 提交 Issue 到 GitHub

**重要提示**：生产环境部署前，请务必完成所有安全检查清单项！
