/**
 * Script para poblar datos de prueba de clientes y conversaciones
 * 
 * Uso: node scripts/poblar_datos_prueba.js
 */

const BASE_URL = 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host';
const BOT_ID = 'bot_fulltech_seguridad';

async function apiPost(path, data) {
  const url = `${BASE_URL}${path}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  const result = await response.json();
  if (!result.ok) {
    console.error(`   ❌ Error en ${path}:`, result.message || result.error);
    return null;
  }
  return result.data;
}

async function main() {
  console.log('=== POBLANDO DATOS DE PRUEBA ===\n');

  // ============================================
  // CLIENTE 1: Junior Lopez (conversación completa)
  // ============================================
  console.log('1. Creando cliente: Junior Lopez...');
  const junior = await apiPost(`/api/bots/${BOT_ID}/clients`, {
    telefono: '18295319442',
    chatid: '18295319442@s.whatsapp.net',
    nombre: 'Junior Lopez',
    usuario_whatsapp: 'Junior Lopez',
    interes_principal: 'Sistema de 8 cámaras',
    producto_servicio_interes: 'Sistema de 8 cámaras',
    estado_cliente: 'seguimiento',
    etapa: 'negociacion',
    total_mensajes: 15,
    ultimo_mensaje: 'Ok, entonces quedamos en que mañana voy para allá',
    ultima_interaccion_at: '2026-05-23T18:30:00.000Z',
    ciudad: 'Higüey',
    sector: 'Villa Cerro',
    requiere_seguimiento: true,
    bot_pausado: false,
    humano_tomo_control: false,
    metadata: {},
  });
  if (junior) console.log(`   ✅ Cliente creado: ${junior.nombre}`);
  else console.log('   ⚠️  Junior ya existe, se actualizó');

  console.log('');

  // Conversaciones para Junior
  console.log('2. Creando conversaciones para Junior...');
  const mensajesJunior = [
    { role: 'user', content: 'Buenos días, me interesa un sistema de cámaras para mi casa' },
    { role: 'assistant', content: '¡Buenos días! Claro, con gusto te ayudo. Tenemos varios kits disponibles. ¿Qué tipo de propiedad tienes y cuántas cámaras necesitas aproximadamente?' },
    { role: 'user', content: 'Quiero como 8 cámaras para mi casa en Villa Cerro' },
    { role: 'assistant', content: 'Perfecto. Tenemos un Kit de 8 cámaras Full Color con audio, DVR de 8 canales, disco de 2TB, instalación incluida en Higüey por RD$32,500. ¿Te interesa ese kit o prefieres algo más personalizado?' },
    { role: 'user', content: 'Está bien, pero ¿me puedes hacer descuento?' },
    { role: 'assistant', content: 'Claro, podemos negociar el precio. El precio mínimo que puedo ofrecerte es RD$29,500 para el kit completo de 8 cámaras con instalación. ¿Te parece bien?' },
    { role: 'user', content: 'Ok, entonces quedamos en que mañana voy para allá' },
  ];

  for (let i = 0; i < mensajesJunior.length; i++) {
    const msg = mensajesJunior[i];
    const result = await apiPost(`/api/bots/${BOT_ID}/conversations`, {
      session_id: '18295319442@s.whatsapp.net',
      message: msg,
    });
    if (result) console.log(`   ✅ Mensaje ${i + 1}`);
  }

  console.log('');

  // ============================================
  // CLIENTE 2: Maria Rodriguez (conversación completa)
  // ============================================
  console.log('3. Creando cliente: Maria Rodriguez...');
  const maria = await apiPost(`/api/bots/${BOT_ID}/clients`, {
    telefono: '18091234567',
    chatid: '18091234567@s.whatsapp.net',
    nombre: 'Maria Rodriguez',
    usuario_whatsapp: 'Maria Rodriguez',
    interes_principal: 'Alarma para negocio',
    producto_servicio_interes: 'Alarma',
    estado_cliente: 'prospecto',
    etapa: 'informacion',
    total_mensajes: 5,
    ultimo_mensaje: 'Está bien, voy a pensarlo y te aviso',
    ultima_interaccion_at: '2026-05-23T14:00:00.000Z',
    ciudad: 'Higüey',
    requiere_seguimiento: true,
    bot_pausado: false,
    humano_tomo_control: false,
    metadata: {},
  });
  if (maria) console.log(`   ✅ Cliente creado: ${maria.nombre}`);

  console.log('');

  // Conversaciones para Maria
  console.log('4. Creando conversaciones para Maria...');
  const mensajesMaria = [
    { role: 'user', content: 'Hola, tengo un colmado y quiero poner una alarma' },
    { role: 'assistant', content: '¡Hola Maria! Claro, podemos ayudarte con eso. Tenemos sistemas de alarma para negocios desde RD$8,500. ¿Qué tamaño tiene tu colmado y qué tipo de protección buscas?' },
    { role: 'user', content: 'Es un colmado pequeño, como de 2 puertas. ¿Cuánto cuesta la alarma?' },
    { role: 'assistant', content: 'Para un colmado de ese tamaño te recomiendo nuestro kit básico de alarma con sensor de puerta, sensor de movimiento y sirena por RD$8,500 instalado. Incluye monitoreo desde tu celular. ¿Te gustaría que te visite un técnico para evaluar?' },
    { role: 'user', content: 'Está bien, voy a pensarlo y te aviso' },
  ];

  for (let i = 0; i < mensajesMaria.length; i++) {
    const msg = mensajesMaria[i];
    const result = await apiPost(`/api/bots/${BOT_ID}/conversations`, {
      session_id: '18091234567@s.whatsapp.net',
      message: msg,
    });
    if (result) console.log(`   ✅ Mensaje ${i + 1}`);
  }

  console.log('');

  // ============================================
  // CLIENTE 3: Carlos Perez (conversación corta)
  // ============================================
  console.log('5. Creando cliente: Carlos Perez...');
  const carlos = await apiPost(`/api/bots/${BOT_ID}/clients`, {
    telefono: '18290000001',
    chatid: '18290000001@s.whatsapp.net',
    nombre: 'Carlos Perez',
    usuario_whatsapp: 'Carlos Perez',
    interes_principal: 'Sistema de 4 cámaras',
    producto_servicio_interes: 'Sistema de 4 cámaras',
    estado_cliente: 'prospecto',
    etapa: 'informacion',
    total_mensajes: 3,
    ultimo_mensaje: '¿Cuánto cuesta el kit de 4 cámaras?',
    ultima_interaccion_at: '2026-05-23T16:00:00.000Z',
    ciudad: 'Higüey',
    requiere_seguimiento: true,
    bot_pausado: false,
    humano_tomo_control: false,
    metadata: {},
  });
  if (carlos) console.log(`   ✅ Cliente creado: ${carlos.nombre}`);

  console.log('');

  // Conversaciones para Carlos
  console.log('6. Creando conversaciones para Carlos...');
  const mensajesCarlos = [
    { role: 'user', content: 'Buenas tardes, vi el anuncio del kit de 4 cámaras. ¿Todavía está disponible?' },
    { role: 'assistant', content: '¡Buenas tardes Carlos! Sí, el Kit de 4 Cámaras Full Color con instalación incluida está disponible por RD$19,900 en oferta. Incluye 4 cámaras 2MP, DVR de 4 canales, cableado completo e instalación en Higüey.' },
    { role: 'user', content: '¿Cuánto cuesta el kit de 4 cámaras? ¿Incluye instalación?' },
    { role: 'assistant', content: 'El kit tiene un precio especial de RD$19,900 e incluye instalación completa en Higüey. El precio normal es RD$19,900 pero estamos en oferta. ¿Te interesa agendar una visita técnica?' },
  ];

  for (let i = 0; i < mensajesCarlos.length; i++) {
    const msg = mensajesCarlos[i];
    const result = await apiPost(`/api/bots/${BOT_ID}/conversations`, {
      session_id: '18290000001@s.whatsapp.net',
      message: msg,
    });
    if (result) console.log(`   ✅ Mensaje ${i + 1}`);
  }

  console.log('');

  // ============================================
  // CLIENTE 4: Ana Martinez (nuevo)
  // ============================================
  console.log('7. Creando cliente: Ana Martinez...');
  const ana = await apiPost(`/api/bots/${BOT_ID}/clients`, {
    telefono: '18090000002',
    chatid: '18090000002@s.whatsapp.net',
    nombre: 'Ana Martinez',
    usuario_whatsapp: 'Ana Martinez',
    interes_principal: 'Cerca eléctrico',
    producto_servicio_interes: 'Cerco eléctrico',
    estado_cliente: 'prospecto',
    etapa: 'inicio',
    total_mensajes: 2,
    ultimo_mensaje: 'Hola, quiero información sobre cerca eléctrico',
    ultima_interaccion_at: '2026-05-23T12:00:00.000Z',
    ciudad: 'Higüey',
    requiere_seguimiento: true,
    bot_pausado: false,
    humano_tomo_control: false,
    metadata: {},
  });
  if (ana) console.log(`   ✅ Cliente creado: ${ana.nombre}`);

  console.log('');

  // Conversaciones para Ana
  console.log('8. Creando conversaciones para Ana...');
  const mensajesAna = [
    { role: 'user', content: 'Hola, quiero información sobre cerca eléctrico' },
    { role: 'assistant', content: '¡Hola Ana! Claro, te puedo ayudar con eso. Tenemos sistemas de cerca eléctrica desde RD$12,000 dependiendo del perímetro. ¿De cuántos metros es el terreno que quieres proteger?' },
  ];

  for (let i = 0; i < mensajesAna.length; i++) {
    const msg = mensajesAna[i];
    const result = await apiPost(`/api/bots/${BOT_ID}/conversations`, {
      session_id: '18090000002@s.whatsapp.net',
      message: msg,
    });
    if (result) console.log(`   ✅ Mensaje ${i + 1}`);
  }

  console.log('');
  console.log('=== DATOS DE PRUEBA INSERTADOS CORRECTAMENTE ===');
  console.log('');
  console.log('Resumen:');
  console.log('  - Junior Lopez: 7 mensajes (negociación)');
  console.log('  - Maria Rodriguez: 5 mensajes (información)');
  console.log('  - Carlos Perez: 4 mensajes (información)');
  console.log('  - Ana Martinez: 2 mensajes (inicio)');
}

main().catch(console.error);
