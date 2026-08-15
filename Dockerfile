# 第一阶段：构建（安装依赖）
FROM node:18.20.8-alpine AS builder

WORKDIR /tmp

# 仅复制依赖清单，利用 Docker 缓存
COPY package*.json ./

# 安装生产依赖（使用 npm install）
RUN npm install --only=production && npm cache clean --force

# 第二阶段：运行（包含所有系统工具）
FROM node:18.20.8-alpine

# 安装单阶段中的所有系统工具（完全一致）
RUN apk add --no-cache \
    openssl \
    curl \
    bash \
    wget \
    gcompat \
    iproute2 \
    coreutils

# 创建非 root 用户
RUN addgroup -g 1001 -S nodejs \
    && adduser -S nodejs -u 1001 -G nodejs

# ★ 工作目录改为 /tmp（与单阶段一致）
WORKDIR /tmp

# 复制依赖（从 builder 阶段）
COPY --from=builder --chown=nodejs:nodejs /tmp/node_modules ./node_modules

# 复制应用代码
COPY --chown=nodejs:nodejs package*.json *.js index.html ./

# 设置生产环境变量
ENV NODE_ENV=production

# 切换到非 root 用户（安全）
USER nodejs

EXPOSE 7860

CMD ["node", "index.js"]
