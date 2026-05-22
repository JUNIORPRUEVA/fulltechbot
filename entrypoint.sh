#!/bin/sh
set -eu

echo "Starting FULLTECH BOT backend..."

if [ -z "${DATABASE_URL:-}" ]; then
  echo "ERROR: DATABASE_URL is not configured"
  exit 1
fi

RUN_PRISMA_MIGRATIONS="${RUN_PRISMA_MIGRATIONS:-true}"

if [ "$RUN_PRISMA_MIGRATIONS" = "true" ]; then
  echo "Running Prisma migrations..."
  npx prisma migrate deploy
else
  echo "Prisma migrations are disabled for this environment."
fi

echo "Prisma Client is generated during the image build."

echo "Starting HTTP server on port ${PORT:-3000}..."
exec node src/server.js
