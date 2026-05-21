# ---- Build Stage ----
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar archivos de dependencias del backend
COPY backend/package*.json ./

# Instalar TODAS las dependencias (incluye devDependencies para Prisma CLI)
RUN npm ci

# Copiar Prisma schema y config para generar cliente
COPY backend/prisma ./prisma/
COPY backend/prisma.config.ts ./

# Generar Prisma Client
RUN npx prisma generate

# ---- Production Stage ----
FROM node:20-alpine AS production

WORKDIR /app

# Instalar herramientas necesarias para healthcheck
RUN apk add --no-cache wget

# Crear usuario no-root para seguridad
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copiar node_modules completos desde builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma

# Copiar código fuente del backend
COPY backend/src ./src
COPY backend/package*.json ./
COPY backend/prisma.config.ts ./

# Copiar script de entrypoint
COPY backend/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Crear directorio para uploads temporales (multer)
RUN mkdir -p /tmp/uploads && chown -R appuser:appgroup /tmp/uploads

# Cambiar a usuario no-root
USER appuser

# Puerto de la aplicación
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]
