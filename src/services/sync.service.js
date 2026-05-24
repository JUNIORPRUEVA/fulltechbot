/**
 * SERVICIO DE SINCRONIZACIÓN - VERSIÓN CORREGIDA
 * 
 * IMPORTANTE: Los modelos actuales NO tienen campos deleted_at, is_deleted, sync_status.
 * Este servicio ahora usa delete físico y no asume campos que no existen en schema.prisma.
 * 
 * Tampoco usa updatedAt porque ningún modelo tiene ese campo.
 * Los modelos usan: actualizado_en, creado_en, created_at, updated_at según corresponda.
 * 
 * Si en el futuro se agregan estos campos al schema, se debe actualizar este servicio.
 */

const prisma = require('../lib/prisma');

/**
 * Obtiene todos los registros activos de una tabla
 * Sin filtrar por deleted_at/is_deleted porque esos campos NO existen
 */
async function getActiveRecords(model, where = {}) {
  return model.findMany({
    where,
    orderBy: { id: 'desc' },
  });
}

/**
 * Obtiene todos los registros para sync (sin filtros de soft delete)
 * No usa updatedAt porque ningún modelo tiene ese campo.
 */
async function getAllRecordsForSync(model, where = {}, since = null) {
  const syncWhere = { ...where };
  
  // Nota: No filtramos por updatedAt porque ningún modelo tiene ese campo.
  // Si se necesita filtro por fecha, usar el campo de fecha que corresponda al modelo.
  // Ej: actualizado_en, creado_en, created_at, updated_at
  if (since) {
    // Este filtro se debe adaptar según el modelo.
    // Por ahora se omite porque no sabemos qué campo de fecha usar genéricamente.
    console.log('[SyncService] since filter not applied - no generic date field available');
  }
  
  return model.findMany({
    where: syncWhere,
    orderBy: { id: 'desc' },
  });
}

/**
 * Elimina físicamente un registro (no hay soft delete disponible)
 */
async function hardDelete(model, idField, idValue) {
  return model.delete({
    where: { [idField]: idValue },
  });
}

/**
 * Procesa un lote de cambios de sincronización desde un dispositivo
 * Usa delete físico porque los modelos NO tienen campos de soft delete
 * 
 * IMPORTANTE: No usa sync_status porque ese campo NO existe en schema.prisma.
 * Los cambios se procesan según su contenido real.
 */
async function processSyncBatch(model, idField, changes, botId = null) {
  const results = [];
  
  for (const change of changes) {
    try {
      const idValue = change[idField];
      const existingRecord = idValue ? await model.findUnique({ where: { [idField]: idValue } }) : null;
      
      // Determinar acción basada en el contenido del cambio
      // Si tiene id y existe -> actualizar
      // Si tiene id y no existe -> crear
      // Si tiene flag explícito de eliminación -> eliminar
      const action = change._action || (existingRecord ? 'update' : 'create');
      
      switch (action) {
        case 'create': {
          if (existingRecord) {
            // Ya existe, actualizar
            const { [idField]: _, _action, ...updateData } = change;
            await model.update({
              where: { [idField]: idValue },
              data: updateData,
            });
            results.push({ id: idValue, status: 'updated' });
          } else {
            // Crear nuevo
            const { _action, ...createData } = change;
            await model.create({
              data: createData,
            });
            results.push({ id: idValue, status: 'created' });
          }
          break;
        }
        
        case 'update': {
          if (!existingRecord) {
            results.push({ id: idValue, status: 'not_found' });
            break;
          }
          
          const { [idField]: _, _action, ...updateData } = change;
          await model.update({
            where: { [idField]: idValue },
            data: updateData,
          });
          results.push({ id: idValue, status: 'updated' });
          break;
        }
        
        case 'delete': {
          if (!existingRecord) {
            results.push({ id: idValue, status: 'not_found' });
            break;
          }
          
          // Delete físico (no hay soft delete disponible)
          await model.delete({
            where: { [idField]: idValue },
          });
          results.push({ id: idValue, status: 'deleted' });
          break;
        }
        
        default: {
          results.push({ id: idValue, status: 'unknown_action' });
        }
      }
    } catch (error) {
      console.error(`[SyncService] Error processing change:`, error);
      results.push({ id: change[idField], status: 'error', error: error.message });
    }
  }
  
  return results;
}

module.exports = {
  getActiveRecords,
  getAllRecordsForSync,
  hardDelete,
  processSyncBatch,
};
