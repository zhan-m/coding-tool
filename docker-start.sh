#!/bin/bash

# Coding-Tool Docker 快速启动脚本

set -e

echo "🐳 Coding-Tool Docker 快速启动"
echo ""

# 检查 Docker 和 Docker Compose
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: 未安装 Docker"
    echo "请访问 https://docs.docker.com/get-docker/ 安装 Docker"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo "❌ 错误: 未安装 Docker Compose"
    echo "请访问 https://docs.docker.com/compose/install/ 安装 Docker Compose"
    exit 1
fi

# 检查必要的目录
echo "📁 检查数据目录..."
for dir in "$HOME/.claude" "$HOME/.codex" "$HOME/.gemini"; do
    if [ ! -d "$dir" ]; then
        echo "⚠️  目录不存在: $dir"
        echo "   将在首次启动时自动创建"
    fi
done

# 创建 .env 文件（如果不存在）
if [ ! -f .env ]; then
    echo "📝 创建 .env 配置文件..."
    cp .env.example .env
    echo "✅ .env 文件已创建，可以根据需要修改端口配置"
fi

# 询问操作
echo ""
echo "请选择操作："
echo "1) 构建并启动服务"
echo "2) 仅启动服务（使用已有镜像）"
echo "3) 停止服务"
echo "4) 查看日志"
echo "5) 查看服务状态"
echo "6) 重新构建（清除缓存）"
echo "0) 退出"
echo ""
read -p "请输入选项 [1]: " choice
choice=${choice:-1}

case $choice in
    1)
        echo ""
        echo "🔨 构建并启动服务..."
        docker compose build
        docker compose up -d
        echo ""
        echo "✅ 服务已启动！"
        echo ""
        echo "📍 访问地址："
        echo "   Web UI: http://localhost:10099"
        echo ""
        echo "📊 查看日志："
        echo "   docker compose logs -f"
        ;;
    2)
        echo ""
        echo "🚀 启动服务..."
        docker compose up -d
        echo ""
        echo "✅ 服务已启动！"
        echo ""
        echo "📍 访问地址："
        echo "   Web UI: http://localhost:10099"
        ;;
    3)
        echo ""
        echo "🛑 停止服务..."
        docker compose down
        echo "✅ 服务已停止"
        ;;
    4)
        echo ""
        echo "📋 实时日志（Ctrl+C 退出）："
        echo ""
        docker compose logs -f
        ;;
    5)
        echo ""
        echo "📊 服务状态："
        echo ""
        docker compose ps
        ;;
    6)
        echo ""
        echo "🔨 重新构建（清除缓存）..."
        docker compose down
        docker compose build --no-cache
        docker compose up -d
        echo ""
        echo "✅ 服务已重新构建并启动！"
        ;;
    0)
        echo "👋 退出"
        exit 0
        ;;
    *)
        echo "❌ 无效选项"
        exit 1
        ;;
esac

echo ""
