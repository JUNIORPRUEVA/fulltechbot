#!/bin/sh
set -eu

echo "Starting FULLTECH BOT backend..."

if [ -z "${DATABASE_URL:-}" ]; then
  echo "ERROR: DATABASE_URL is not configured"
  exit 1
fi

echo "Generating Prisma Client..."
npx prisma generate

echo "Running database migrations..."
npx prisma migrate deploy

echo "Starting HTTP server on port ${PORT:-3000}..."
exec node src/server.js
