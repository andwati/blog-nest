# Multi-stage Dockerfile for blog-nest monorepo
# Builds: backend (NestJS), frontend (Next.js), and shares dependencies
# Location: deploy/Dockerfile - build from root with: docker build -f deploy/Dockerfile .

# Stage 1: Dependencies
FROM node:24-alpine AS deps
WORKDIR /app
RUN npm install -g pnpm@10.30.3

COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
RUN pnpm install --frozen-lockfile

# Stage 2: Build Backend
FROM node:24-alpine AS backend-build
WORKDIR /app
RUN npm install -g pnpm@10.30.3

COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY apps/api ./apps/api
COPY tsconfig.json ./

RUN pnpm install --frozen-lockfile
RUN pnpm --filter api run build

# Stage 3: Backend Runtime
FROM node:24-alpine AS backend-prod
WORKDIR /app
RUN npm install -g pnpm@10.30.3

COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY apps/api/package.json ./apps/api/

RUN pnpm install --prod --frozen-lockfile

COPY --from=backend-build /app/apps/api/dist ./apps/api/dist
COPY --from=backend-build /app/apps/api/package.json ./apps/api/

EXPOSE 3000
ENV NODE_ENV=production
CMD ["node", "apps/api/dist/src/main.js"]

# Stage 4: Build Frontend
FROM node:24-alpine AS frontend-build
WORKDIR /app
RUN npm install -g pnpm@10.30.3

COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY apps/frontend ./apps/frontend
COPY tsconfig.json ./

RUN pnpm install --frozen-lockfile
RUN pnpm --filter frontend run build

# Stage 5: Frontend Runtime
FROM node:24-alpine AS frontend-prod
WORKDIR /app
RUN npm install -g pnpm@10.30.3

COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY apps/frontend/package.json ./apps/frontend/

RUN pnpm install --prod --frozen-lockfile

COPY --from=frontend-build /app/apps/frontend/.next ./apps/frontend/.next
COPY --from=frontend-build /app/apps/frontend/public ./apps/frontend/public
COPY apps/frontend/package.json ./apps/frontend/

EXPOSE 3001
ENV NODE_ENV=production
CMD ["pnpm", "--filter", "frontend", "run", "start"]
