# FULLTECH BOT - v2.1.0 - Optimized build
FROM node:22-alpine

WORKDIR /app

RUN apk add --no-cache openssl ca-certificates

ARG DATABASE_URL
ENV DATABASE_URL=${DATABASE_URL}

COPY package*.json ./

RUN npm ci --omit=dev && npm cache clean --force

COPY prisma ./prisma
COPY src ./src
COPY prisma.config.ts ./prisma.config.ts
COPY entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh && npx prisma generate

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:${PORT}/api/health" || exit 1

CMD ["./entrypoint.sh"]
