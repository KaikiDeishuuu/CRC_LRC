#!/bin/bash

# Docker 清理脚本
# 清理未使用的镜像、容器、网络和构建缓存

echo "=========================================="
echo "Docker 清理工具"
echo "=========================================="

# 显示当前使用情况
echo -e "\n[清理前] Docker 磁盘使用情况:"
docker system df

echo -e "\n=========================================="
echo "开始清理..."
echo "=========================================="

# 1. 停止并删除当前项目的容器
echo -e "\n[1] 停止并删除项目容器..."
docker-compose down -v 2>/dev/null || echo "没有运行中的容器"

# 2. 删除所有停止的容器
echo -e "\n[2] 删除所有停止的容器..."
STOPPED_CONTAINERS=$(docker ps -aq -f status=exited)
if [ -n "$STOPPED_CONTAINERS" ]; then
    docker rm $STOPPED_CONTAINERS
    echo "✓ 已删除停止的容器"
else
    echo "没有停止的容器需要清理"
fi

# 3. 删除悬空镜像 (dangling images)
echo -e "\n[3] 删除悬空镜像..."
DANGLING_IMAGES=$(docker images -f "dangling=true" -q)
if [ -n "$DANGLING_IMAGES" ]; then
    docker rmi $DANGLING_IMAGES
    echo "✓ 已删除悬空镜像"
else
    echo "没有悬空镜像需要清理"
fi

# 4. 删除未使用的镜像
echo -e "\n[4] 删除未使用的镜像..."
read -p "是否删除所有未使用的镜像? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker image prune -a -f
    echo "✓ 已删除未使用的镜像"
else
    echo "跳过删除未使用的镜像"
fi

# 5. 删除未使用的网络
echo -e "\n[5] 删除未使用的网络..."
docker network prune -f
echo "✓ 已删除未使用的网络"

# 6. 删除构建缓存
echo -e "\n[6] 删除构建缓存..."
read -p "是否删除 Docker 构建缓存? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker builder prune -a -f
    echo "✓ 已删除构建缓存"
else
    echo "跳过删除构建缓存"
fi

# 7. 删除未使用的卷
echo -e "\n[7] 删除未使用的卷..."
read -p "是否删除未使用的卷 (Volume)? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker volume prune -f
    echo "✓ 已删除未使用的卷"
else
    echo "跳过删除未使用的卷"
fi

echo -e "\n=========================================="
echo "清理完成！"
echo "=========================================="

# 显示清理后的使用情况
echo -e "\n[清理后] Docker 磁盘使用情况:"
docker system df

echo -e "\n=========================================="
echo "当前镜像列表:"
docker images

echo -e "\n当前容器列表:"
docker ps -a

echo -e "\n=========================================="
echo "快捷清理命令:"
echo "  清理所有: docker system prune -a -f --volumes"
echo "  仅清理容器: docker container prune -f"
echo "  仅清理镜像: docker image prune -a -f"
echo "  仅清理网络: docker network prune -f"
echo "  仅清理卷: docker volume prune -f"
echo "=========================================="
