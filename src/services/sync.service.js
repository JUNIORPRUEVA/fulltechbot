/**
 * SERVICIO DE SINCRONIZACIÓN
 * 
 * Maneja la sincronización entre dispositivos usando soft delete.
 * 
 * Estrategia:
 * - Todas las tablas tienen: deleted_at, is_deleted, sync_status, updated_at
 * - Los deletes son soft delete (marcar como eliminado, no borrar físicamente)
 * - Los tombstones se conservan para propagar eliminaciones a otros dispositivos
 * - Las queries normales filtran: WHERE deleted_at IS NULL
 * - Las queries de sync incluyen tombstones para propagar eliminaciones
 * 
 * Reglas de conflicto:
 * 1. delete gana contra update antiguo
 * 2. updatedAt más reciente gana solo si ninguno está eliminado
 * 3. cloud deletedAt gana si es más reciente o si local no tiene cambios válidos posteriores
 */

const prisma = require('../lib/prisma');

const SYNC_STATUS = {
  SYNCED: 'synced',
  PENDING_CREATE: 'pending_create',
  PENDING_UPDATE: 'pending_update',
  PENDING_DELETE: 'pending_delete',
  CONFLICT: 'conflict',
};

/**
 * Obtiene todos los registros activos (no eliminados) de una tabla
 */
async function getActiveRecords(model, where = {}) {
  // Usar created_at como fallback si actualizado_en no existe
  const orderField = model.name === 'BotConversation' ? 'created_at' : 'actualizado_en';
  return model.findMany({
    where: {
      ...where,
      deleted_at: null,
      is_deleted: false,
    },
    orderBy: { [orderField]: 'desc' },
  });
}

/**
 * Obtiene todos los registros incluyendo eliminados (para sync)
 */
async function getAllRecordsForSync(model, where = {}, since = null) {
  const syncWhere = { ...where };
  const isConversation = model.name === 'BotConversation';
  const timeField = isConversation ? 'created_at' : 'actualizado_en';
  
  if (since) {
    syncWhere.OR = [
      { [timeField]: { gte: since } },
      { deleted_at: { gte: since } },
    ];
  }
  
  return model.findMany({
    where: syncWhere,
    orderBy: { [timeField]: 'desc' },
  });
}

/**
 * Soft delete: marca un registro como eliminado en lugar de borrarlo físicamente
 */
async function softDelete(model, idField, idValue, extraData = {}) {
  const now = new Date();
  return model.update({
    where: { [idField]: idValue },
    data: {
      deleted_at: now,
      is_deleted: true,
      sync_status: SYNC_STATUS.PENDING_DELETE,
      actualizado_en: now,
      ...extraData,
    },
  });
}

/**
 * Soft delete múltiple
 */
async function softDeleteMany(model, where, extraData = {}) {
  const now = new Date();
  return model.updateMany({
    where,
    data: {
      deleted_at: now,
      is_deleted: true,
      sync_status: SYNC_STATUS.PENDING_DELETE,
      actualizado_en: now,
      ...extraData,
    },
  });
}

/**
 * Restaurar un registro soft-deleteado (solo para casos especiales)
 */
async function restore(model, idField, idValue) {
  const now = new Date();
  return model.update({
    where: { [idField]: idValue },
    data: {
      deleted_at: null,
      is_deleted: false,
      sync_status: SYNC_STATUS.PENDING_UPDATE,
      actualizado_en: now,
    },
  });
}

/**
 * Resuelve conflictos entre un registro local y uno de cloud
 * 
 * Reglas:
 * 1. Si local está eliminado y cloud no -> subir eliminación
 * 2. Si cloud está eliminado y local no -> aplicar eliminación local
 * 3. Si ambos eliminados -> mantener eliminado
 * 4. Si local tiene update pendiente pero cloud eliminado -> gana delete
 * 5. Si cloud activo pero tombstone local más reciente -> subir delete
 * 6. Nunca restaurar automáticamente un registro eliminado
 */
function resolveConflict(localRecord, cloudRecord) {
  const localDeleted = localRecord?.is_deleted === true || localRecord?.deleted_at != null;
  const cloudDeleted = cloudRecord?.is_deleted === true || cloudRecord?.deleted_at != null;
  
  const localUpdatedAt = localRecord?.actualizado_en ? new Date(localRecord.actualizado_en).getTime() : 0;
  const cloudUpdatedAt = cloudRecord?.actualizado_en ? new Date(cloudRecord.actualizado_en).getTime() : 0;
  const localDeletedAt = localRecord?.deleted_at ? new Date(localRecord.deleted_at).getTime() : 0;
  const cloudDeletedAt = cloudRecord?.deleted_at ? new Date(cloudRecord.deleted_at).getTime() : 0;
  
  // Caso 1: Local eliminado, cloud no -> subir eliminación
  if (localDeleted && !cloudDeleted) {
    return { action: 'upload_delete', winner: 'local' };
  }
  
  // Caso 2: Cloud eliminado, local no -> aplicar eliminación local
  if (cloudDeleted && !localDeleted) {
    return { action: 'apply_delete', winner: 'cloud' };
  }
  
  // Caso 3: Ambos eliminados -> mantener eliminado
  if (localDeleted && cloudDeleted) {
    return { action: 'keep_deleted', winner: 'tie' };
  }
  
  // Caso 4: Conflicto update vs delete (local update, cloud delete)
  if (localRecord && !localDeleted && cloudDeleted) {
    // Gana delete siempre
    return { action: 'apply_delete', winner: 'cloud' };
  }
  
  // Caso 5: Cloud activo pero tombstone local más reciente
  if (!cloudDeleted && localDeleted && localDeletedAt > cloudUpdatedAt) {
    return { action: 'upload_delete', winner: 'local' };
  }
  
  // Caso 6: Ambos activos -> gana el más reciente
  if (!localDeleted && !cloudDeleted) {
    if (localUpdatedAt > cloudUpdatedAt) {
      return { action: 'upload_update', winner: 'local' };
    } else {
      return { action: 'apply_update', winner: 'cloud' };
    }
  }
  
  // Default: cloud gana
  return { action: 'apply_update', winner: 'cloud' };
}

