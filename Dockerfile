FROM node:22-alpine

WORKDIR /app

RUN apk add --no-cache openssl ca-certificates

COPY package*.json ./

RUN npm ci

COPY prisma ./prisma
COPY src ./src
COPY prisma.config.ts ./prisma.config.ts
COPY entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["./entrypoint.sh"]
