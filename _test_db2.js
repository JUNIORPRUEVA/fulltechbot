require('dotenv').config();
const { PrismaPg } = require('@prisma/adapter-pg');
const { PrismaClient } = require('@prisma/client');

async function test() {
  try {
    const adapter = new PrismaPg(process.env.DATABASE_URL);
    const prisma = new PrismaClient({ adapter });
    const result = await prisma.$queryRawUnsafe('SELECT 1 as ok');
    console.log('DB_OK:', JSON.stringify(result));
    await prisma.$disconnect();
  } catch (e) {
    console.log('DB_ERROR:', e.message);
    console.log('DB_ERROR_CODE:', e.code);
    console.log('DB_ERROR_META:', JSON.stringify(e.meta || {}));
  }
}
test();
