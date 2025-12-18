# 多阶段构建 Dockerfile for Coding-Tool
# Stage 1: 构建前端
FROM node:18-alpine AS frontend-builder

WORKDIR /app/frontend

# 复制前端项目文件
COPY src/web/package*.json ./
RUN npm ci --only=production

COPY src/web/ ./

# 构建前端静态文件
RUN npm run build

# Stage 2: 构建最终镜像
FROM node:18-alpine

# 安装必要的系统工具
RUN apk add --no-cache \
    tini \
    bash \
    curl

# 创建应用目录
WORKDIR /app

# 复制 package.json 和 package-lock.json
COPY package*.json ./

# 安装生产依赖
RUN npm ci --only=production

# 复制应用源码
COPY bin/ ./bin/
COPY src/ ./src/
COPY docs/ ./docs/
COPY CHANGELOG.md README.md LICENSE ./

# 从前端构建阶段复制构建产物
COPY --from=frontend-builder /app/frontend/dist ../dist/web

# 创建必要的目录
RUN mkdir -p /root/.claude/cc-tool \
    /root/.codex \
    /root/.gemini \
    /root/.cc-tool

# 创建默认配置文件（如果不存在）
RUN echo '{\n\
  "projectsDir": "/root/.claude/projects",\n\
  "defaultProject": null,\n\
  "maxDisplaySessions": 100,\n\
  "pageSize": 15,\n\
  "currentCliType": "claude",\n\
  "ports": {\n\
    "webUI": 10099,\n\
    "proxy": 10088,\n\
    "codexProxy": 10089,\n\
    "geminiProxy": 10090\n\
  },\n\
  "maxLogs": 100,\n\
  "statsInterval": 30,\n\
  "pricing": {\n\
    "claude": {\n\
      "mode": "auto",\n\
      "input": 3,\n\
      "output": 15,\n\
      "cacheCreation": 3.75,\n\
      "cacheRead": 0.3\n\
    },\n\
    "codex": {\n\
      "mode": "auto",\n\
      "input": 2.5,\n\
      "output": 10\n\
    },\n\
    "gemini": {\n\
      "mode": "auto",\n\
      "input": 1.25,\n\
      "output": 5\n\
    }\n\
  },\n\
  "enableSessionBinding": true\n\
}' > /app/config.json.default

# 复制启动脚本
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 暴露端口
EXPOSE 10099 10088 10089 10090

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:10099/api/version || exit 1

# 使用 tini 作为 init 进程
ENTRYPOINT ["/sbin/tini", "--"]

# 启动应用
CMD ["docker-entrypoint.sh"]
