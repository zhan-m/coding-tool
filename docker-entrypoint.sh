#!/bin/bash
set -e

echo "🚀 Starting Coding-Tool..."

# 检查并使用默认配置（如果配置文件不存在）
if [ ! -f /app/config.json ]; then
  echo "⚠️  配置文件不存在，使用默认配置..."
  cp /app/config.json.default /app/config.json
fi

# 确保必要的目录存在
mkdir -p /root/.claude/cc-tool /root/.claude/projects
mkdir -p /root/.codex
mkdir -p /root/.gemini
mkdir -p /root/.cc-tool

# 显示配置信息
echo "📦 配置信息："
echo "   - Web UI 端口: ${WEB_UI_PORT:-10099}"
echo "   - Claude 代理端口: ${CLAUDE_PROXY_PORT:-10088}"
echo "   - Codex 代理端口: ${CODEX_PROXY_PORT:-10089}"
echo "   - Gemini 代理端口: ${GEMINI_PROXY_PORT:-10090}"
echo ""

# 启动服务（使用 daemon 模式，避免自动打开浏览器）
exec node /app/bin/ct.js ui --daemon
