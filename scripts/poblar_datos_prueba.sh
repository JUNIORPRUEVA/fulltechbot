#!/bin/bash
# Script para poblar datos de prueba de clientes y conversaciones
# Uso: bash scripts/poblar_datos_prueba.sh

BASE_URL="https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host"
BOT_ID="bot_fulltech_seguridad"

echo "=== POBLANDO DATOS DE PRUEBA ==="
echo ""

# 1. Crear cliente: Junior Lopez
echo "1. Creando cliente: Junior Lopez..."
curl -s -X POST "$BASE_URL/api/bots/$BOT_ID/clients" \
  -H "Content-Type: application/json" \
  -d '{
    "telefono": "18295319442",
    "chatid": "18295319442@s.whatsapp.net",
    "nombre": "Junior Lopez",
    "usuario_whatsapp": "Junior Lopez",
    "interes_principal": "Sistema de 8 cámaras",
    "producto_servicio_interes": "Sistema de 8 cámaras",
    "estado_cliente": "seguimiento",
    "etapa": "negociacion",
    "total_mensajes": 15,
    "ultimo_mensaje": "Ok, entonces quedamos en que mañana voy para allá",
    "ultima_interaccion_at": "2026-05-23T18:30:00.000Z",
    "ciudad": "Higüey",
    "sector": "Villa Cerro",
    "requiere_seguimiento": true,
    "bot_pausado": false,
    "humano_tomo_control": false,
    "metadata": {}
  }' 2>&1 | python -c "import sys,json; d=json.load(sys.stdin); print('   ✅ Cliente creado:', d.get('data',{}).get('nombre','ERROR'))"

echo ""

# 2. Crear conversaciones para Junior Lopez
echo "2. Creando conversaciones..."

# Mensaje 1: Saludo inicial
curl -s -X POST "$BASE_URL/api/bots/$BOT_ID/conversations" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "18295319442@s.whatsapp.net",
    "message": {"role": "user", "content": "Buenos días, me interesa un sistema de cámaras para mi casa"}
  }' 2>&1 > /dev/null
echo "   ✅ Mensaje 1: Saludo inicial"

curl -s -X POST "$BASE_URL/api/bots/$BOT_ID/conversations" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "18295319442@s.whatsapp.net",
    "message": {"role": "assistant", "content": "¡Buenos días! Claro, con gusto te ayudo. Tenemos varios kits disponibles. ¿Qué tipo de propiedad tienes y cuántas cámaras necesitas aproximadamente?"}
  }' 2>&1 > /dev/null
echo "   ✅ Mensaje 2: Respuesta del bot"

curl -s -X POST "$BASE_URL/api/bots/$BOT_ID/conversations" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "18295319442@s.whatsapp.net",
    "message": {"role": "user", "content": "Quiero como 8 cámaras para mi casa en Villa Cerro"}
  }' 2>&1 > /dev/null
echo "   ✅ Mensaje 3: Cliente pide 8 cámaras"

curl -s -X POST "$BASE_URL/api/bots/$BOT_ID/conversations" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "18295319442@s.whatsapp.net",
    "message": {"role": "assistant", "content": "Perfecto. Tenemos un Kit de 8 cámaras Full Color con audio, DVR de 8 canales, disco de 2TB, instalación incluida en Higüey por RD$32,500. ¿Te interesa ese kit o prefieres algo más personalizado?"}
  }' 2>&1 > /dev/null
echo "   ✅ Mensaje 4: Bot ofrece kit"

curl -s -X POST "$BASE_URL/api/bots/$BOT_ID/conversations" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "18295319442@s.whatsapp.net",
    "message": {"role": "user", "content": "Está bien, pero ¿me puedes hacer descuento?"}
  }' 2>&1 > /dev/null
echo "   ✅ Mensaje 5: Cliente pide descuento"

curl -s -X POST "$BASE_URL/api/bots/$BOT_ID/conversations" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "18295319442@s.whatsapp.net",
    "message": {"role": "assistant", "content": "Claro, podemos negociar el precio. El precio mínimo que puedo ofrecerte es RD$29,500 para el kit completo de 8 cámaras con instalación. ¿Te parece bien?"}
  }' 2>&1 > /dev/null
