# Docker 部署指南

## 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- 宿主机已安装并配置好 Claude Code / Codex / Gemini CLI

## 快速开始

### 1. 构建镜像

```bash
docker-compose build
```

### 2. 启动服务

```bash
docker-compose up -d
```

### 3. 查看日志

```bash
docker-compose logs -f
```

### 4. 访问 Web UI

打开浏览器访问：`http://localhost:10099`

## 配置说明

### 端口配置

默认端口映射：
- `10099` - Web UI + WebSocket
- `10088` - Claude 代理服务
- `10089` - Codex 代理服务
- `10090` - Gemini 代理服务

如需修改端口，可以创建 `.env` 文件：

```bash
cp .env.example .env
# 编辑 .env 文件修改端口
```

### 卷挂载说明

容器会挂载以下宿主机目录：

| 宿主机路径 | 容器内路径 | 说明 |
|-----------|-----------|------|
| `~/.claude` | `/root/.claude` | Claude 项目和会话数据 |
| `~/.codex` | `/root/.codex` | Codex 配置和会话数据 |
| `~/.gemini` | `/root/.gemini` | Gemini 配置和会话数据 |
| `~/.cc-tool` | `/root/.cc-tool` | UI 配置和通知脚本 |
| `./config.json` | `/app/config.json` | Coding-Tool 配置文件 |

⚠️ **重要提示**：
- 容器需要访问这些目录才能正常工作
- 如果目录不存在，容器会自动创建
- 数据修改会同步到宿主机

## 常用命令

### 启动服务
```bash
docker-compose up -d
```

### 停止服务
```bash
docker-compose down
```

### 重启服务
```bash
docker-compose restart
```

### 查看日志
```bash
# 实时日志
docker-compose logs -f

# 查看最近 100 行
docker-compose logs --tail=100
```

### 进入容器
```bash
docker-compose exec coding-tool sh
```

### 更新镜像
```bash
# 拉取最新代码
git pull

# 重新构建
docker-compose build --no-cache

# 重启服务
docker-compose up -d
```

## 健康检查

容器内置了健康检查，每 30 秒检查一次服务状态：

```bash
# 查看健康状态
docker-compose ps
```

如果服务异常，健康检查会显示 `unhealthy` 状态。

## 故障排查

### 1. 端口被占用

如果启动失败提示端口被占用：

```bash
# 检查端口占用
lsof -i :10099

# 方法 1: 停止占用端口的进程
# 方法 2: 修改 .env 文件使用其他端口
```

### 2. 卷挂载权限问题

如果遇到权限错误：

```bash
# 检查目录权限
ls -la ~/.claude ~/.codex ~/.gemini

# 确保当前用户有读写权限
chmod -R 755 ~/.claude ~/.codex ~/.gemini
```

### 3. 前端页面无法访问

检查：
1. 容器是否正常运行：`docker-compose ps`
2. 端口映射是否正确：`docker-compose port coding-tool 10099`
3. 防火墙是否放行：`sudo ufw status`

### 4. 无法访问 CLI 会话

确认：
1. 宿主机的 CLI 已正确安装和配置
2. `~/.claude/projects` 目录存在且有数据
3. 卷挂载路径正确

## 环境变量

支持的环境变量：

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `NODE_ENV` | `production` | Node.js 运行环境 |
| `TZ` | `Asia/Shanghai` | 时区设置 |
| `WEB_UI_PORT` | `10099` | Web UI 端口 |
| `CLAUDE_PROXY_PORT` | `10088` | Claude 代理端口 |
| `CODEX_PROXY_PORT` | `10089` | Codex 代理端口 |
| `GEMINI_PROXY_PORT` | `10090` | Gemini 代理端口 |

## 性能优化

### 日志管理

默认配置限制日志大小为 10MB，保留 3 个文件。如需调整：

```yaml
# 在 docker-compose.yml 中修改
logging:
  driver: "json-file"
  options:
    max-size: "50m"  # 增加到 50MB
    max-file: "5"    # 保留 5 个文件
```

### 资源限制

如果需要限制容器资源使用：

```yaml
# 在 docker-compose.yml 中添加
services:
  coding-tool:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
```

## 网络配置

### 使用自定义网络

如果需要与其他容器通信：

```yaml
networks:
  coding-tool-network:
    driver: bridge

services:
  coding-tool:
    networks:
      - coding-tool-network
```

### 暴露到外网

⚠️ **安全警告**：暴露服务到公网前请确保：
1. 已配置防火墙规则
2. 使用 HTTPS 反向代理（如 Nginx + Let's Encrypt）
3. 启用身份认证（项目当前不支持，需要额外配置）

Nginx 反向代理配置示例：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:10099;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 数据备份

### 备份所有数据

```bash
# 创建备份目录
mkdir -p ~/coding-tool-backup

# 备份数据
tar -czf ~/coding-tool-backup/backup-$(date +%Y%m%d-%H%M%S).tar.gz \
  ~/.claude \
  ~/.codex \
  ~/.gemini \
  ~/.cc-tool \
  ./config.json
```

### 恢复数据

```bash
# 解压备份
tar -xzf ~/coding-tool-backup/backup-YYYYMMDD-HHMMSS.tar.gz -C ~/

# 重启容器
docker-compose restart
```

## 升级指南

### 升级到新版本

```bash
# 1. 备份数据（推荐）
tar -czf ~/coding-tool-backup.tar.gz ~/.claude ~/.codex ~/.gemini

# 2. 停止服务
docker-compose down

# 3. 拉取最新代码
git pull origin main

# 4. 重新构建镜像
docker-compose build --no-cache

# 5. 启动服务
docker-compose up -d

# 6. 查看日志确认启动成功
docker-compose logs -f
```

## 卸载

### 完全移除

```bash
# 停止并删除容器
docker-compose down

# 删除镜像
docker rmi coding-tool:latest

# （可选）删除数据
rm -rf ~/.claude/cc-tool
rm -rf ~/.cc-tool
```

⚠️ **注意**：不要删除 `~/.claude/projects`，那是 Claude CLI 的会话数据。

## 常见问题

### Q: 容器内能看到宿主机的 CLI 会话吗？

A: 可以。通过卷挂载，容器可以访问宿主机的 `~/.claude`、`~/.codex`、`~/.gemini` 目录，读取所有会话数据。

### Q: 在容器内修改配置会影响宿主机吗？

A: 会。所有数据都是双向同步的，容器内的修改会立即反映到宿主机。

### Q: 能否在多台机器上使用同一个数据目录？

A: 不推荐。CLI 的会话数据包含本地路径和状态，在不同机器上可能出现问题。建议每台机器独立运行。

### Q: Docker 方式相比 npm 全局安装有什么优势？

A:
- ✅ 环境隔离，不污染宿主机 Node.js 环境
- ✅ 依赖版本锁定，避免版本冲突
- ✅ 一键部署，无需关心 Node.js 版本
- ✅ 易于迁移和分发
- ✅ 统一的日志管理和监控

### Q: 性能会有损失吗？

A: Docker 的性能损失通常在 5% 以内，对于这类 I/O 密集型应用几乎可以忽略。

## 技术支持

遇到问题？

1. 查看日志：`docker-compose logs -f`
2. 检查健康状态：`docker-compose ps`
3. 提交 Issue：https://github.com/CooperJiang/cc-tool/issues
