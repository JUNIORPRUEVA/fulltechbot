# PLAN DE TRABAJO - Auditoría y Corrección de Sincronización/Eliminación

## FASE 1: Auditoría (COMPLETADA)
- [x] Analizar arquitectura de datos (Prisma schema, modelos, relaciones)
- [x] Identificar tablas/entidades con datos de usuario
- [x] Identificar campos de sincronización existentes
- [x] Revisar flujos de eliminación actuales
- [x] Diagnosticar por qué datos borrados vuelven a aparecer

## FASE 2: Migración de Base de Datos (Prisma) (COMPLETADA)
- [x] Agregar campos de sincronización a todas las tablas (deletedAt, isDeleted, syncStatus, updatedAt)
- [x] Agregar índices necesarios
- [x] Ejecutar migración (20260523000000_add_sync_fields)

## FASE 3: Backend - Soft Delete y Sincronización (COMPLETADA)
- [x] Modificar servicios para usar soft delete en lugar de delete físico
  - [x] botClient.service.js - eliminarCliente usa soft delete
  - [x] botConversation.service.js - eliminarConversacion usa soft delete
  - [x] botQuotation.service.js - eliminarCotizacion usa soft delete
  - [x] order.service.js - eliminarOrden usa soft delete
  - [x] quotation.service.js - eliminarCotizacion usa soft delete
  - [x] catalogo.service.js - eliminarProducto usa soft delete
  - [x] botCampaign.service.js - eliminar usa soft delete
- [x] Modificar queries para filtrar deletedAt IS NULL en listados
  - [x] botClient.service.js - listarClientes filtra eliminados
  - [x] botConversation.service.js - listarConversaciones filtra eliminados
  - [x] botQuotation.service.js - listarCotizaciones filtra eliminados
  - [x] quotation.service.js - listarCotizaciones filtra eliminados
  - [x] catalogo.service.js - listarCatalogo filtra eliminados
  - [x] botCampaign.service.js - listar filtra eliminados
- [x] Crear sync.service.js (backend) con lógica de resolución de conflictos
- [x] Crear sync.controller.js con endpoints de sincronización
- [x] Crear sync.routes.js con rutas de sincronización
- [x] Registrar rutas de sync en server.js

## FASE 4: Frontend - Modelos y Servicios (COMPLETADA)
- [x] Crear SyncService (cola offline, sincronización inmediata, deviceId)
- [x] Agregar dependencia connectivity_plus al pubspec.yaml

## FASE 5: Frontend - Providers (COMPLETADA)
- [x] Modificar ClientesProvider para usar SyncService con eliminación optimista
- [x] Modificar ConversacionesProvider para usar SyncService con eliminación optimista
- [x] Modificar QuotationProvider para usar SyncService con eliminación optimista
- [x] Modificar OrderProvider para usar SyncService con eliminación optimista
- [x] Modificar CatalogoProvider para usar SyncService con eliminación optimista

## FASE 6: Frontend - UI (Botones de Eliminar) (COMPLETADA)
- [x] Agregar botón eliminar en OrdersPage con confirmación
- [x] Agregar botón eliminar en QuotationsPage con confirmación
- [x] Mejorar diálogos de confirmación con advertencias de cascada

## FASE 7: Eliminación en Cascada (COMPLETADA en backend)
- [x] Implementar cascada al eliminar cliente en botClient.service.js (conversaciones, mensajes, cotizaciones, pedidos)
- [x] Implementar cascada al eliminar conversación en botConversation.service.js (mensajes)
- [x] Asegurar que no queden huérfanos

## FASE 8: Pruebas (PENDIENTE - requiere ejecución manual)
- [ ] Prueba 1: Crear cliente en A, verificar en B
- [ ] Prueba 2: Eliminar cliente en A, verificar en B
- [ ] Prueba 3: Eliminar cliente con relaciones
- [ ] Prueba 4: Eliminar cotización individual
- [ ] Prueba 5: Offline delete + sync
- [ ] Prueba 6: Conflicto update vs delete
- [ ] Prueba 7: Eliminar conversación con mensajes
- [ ] Prueba 8: Eliminar campaña
- [ ] Prueba 9: Eliminar producto
- [ ] Prueba 10: Reiniciar app después de eliminar