echo "   ✅ Mensaje 6: Bot negocia"

curl -s -X POST "$BASE_URL/api/bots/$BOT_ID/conversations" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "18295319442@s.whatsapp.net",
    "message": {"role": "user", "content": "Ok, entonces quedamos en que mañana voy para allá"}
  }' 2>&1 > /dev/null
echo "   ✅ Mensaje 7: Cliente confirma"

echo ""

# 3. Crear cliente: Maria Rodriguez
echo "3. Creando cliente: Maria Rodriguez..."
curl -s -X POST "$BASE_URL/api/bots/$BOT_ID/clients" \
  -H "Content-Type: application/json" \
  -d '{
    "telefono": "18091234567",
    "chatid": "18091234567@s.whatsapp.net",
    "nombre": "Maria Rodriguez",
    "usuario_whatsapp": "Maria Rodriguez",
    "interes_principal": "Alarma para negocio",
    "producto_servicio_interes": "Alarma",
    "estado_cliente": "prospecto",
    "etapa": "informacion",
    "total_mensajes": 5,
    "ultimo_mensaje": "¿Cuánto cuesta la alarma?",
    "ultima_interaccion_at": "2026-05-23T14:00:00.000Z",
    "ciudad": "Higüey",
    "requiere_seguimiento": true,
    "bot_pausado": false,
    "humano_tomo_control": false,
    "metadata": {}
  }' 2>&1 | python -c "import sys,json; d=json.load(sys.stdin); print('   ✅ Cliente creado:', d.get('data',{}).get('nombre','ERROR'))"

echo ""

# 4. Crear conversaciones para Maria
echo "4. Creando conversaciones para Maria..."
curl -s -X POST "$BASE_URL/api/bots/$BOT_ID/conversations" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "18091234567@s.whatsapp.net",
    "message": {"role": "user", "content": "Hola, tengo un colmado y quiero poner una alarma"}
  }' 2>&1 > /dev/null
echo "   ✅ Mensaje 1"

curl -s -X POST "$BASE_URL/api/bots/$BOT_ID/conversations" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "18091234567@s.whatsapp.net",
    "message": {"role": "assistant", "content": "¡Hola Maria! Claro, podemos ayudarte con eso. Tenemos sistemas de alarma para negocios desde RD$8,500. ¿Qué tamaño tiene tu colmado y qué tipo de protección buscas?"}
  }' 2>&1 > /dev/null
echo "   ✅ Mensaje 2"

curl -s -X POST "$BASE_URL/api/bots/$BOT_ID/conversations" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "18091234567@s.whatsapp.net",
    "message": {"role": "user", "content": "Es un colmado pequeño, como de 2 puertas. ¿Cuánto cuesta la alarma?"}
  }' 2>&1 > /dev/null
echo "   ✅ Mensaje 3"

curl -s -X POST "$BASE_URL/api/bots/$BOT_ID/conversations" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "18091234567@s.whatsapp.net",
    "message": {"role": "assistant", "content": "Para un colmado de ese tamaño te recomiendo nuestro kit básico de alarma con sensor de puerta, sensor de movimiento y sirena por RD$8,500 instalado. Incluye monitoreo desde tu celular. ¿Te gustaría que te visite un técnico para evaluar?"}
  }' 2>&1 > /dev/null
echo "   ✅ Mensaje 4"

curl -s -X POST "$BASE_URL/api/bots/$BOT_ID/conversations" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "18091234567@s.whatsapp.net",
    "message": {"role": "user", "content": "Está bien, voy a pensarlo y te aviso"}
  }' 2>&1 > /dev/null
echo "   ✅ Mensaje 5"

echo ""
echo "=== DATOS DE PRUEBA INSERTADOS CORRECTAMENTE ==="
echo ""
echo "Verifica con:"
echo "  curl -s $BASE_URL/api/bots/$BOT_ID/clients | python -m json.tool"
echo "  curl -s $BASE_URL/api/bots/$BOT_ID/conversations | python -m json.tool"
