/**
 * CONTROLADOR DE SINCRONIZACIÓN - VERSIÓN CORREGIDA
 * 
 * Endpoints para sincronización entre dispositivos.
 * 
 * IMPORTANTE: Los modelos actuales NO tienen campos sync_status, deleted_at, is_deleted.
 * Este controlador ha sido corregido para no usar esos campos inexistentes.
 */

const prisma = require('../lib/prisma');
const syncService = require('../services/sync.service');

/**
 * POST /api/sync
 * 
 * Recibe un lote de cambios desde un dispositivo y devuelve los cambios
 * que el dispositivo necesita aplicar.
 */
async function sync(req, res) {
  try {
    const { deviceId, lastSyncAt, changes } = req.body;
    const now = new Date().toISOString();
    
    if (!deviceId) {
      return res.status(400).json({ ok: false, message: 'deviceId es requerido' });
    }
    
    const results = {
      clients: [],
      conversations: [],
      quotations: [],
      orders: [],
      catalog: [],
      campaigns: [],
      bots: [],
      errors: [],
    };
    
    // 1. Procesar cambios entrantes del dispositivo
    if (changes) {
      // Procesar clientes
      if (changes.clients?.length) {
        results.clients = await syncService.processSyncBatch(
          prisma.botClient, 'telefono', changes.clients
        );
      }
      
      // Procesar conversaciones
      if (changes.conversations?.length) {
        results.conversations = await syncService.processSyncBatch(
          prisma.botConversation, 'id', changes.conversations
        );
      }
      
      // Procesar cotizaciones
      if (changes.quotations?.length) {
        results.quotations = await syncService.processSyncBatch(
          prisma.botQuotation, 'id', changes.quotations
        );
      }
      
      // Procesar pedidos
      if (changes.orders?.length) {
        results.orders = await syncService.processSyncBatch(
          prisma.botOrder, 'id', changes.orders
        );
      }
      
      // Procesar catálogo
      if (changes.catalog?.length) {
        results.catalog = await syncService.processSyncBatch(
          prisma.catalogo, 'id', changes.catalog
        );
      }
      
      // Procesar campañas
      if (changes.campaigns?.length) {
        results.campaigns = await syncService.processSyncBatch(
          prisma.botCampaign, 'id', changes.campaigns
        );
      }
      
      // Procesar bots
      if (changes.bots?.length) {
        results.bots = await syncService.processSyncBatch(
          prisma.bot, 'id', changes.bots
        );
      }
    }
    
    // 2. Obtener cambios que el dispositivo necesita (desde lastSyncAt)
    const since = lastSyncAt ? new Date(lastSyncAt) : null;
    
    const [clients, conversations, quotations, orders, catalog, campaigns, bots] = await Promise.all([
      syncService.getAllRecordsForSync(prisma.botClient, {}, since),
      syncService.getAllRecordsForSync(prisma.botConversation, {}, since),
      syncService.getAllRecordsForSync(prisma.botQuotation, {}, since),
      syncService.getAllRecordsForSync(prisma.botOrder, {}, since),
      syncService.getAllRecordsForSync(prisma.catalogo, {}, since),
      syncService.getAllRecordsForSync(prisma.botCampaign, {}, since),
      syncService.getAllRecordsForSync(prisma.bot, {}, since),
    ]);
    
    // 3. Responder con los cambios pendientes
    res.json({
      ok: true,
      data: {
        syncTimestamp: now,
        serverTime: now,
        changes: {
          clients,
          conversations,
          quotations,
          orders,
          catalog,
          campaigns,
          bots,
        },
        results,
      },
    });
  } catch (error) {
    console.error('[SyncController] Error en sync:', error);
    res.status(500).json({
      ok: false,
      message: 'Error en sincronización',
      error: error.message,
    });
  }
}

/**
 * GET /api/sync/status
 * Devuelve el estado de la sincronización
 * NOTA: Como los modelos no tienen sync_status, este endpoint devuelve 0 pendientes.
 * Si se agrega sync_status en el futuro, actualizar este método.
 */
async function syncStatus(req, res) {
  try {
    // Los modelos actuales NO tienen sync_status, así que devolvemos 0
    res.json({
      ok: true,
      data: {
        pendingChanges: {
          clients: 0,
          conversations: 0,
          quotations: 0,
          orders: 0,
          catalog: 0,
          campaigns: 0,
          bots: 0,
        },
        totalPending: 0,
        serverTime: new Date().toISOString(),
        message: 'Los modelos actuales no tienen campo sync_status. Todos los registros se consideran sincronizados.',
      },
    });
  } catch (error) {
    console.error('[SyncController] Error en syncStatus:', error);
    res.status(500).json({ ok: false, message: 'Error al obtener estado de sync' });
  }
}

module.exports = {
  sync,
  syncStatus,
};
