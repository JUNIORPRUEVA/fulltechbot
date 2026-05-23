# FULLTECH BOT - Auditoría y Reparación

## Diagnóstico Completo

### CAUSA RAÍZ ENCONTRADA

**Problema:** Los servicios de backend usan filtros `deleted_at: null` e `is_deleted: false` en consultas de Prisma, pero los modelos en `schema.prisma` NO tienen esos campos definidos.

**Modelos afectados:**
- `Catalogo` - filtro `deleted_at` e `is_deleted` NO existen
- `BotClient` - filtro `deleted_at` e `is_deleted` NO existen  
- `BotConversation` - filtro `deleted_at` e `is_deleted` NO existen
- `BotQuotation` - filtro `deleted_at` e `is_deleted` NO existen
- `BotCampaign` - filtro `deleted_at` e `is_deleted` NO existen

**Único que funciona:** `bot_orders` porque usa SQL raw, no Prisma ORM.

### Plan de Corrección

- [x] 1. DIAGNÓSTICO COMPLETO - Identificar causa raíz
- [ ] 2. CORREGIR servicios backend - Remover filtros `deleted_at`/`is_deleted` que no existen
- [ ] 3. CORREGIR frontend - Manejar arrays vacíos correctamente
- [ ] 4. VERIFICAR endpoints con tablas vacías
- [ ] 5. EJECUTAR seed para asegurar bot existe
- [ ] 6. PRUEBA FINAL de todos los endpoints
