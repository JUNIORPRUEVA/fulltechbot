require('dotenv/config');
const { PrismaClient } = require('@prisma/client');
const { PrismaPg } = require('@prisma/adapter-pg');

const adapter = new PrismaPg(process.env.DATABASE_URL);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('🔍 Verificando tablas...');
  
  // Verificar schemas
  const schemas = await prisma.$queryRawUnsafe(
    `SELECT current_schema(), current_database()`
  );
  console.log('Schema/Database:', schemas);
  
  // Listar tablas públicas
  const tables = await prisma.$queryRawUnsafe(
    `SELECT table_name, table_schema FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name`
  );
  console.log('Tablas en public:', tables.map(t => t.table_name).join(', '));
  
  // Ver si storefront_config existe
  const hasConfig = tables.some(t => t.table_name === 'storefront_config');
  console.log('storefront_config existe:', hasConfig);
  
  // Probar query directa
  try {
    const test = await prisma.$queryRawUnsafe(`SELECT * FROM storefront_config LIMIT 1`);
    console.log('Query storefront_config OK:', test);
  } catch (err) {
    console.error('Error query storefront_config:', err.message);
  }
  
  // Probar con schema explícito
  try {
    const test2 = await prisma.$queryRawUnsafe(`SELECT * FROM public.storefront_config LIMIT 1`);
    console.log('Query public.storefront_config OK:', test2);
  } catch (err) {
    console.error('Error query public.storefront_config:', err.message);
  }
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
