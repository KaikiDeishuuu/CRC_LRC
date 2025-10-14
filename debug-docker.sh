#!/bin/bash

# Docker 容器调试脚本

echo "=========================================="
echo "Docker 容器诊断"
echo "=========================================="

echo -e "\n[1] 容器状态:"
docker ps -a | grep checksum

echo -e "\n[2] 容器最近日志 (最后 50 行):"
docker logs --tail 50 checksum-api 2>&1

echo -e "\n[3] 检查容器内文件结构:"
docker run --rm crc_lrc_checksum-api ls -la /app

echo -e "\n[4] 检查配置文件是否存在:"
docker run --rm crc_lrc_checksum-api ls -la /app/config

echo -e "\n[5] 检查可执行文件权限:"
docker run --rm crc_lrc_checksum-api ls -l /app/checksum-api

echo -e "\n[6] 尝试手动运行程序:"
docker run --rm crc_lrc_checksum-api ./checksum-api &
sleep 3
kill %1 2>/dev/null

echo -e "\n[7] 检查端口占用:"
netstat -tlnp | grep 8080 || ss -tlnp | grep 8080 || echo "端口 8080 未被占用"

echo -e "\n[8] Docker Compose 配置:"
cat docker-compose.yml

echo -e "\n=========================================="
echo "诊断完成"
echo "=========================================="
