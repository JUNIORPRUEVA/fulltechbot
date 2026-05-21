#!/bin/sh
set -e

echo "Iniciando backend FULLTECH BOT..."

if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL no está configurada"
  exit 1
fi

echo "Generando Prisma Client..."
npx prisma generate

echo "Ejecutando migraciones..."
npx prisma migrate deploy

echo "Iniciando servidor..."
npm run start
