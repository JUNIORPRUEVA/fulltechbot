const orderService = require('./order.service');

async function listarOrdenes(botId) {
  return orderService.listarOrdenes({ botId });
}

async function obtenerOrdenPorId(id) {
  return orderService.obtenerOrdenPorId(id);
}

async function crearOrden(data) {
  return orderService.crearOrden(data);
}

async function actualizarOrden(id, data) {
  return orderService.actualizarOrden(id, data);
}

async function cambiarEstado(id, estado) {
  return orderService.cambiarEstado(id, estado);
}

async function eliminarOrden(id) {
  return orderService.eliminarOrden(id);
}

module.exports = {
  listarOrdenes,
  obtenerOrdenPorId,
  crearOrden,
  actualizarOrden,
  cambiarEstado,
  eliminarOrden,
};
