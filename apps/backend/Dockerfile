# Build Stage
FROM node:18-alpine AS builder
RUN sed -i 's/https/http/g' /etc/apk/repositories && apk add --no-cache openssl
WORKDIR /app

ARG NODE_TLS_REJECT_UNAUTHORIZED

COPY apps/backend/package*.json ./apps/backend/
COPY apps/backend/prisma ./apps/backend/prisma/

# Install dependencies (including devDependencies for Nest CLI)
RUN cd apps/backend && npm ci

COPY apps/backend/src ./apps/backend/src/
COPY apps/backend/tsconfig*.json ./apps/backend/

# Run prisma generate and build TypeScript files
RUN cd apps/backend && npx prisma generate && npm run build

# Production Stage
FROM node:18-alpine
RUN sed -i 's/https/http/g' /etc/apk/repositories && apk add --no-cache openssl
WORKDIR /app

COPY --from=builder /app/apps/backend/dist ./apps/backend/dist
COPY --from=builder /app/apps/backend/node_modules ./apps/backend/node_modules
COPY --from=builder /app/apps/backend/package*.json ./apps/backend/
COPY --from=builder /app/apps/backend/prisma ./apps/backend/prisma

ENV NODE_ENV=production
EXPOSE 3000

CMD ["sh", "-c", "npx prisma migrate deploy && node apps/backend/dist/main"]
