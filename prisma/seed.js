const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Iniciando seed...');

  // 1. Crear o verificar el bot por defecto
  const slug = 'fulltech-seguridad';
  let bot = await prisma.bot.findUnique({ where: { slug } });

  if (!bot) {
    bot = await prisma.bot.create({
      data: {
        nombre: 'FULLTECH Seguridad',
        slug,
        tipoNegocio: 'seguridad',
        estado: 'activo',
      },
    });
    console.log(`✅ Bot por defecto creado: ${bot.nombre} (${bot.id})`);
  } else {
    console.log(`ℹ️  Bot por defecto ya existe: ${bot.nombre} (${bot.id})`);
  }

  // 2. Asignar productos del catálogo con botId null al bot por defecto
  const productosSinBot = await prisma.catalogo.findMany({
    where: { botId: null },
  });

  if (productosSinBot.length > 0) {
    const result = await prisma.catalogo.updateMany({
      where: { botId: null },
      data: { botId: bot.id },
    });
    console.log(`✅ ${result.count} producto(s) del catálogo asignado(s) al bot por defecto`);
  } else {
    console.log('ℹ️  No hay productos del catálogo sin bot asignado');
  }

  console.log('🌱 Seed completado exitosamente.');
}

main()
  .catch((e) => {
    console.error('❌ Error en seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
