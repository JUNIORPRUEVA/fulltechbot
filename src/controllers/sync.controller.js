/**
 * CONTROLADOR DE SINCRONIZACIÓN
 * 
 * Endpoints para sincronización entre dispositivos.
 * POST /api/sync - Recibe cambios de un dispositivo y devuelve cambios pendientes
 * GET /api/sync/status - Estado de la sincronización
 */

const prisma = require('../lib/prisma');
const syncService = require('../services/sync.service');

/**
 * POST /api/sync
 * 
 * Recibe un lote de cambios desde un dispositivo y devuelve los cambios
 * que el dispositivo necesita aplicar.
 * 
 * Body esperado:
 * {
 *   deviceId: "string",
 *   lastSyncAt: "ISO date string",
 *   changes: {
 *     clients: [...],
 *     conversations: [...],
 *     quotations: [...],
 *     orders: [...],
 *     catalog: [...],
 *     campaigns: [...],
 *     bots: [...]
 *   }
 * }
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
 */
async function syncStatus(req, res) {
  try {
    const counts = await Promise.all([
      prisma.botClient.count({ where: { sync_status: { not: 'synced' } } }),
      prisma.botConversation.count({ where: { sync_status: { not: 'synced' } } }),
      prisma.botQuotation.count({ where: { sync_status: { not: 'synced' } } }),
      prisma.botOrder.count({ where: { sync_status: { not: 'synced' } } }),
      prisma.catalogo.count({ where: { sync_status: { not: 'synced' } } }),
      prisma.botCampaign.count({ where: { sync_status: { not: 'synced' } } }),
      prisma.bot.count({ where: { sync_status: { not: 'synced' } } }),
    ]);
    
    res.json({
      ok: true,
      data: {
        pendingChanges: {
          clients: counts[0],
          conversations: counts[1],
          quotations: counts[2],
          orders: counts[3],
          catalog: counts[4],
          campaigns: counts[5],
          bots: counts[6],
        },
        totalPending: counts.reduce((a, b) => a + b, 0),
        serverTime: new Date().toISOString(),
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
