#!/bin/bash

# 快速重启 Docker 服务

echo "=========================================="
echo "快速重启服务"
echo "=========================================="

# 停止并清理
echo -e "\n[1] 停止现有容器..."
docker-compose down 2>/dev/null

# 删除旧镜像（可选）
echo -e "\n[2] 删除旧镜像..."
docker rmi crc_lrc_checksum-api 2>/dev/null || echo "没有旧镜像需要删除"

# 重新构建
echo -e "\n[3] 重新构建镜像..."
docker-compose build --no-cache

# 启动服务
echo -e "\n[4] 启动服务..."
docker-compose up -d

# 等待启动
echo -e "\n[5] 等待服务启动..."
sleep 3

# 检查状态
echo -e "\n[6] 检查容器状态..."
docker-compose ps

# 显示日志
echo -e "\n[7] 最近日志:"
docker-compose logs --tail 20

# 测试服务
echo -e "\n[8] 测试服务..."
sleep 2
curl -s http://localhost:8080/ > /dev/null && echo "✓ 服务运行正常" || echo "✗ 服务未响应"

echo -e "\n=========================================="
echo "重启完成！"
echo "访问: http://localhost:8080"
echo "查看日志: docker-compose logs -f"
echo "=========================================="
