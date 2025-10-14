.PHONY: help build run docker-build docker-up docker-down docker-logs docker-restart frontend clean test

# 默认目标
help:
	@echo "CRC/LRC 校验计算器 - 可用命令："
	@echo ""
	@echo "  make build          - 编译 Go 应用"
	@echo "  make run            - 运行应用（开发模式）"
	@echo "  make frontend       - 构建前端"
	@echo ""
	@echo "  make docker-build   - 构建 Docker 镜像"
	@echo "  make docker-up      - 启动 Docker 容器"
	@echo "  make docker-down    - 停止 Docker 容器"
	@echo "  make docker-logs    - 查看 Docker 日志"
	@echo "  make docker-restart - 重启 Docker 容器"
	@echo ""
	@echo "  make deploy         - 完整部署（推荐）"
	@echo "  make test           - 运行测试"
	@echo "  make clean          - 清理构建文件"
	@echo ""

# 编译 Go 应用
build:
	@echo "编译 Go 应用..."
	go build -o bin/checksum-api .
	@echo "编译完成: bin/checksum-api"

# 运行应用
run:
	@echo "启动应用..."
	go run .

# 构建前端
frontend:
	@echo "构建前端..."
	cd frontend && yarn install && yarn build
	@echo "前端构建完成"

# Docker 构建镜像
docker-build: frontend
	@echo "构建 Docker 镜像..."
	docker-compose build --no-cache

# Docker 启动容器
docker-up:
	@echo "启动 Docker 容器..."
	docker-compose up -d
	@sleep 2
	@docker-compose ps
	@echo ""
	@echo "访问地址: http://localhost:8080"

# Docker 停止容器
docker-down:
	@echo "停止 Docker 容器..."
	docker-compose down

# Docker 查看日志
docker-logs:
	docker-compose logs -f checksum-api

# Docker 重启
docker-restart:
	@echo "重启 Docker 容器..."
	docker-compose restart
	@sleep 2
	@docker-compose ps

# 完整部署
deploy: frontend docker-build docker-up
	@echo ""
	@echo "========================================="
	@echo "部署完成！"
	@echo "========================================="
	@echo "访问地址: http://localhost:8080"
	@echo "查看日志: make docker-logs"
	@echo "停止服务: make docker-down"

# 运行测试
test:
	@echo "运行测试..."
	go test -v ./...

# 清理构建文件
clean:
	@echo "清理构建文件..."
	rm -rf bin/
	rm -rf frontend/dist/
	rm -rf frontend/node_modules/
	docker-compose down
	docker image prune -f
	@echo "清理完成"
