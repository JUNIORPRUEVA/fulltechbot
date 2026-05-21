FROM node:22-alpine

WORKDIR /app

RUN apk add --no-cache openssl ca-certificates

COPY backend/package*.json ./

RUN npm ci

COPY backend/prisma ./prisma
COPY backend/src ./src
COPY backend/prisma.config.ts ./prisma.config.ts
COPY backend/entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["./entrypoint.sh"]
