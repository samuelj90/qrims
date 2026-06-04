# Build Stage
FROM node:18-alpine AS builder
WORKDIR /app

COPY apps/web/package*.json ./apps/web/
RUN cd apps/web && npm ci

COPY apps/web ./apps/web/
RUN cd apps/web && npm run build

# Production Stage
FROM node:18-alpine
WORKDIR /app

COPY --from=builder /app/apps/web/package*.json ./apps/web/
COPY --from=builder /app/apps/web/node_modules ./apps/web/node_modules
COPY --from=builder /app/apps/web/.next ./apps/web/.next
COPY --from=builder /app/apps/web/public ./apps/web/public

ENV NODE_ENV=production
EXPOSE 3000

CMD ["npm", "--prefix", "apps/web", "start"]