/**
 * Procesa un lote de cambios de sincronización desde un dispositivo
 */
async function processSyncBatch(model, idField, changes, botId = null) {
  const results = [];
  const now = new Date();
  
  for (const change of changes) {
    try {
      const idValue = change[idField];
      const existingRecord = idValue ? await model.findUnique({ where: { [idField]: idValue } }) : null;
      
      // Determinar acción basada en sync_status
      switch (change.sync_status) {
        case SYNC_STATUS.PENDING_CREATE: {
          // Verificar si ya existe (por si es un duplicado)
          if (existingRecord) {
            // Ya existe, actualizar
            const { idField: _, sync_status, ...updateData } = change;
            await model.update({
              where: { [idField]: idValue },
              data: {
                ...updateData,
                sync_status: SYNC_STATUS.SYNCED,
                actualizado_en: now,
              },
            });
            results.push({ id: idValue, status: 'updated' });
          } else {
            // Crear nuevo
            const { sync_status, ...createData } = change;
            await model.create({
              data: {
                ...createData,
                sync_status: SYNC_STATUS.SYNCED,
                actualizado_en: now,
              },
            });
            results.push({ id: idValue, status: 'created' });
          }
          break;
        }
        
        case SYNC_STATUS.PENDING_UPDATE: {
          if (!existingRecord) {
            results.push({ id: idValue, status: 'not_found' });
            break;
          }
          
          // Resolver conflicto
          const conflict = resolveConflict(existingRecord, change);
          
          if (conflict.action === 'apply_update') {
            const { idField: _, sync_status, ...updateData } = change;
            await model.update({
              where: { [idField]: idValue },
              data: {
                ...updateData,
                sync_status: SYNC_STATUS.SYNCED,
                actualizado_en: now,
              },
            });
            results.push({ id: idValue, status: 'updated' });
          } else if (conflict.action === 'apply_delete') {
            // Cloud dice eliminado, aplicar
            await softDelete(model, idField, idValue);
            results.push({ id: idValue, status: 'deleted' });
          } else {
            results.push({ id: idValue, status: 'conflict_skipped' });
          }
          break;
        }
        
        case SYNC_STATUS.PENDING_DELETE: {
          if (!existingRecord) {
            results.push({ id: idValue, status: 'not_found' });
            break;
          }
          
          // Aplicar soft delete
          await softDelete(model, idField, idValue);
          results.push({ id: idValue, status: 'deleted' });
          break;
        }
        
        default: {
          results.push({ id: idValue, status: 'unknown_status' });
        }
      }
    } catch (error) {
      console.error(`[SyncService] Error processing change:`, error);
      results.push({ id: change[idField], status: 'error', error: error.message });
    }
  }
  
  return results;
}

/**
 * Obtiene cambios pendientes desde una fecha específica
 */
async function getPendingChanges(model, where = {}, since = null) {
  const isConversation = model.name === 'BotConversation';
  const timeField = isConversation ? 'created_at' : 'actualizado_en';
  
  const pendingWhere = {
    ...where,
    sync_status: {
      in: [SYNC_STATUS.PENDING_CREATE, SYNC_STATUS.PENDING_UPDATE, SYNC_STATUS.PENDING_DELETE],
    },
  };
  
  if (since) {
    pendingWhere[timeField] = { gte: since };
  }
  
  return model.findMany({
    where: pendingWhere,
    orderBy: { [timeField]: 'asc' },
  });
}

/**
 * Marca registros como sincronizados
 */
async function markAsSynced(model, ids, idField = 'id') {
  const now = new Date();
  return model.updateMany({
    where: { [idField]: { in: ids } },
    data: {
      sync_status: SYNC_STATUS.SYNCED,
      actualizado_en: now,
    },
  });
}

module.exports = {
  SYNC_STATUS,
  getActiveRecords,
  getAllRecordsForSync,
  softDelete,
  softDeleteMany,
  restore,
  resolveConflict,
  processSyncBatch,
  getPendingChanges,
  markAsSynced,
};
