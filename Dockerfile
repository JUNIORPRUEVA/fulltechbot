FROM node:22-alpine

WORKDIR /app

RUN apk add --no-cache openssl ca-certificates

ARG DATABASE_URL
ENV DATABASE_URL=${DATABASE_URL}

COPY package*.json ./

RUN npm ci --omit=dev && npm cache clean --force

COPY --chown=node:node prisma ./prisma
COPY --chown=node:node src ./src
COPY --chown=node:node prisma.config.ts ./prisma.config.ts
COPY --chown=node:node entrypoint.sh ./entrypoint.sh

RUN npx prisma generate && chmod +x ./entrypoint.sh

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:${PORT}/api/health" || exit 1

USER node

CMD ["./entrypoint.sh"]
