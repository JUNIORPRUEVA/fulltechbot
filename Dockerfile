FROM node:22-alpine

WORKDIR /app

RUN apk add --no-cache openssl ca-certificates

COPY package*.json ./

RUN npm ci --omit=dev

COPY prisma ./prisma
COPY src ./src
COPY prisma.config.ts ./prisma.config.ts
COPY entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh

RUN chown -R node:node /app

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:${PORT}/api/health" || exit 1

USER node

CMD ["./entrypoint.sh"]
