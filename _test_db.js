const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();
p.$queryRawUnsafe('SELECT 1 as ok')
  .then(r => console.log('DB_OK:', JSON.stringify(r)))
  .catch(e => console.log('DB_ERROR:', e.message))
  .finally(() => p.$disconnect());
