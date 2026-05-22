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

  // 3. Crear productos de ejemplo con campos inteligentes
  const productosEjemplo = [
    {
      titulo: 'Kit Cámaras 4CH Full HD',
      categoria: 'Cámaras',
      descripcion: 'Kit completo de 4 cámaras de seguridad Full HD con DVR',
      informacion: 'Incluye 4 cámaras Full HD 1080p, DVR 4 canales, disco duro 1TB, cableado básico e instalación en Higüey.',
      precio: 18500,
      precioMinimo: 16000,
      stock: 10,
      estado: 'activo',
      tipoProducto: 'kit',
      incluye: '4 cámaras Full HD 1080p, DVR 4 canales H.265+, disco duro 1TB, fuente de poder, cableado básico (hasta 20m por cámara), conectores, instalación en Higüey',
      permiteAdicionales: true,
      esCotizable: true,
      orden: 1,
      cantidadBase: 4,
      unidadAdicionalNombre: 'cámara adicional',
      precioAdicional: 3500,
      precioMinimoAdicional: 3000,
      permiteCalculoAdicional: true,
      ciudadBase: 'Higüey',
      cargoFueraCiudad: 1500,
      aplicaCargoFueraCiudad: true,
      instalacionIncluida: true,
      palabrasClave: 'kit, cámaras, seguridad, full hd, 4 canales, dvr',
      reglasNegociacion: 'Precio mínimo RD$16,000. Por cada cámara adicional sobre las 4 incluidas, agregar RD$3,500. Si es fuera de Higüey, agregar RD$1,500 de transporte.',
    },
    {
      titulo: 'Cámara IP 2MP Exterior',
      categoria: 'Cámaras',
      descripcion: 'Cámara IP 2MP para exterior con visión nocturna',
      informacion: 'Cámara IP 2MP (1080p) para exterior, visión nocturna hasta 30m, resistencia IP67, compatible con NVR.',
      precio: 4500,
      precioMinimo: 3800,
      stock: 25,
      estado: 'activo',
      tipoProducto: 'producto',
      permiteAdicionales: true,
      esCotizable: true,
      orden: 2,
      cantidadBase: 1,
      unidadAdicionalNombre: 'cámara',
      precioAdicional: 4500,
      precioMinimoAdicional: 3800,
      permiteCalculoAdicional: false,
      ciudadBase: 'Higüey',
      cargoFueraCiudad: 500,
      aplicaCargoFueraCiudad: true,
      instalacionIncluida: false,
      palabrasClave: 'cámara, ip, exterior, 2mp, seguridad',
      reglasNegociacion: 'Precio mínimo RD$3,800. No incluye instalación.',
    },
    {
      titulo: 'Servicio de Instalación',
      categoria: 'Servicios',
      descripcion: 'Servicio profesional de instalación de sistemas de seguridad',
      informacion: 'Instalación profesional de cámaras, alarmas y sistemas de seguridad. Incluye cableado, montaje y configuración.',
      precio: 3000,
      precioMinimo: 2500,
      stock: 999,
      estado: 'activo',
      tipoProducto: 'servicio',
      permiteAdicionales: false,
      esCotizable: true,
      orden: 10,
      cantidadBase: 1,
      permiteCalculoAdicional: false,
      ciudadBase: 'Higüey',
      cargoFueraCiudad: 1000,
      aplicaCargoFueraCiudad: true,
      instalacionIncluida: false,
      palabrasClave: 'instalación, servicio, técnico, seguridad',
      reglasNegociacion: 'Precio base en Higüey. Fuera de Higüey agregar RD$1,000.',
    },
  ];

  for (const producto of productosEjemplo) {
    const existente = await prisma.catalogo.findFirst({
      where: { titulo: producto.titulo, botId: bot.id },
    });

    if (!existente) {
      await prisma.catalogo.create({
        data: {
          ...producto,
          botId: bot.id,
        },
      });
      console.log(`✅ Producto de ejemplo creado: ${producto.titulo}`);
    } else {
      console.log(`ℹ️  Producto de ejemplo ya existe: ${producto.titulo}`);
    }
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
