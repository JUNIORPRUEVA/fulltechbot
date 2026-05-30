require('dotenv/config');
const { PrismaClient } = require('@prisma/client');
const { PrismaPg } = require('@prisma/adapter-pg');
const fs = require('fs');
const path = require('path');

const adapter = new PrismaPg(process.env.DATABASE_URL);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('📦 Creando tablas storefront...');
  
  const sqlPath = path.join(__dirname, 'sql', 'crear_storefront_tablas.sql');
  const sql = fs.readFileSync(sqlPath, 'utf8');
  
  // Dividir por statements (por CREATE TABLE e CREATE INDEX)
  const statements = sql
    .split(';')
    .map(s => s.trim())
    .filter(s => s.length > 0 && !s.startsWith('--'));
  
  for (const stmt of statements) {
    try {
      await prisma.$executeRawUnsafe(stmt + ';');
      console.log(`✅ Ejecutado: ${stmt.substring(0, 60)}...`);
    } catch (err) {
      if (err.message.includes('ya existe')) {
        console.log(`ℹ️  Ya existe (omitido): ${stmt.substring(0, 60)}...`);
      } else {
        console.error(`❌ Error: ${err.message.substring(0, 100)}`);
        console.error(`   SQL: ${stmt.substring(0, 80)}...`);
      }
    }
  }
  
  console.log('✅ Tablas storefront creadas/verificadas.');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
