# 多阶段构建 Dockerfile
# 阶段1: 构建前端
FROM node:18-alpine AS frontend-builder

WORKDIR /app/frontend

# 复制前端依赖配置文件
COPY frontend/package.json frontend/yarn.lock* ./

# 安装依赖
RUN yarn install --frozen-lockfile

# 复制前端源码
COPY frontend/ ./

# 构建前端
RUN yarn build

# 阶段2: 构建 Go 后端
FROM golang:alpine AS backend-builder

WORKDIR /app

# 安装构建依赖
RUN apk add --no-cache git

# 复制 go.mod 和 go.sum
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

# 安装必要的运行时依赖
RUN apk --no-cache add ca-certificates tzdata

# 设置时区
ENV TZ=Asia/Shanghai

WORKDIR /app

# 从构建阶段复制二进制文件
COPY --from=backend-builder /app/checksum-api .

# 从前端构建阶段复制静态文件
COPY --from=frontend-builder /app/frontend/dist ./web
