# 多阶段构建 Dockerfile
# 阶段1: 构建前端
FROM node:18-alpine AS frontend-builder

WORKDIR /app

# 复制整个前端目录
COPY frontend ./frontend

# 切换到前端目录
WORKDIR /app/frontend

# 安装依赖
RUN yarn install --frozen-lockfile

# 构建前端
RUN yarn build

# 阶段2: 构建 Go 应用
FROM golang:1.21-alpine AS go-builder

WORKDIR /app

# 安装必要的构建工具
RUN apk add --no-cache git

# 复制 Go 模块文件
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制源码
COPY . .

# 从前端构建阶段复制编译后的文件
COPY --from=frontend-builder /app/frontend/dist ./web

# 构建 Go 应用（静态编译）
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o checksum-api .

# 阶段3: 最终运行镜像
FROM alpine:latest

# 安装 CA 证书（用于 HTTPS 请求）
RUN apk --no-cache add ca-certificates tzdata

# 设置时区为中国
ENV TZ=Asia/Shanghai

WORKDIR /app

# 从构建阶段复制可执行文件
COPY --from=go-builder /app/checksum-api .

# 复制配置文件
COPY --from=go-builder /app/config ./config

# 复制前端资源
COPY --from=go-builder /app/web ./web

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/ || exit 1

# 运行应用
CMD ["./checksum-api"]
