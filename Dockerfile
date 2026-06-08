FROM node:24-alpine AS builder
WORKDIR /app

# 安装 pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# 复制 package.json 文件 及 pnpm 锁定文件
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# 安装所有依赖（使用 pnpm）
RUN pnpm install --frozen-lockfile

# 复制源代码
COPY . .

# 构建包
RUN pnpm run build

# 清理阶段
RUN npm cache clean --force

# 验证构建产物（Nuxt 4 构建后在这里）
RUN if [ -d ./.output ] && [ -f ./.output/server/index.mjs ]; then \
      echo "✅ Build artifacts verified"; \
    else \
      echo "❌ Build verification failed - .output/server/index.mjs not found"; \
      exit 1; \
    fi

# 生产阶段
FROM node:24-alpine AS production

WORKDIR /app

# 启用 corepack
RUN corepack enable && corepack prepare pnpm@latest --activate

# 只复制构建产物和必要的依赖文件
COPY --from=builder /app/.output ./.output
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=builder /app/pnpm-workspace.yaml ./pnpm-workspace.yaml

# 只安装生产依赖
RUN pnpm install --prod --frozen-lockfile

# 设置环境变量
ENV NODE_ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0

# 暴露端口
EXPOSE 3000

# 启动应用
CMD ["node", ".output/server/index.mjs"]