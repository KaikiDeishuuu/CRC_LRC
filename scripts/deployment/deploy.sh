#!/bin/bash

# CRC/LRC 校验计算器 - 快速部署脚本
# 使用方法: ./deploy.sh [build|start|stop|restart|logs|status]

set -e

PROJECT_NAME="checksum-api"
DOCKER_COMPOSE_FILE="docker-compose.yml"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    info "Docker 和 Docker Compose 已安装"
}

# 构建前端
build_frontend() {
    info "开始构建前端..."
    
    if [ ! -d "frontend" ]; then
        error "frontend 目录不存在"
        exit 1
    fi
    
    cd frontend
    
    if [ ! -f "yarn.lock" ]; then
        warn "yarn.lock 不存在，执行 yarn install"
        yarn install
    fi
    
    info "编译前端资源..."
    yarn build
    
    cd ..
    info "前端构建完成"
}

# 构建 Docker 镜像
build_image() {
    info "开始构建 Docker 镜像..."
    
    docker-compose build --no-cache
    
    info "Docker 镜像构建完成"
}

# 启动容器
start_container() {
    info "启动 Docker 容器..."
    
    docker-compose up -d
    
    info "容器已启动"
    sleep 3
    
    # 检查容器状态
    check_status
}

# 停止容器
stop_container() {
    info "停止 Docker 容器..."
    
    docker-compose down
    
    info "容器已停止"
}

# 重启容器
restart_container() {
    info "重启 Docker 容器..."
    
    docker-compose restart
    
    info "容器已重启"
    sleep 3
    
    check_status
}

# 查看日志
show_logs() {
    info "显示容器日志 (Ctrl+C 退出)..."
    
    docker-compose logs -f $PROJECT_NAME
}

# 检查状态
check_status() {
    info "检查容器状态..."
    
    docker-compose ps
    
    echo ""
    
    # 测试 API
    if curl -s http://localhost:8080/ > /dev/null; then
        info "✓ API 服务运行正常 (http://localhost:8080)"
    else
        warn "✗ API 服务未响应"
    fi
    
    # 测试 API 端点
    RESULT=$(curl -s -X POST http://localhost:8080/api/checksum \
        -H "Content-Type: application/json" \
        -d '{"data":"Hello","method":"text"}' 2>/dev/null || echo "")
    
    if [ -n "$RESULT" ]; then
        info "✓ API 端点测试成功"
        echo "$RESULT" | python3 -m json.tool 2>/dev/null || echo "$RESULT"
    else
        warn "✗ API 端点测试失败"
    fi
}

# 完整部署
full_deploy() {
    info "========================================="
    info "开始完整部署流程"
    info "========================================="
    
    check_docker
    build_frontend
    build_image
    start_container
    
    info "========================================="
    info "部署完成！"
    info "========================================="
    info "访问地址: http://localhost:8080"
    info "查看日志: ./deploy.sh logs"
    info "停止服务: ./deploy.sh stop"
}

# 更新部署（无需重新构建前端）
update_deploy() {
    info "更新部署（快速模式）..."
    
    docker-compose up -d --build
    
    info "更新完成"
    check_status
}

# 清理
cleanup() {
    info "清理未使用的 Docker 资源..."
    
    docker-compose down
    docker image prune -f
    docker volume prune -f
    
    info "清理完成"
}

# 显示帮助
show_help() {
    cat << EOF
CRC/LRC 校验计算器 - 部署脚本

使用方法:
  ./deploy.sh [命令]

命令:
  build       - 构建前端和 Docker 镜像
  start       - 启动容器
  stop        - 停止容器
  restart     - 重启容器
  logs        - 查看实时日志
  status      - 检查服务状态
  deploy      - 完整部署（推荐首次使用）
  update      - 快速更新部署
  cleanup     - 清理 Docker 资源
  help        - 显示此帮助信息

示例:
  # 首次部署
  ./deploy.sh deploy
  
  # 更新代码后重新部署
  git pull
  ./deploy.sh update
  
  # 查看日志
  ./deploy.sh logs
  
  # 检查状态
  ./deploy.sh status

EOF
}

# 主函数
main() {
    case "${1:-help}" in
        build)
            check_docker
            build_frontend
            build_image
            ;;
        start)
            start_container
            ;;
        stop)
            stop_container
            ;;
        restart)
            restart_container
            ;;
        logs)
            show_logs
            ;;
        status)
            check_status
            ;;
        deploy)
            full_deploy
            ;;
        update)
            update_deploy
            ;;
        cleanup)
            cleanup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
