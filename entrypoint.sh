#!/bin/sh
set -eu

echo "Starting FULLTECH BOT backend..."

if [ -z "${DATABASE_URL:-}" ]; then
  echo "ERROR: DATABASE_URL is not configured"
  exit 1
fi

echo "Prisma migrations are disabled for this environment."
echo "Prisma Client is generated during the image build."

echo "Starting HTTP server on port ${PORT:-3000}..."
exec node src/server.js
