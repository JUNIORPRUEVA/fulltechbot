const botOrderService = require('../services/botOrder.service');

async function listar(req, res) {
  try {
    const { botId } = req.params;
    const ordenes = await botOrderService.listarOrdenes(botId);
    res.json({
      ok: true,
      message: 'Órdenes listadas correctamente',
      data: ordenes,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al listar órdenes',
      error: error.message,
    });
  }
}

async function obtenerPorId(req, res) {
  try {
    const { botId, id } = req.params;
    const orden = await botOrderService.obtenerOrdenPorId(id, botId);

    if (!orden) {
      return res.status(404).json({
        ok: false,
        message: 'Orden no encontrada',
      });
    }

    res.json({
      ok: true,
      message: 'Orden encontrada',
      data: orden,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al obtener orden',
      error: error.message,
    });
  }
}

async function crear(req, res) {
  try {
    const { botId } = req.params;
    const data = req.body;

    if (!data.telefonoCliente && !data.telefono_cliente) {
      return res.status(400).json({
        ok: false,
        message: 'El telefono_cliente es obligatorio',
      });
    }

    // Normalizar campos: aceptar tanto snake_case como camelCase
    const normalizedData = {
      telefonoCliente: data.telefonoCliente || data.telefono_cliente,
      nombreCliente: data.nombreCliente || data.nombre_cliente || null,
      productoServicio: data.productoServicio || data.producto_servicio || null,
      tipoServicio: data.tipoServicio || data.tipo_servicio || 'otro',
      direccion: data.direccion || null,
      fechaDeseada: data.fechaDeseada || data.fecha_deseada || null,
      estadoPedido: data.estadoPedido || data.estado_pedido || 'pendiente',
      resumenPedido: data.resumenPedido || data.resumen_pedido || null,
      ubicacionGpsUrl: data.ubicacionGpsUrl || data.ubicacion_gps_url || null,
      botId,
    };

    const orden = await botOrderService.crearOrden(normalizedData);

    res.status(201).json({
      ok: true,
      message: 'Orden creada correctamente',
      data: orden,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al crear orden',
      error: error.message,
    });
  }
}

async function actualizar(req, res) {
  try {
    const { botId, id } = req.params;
    const data = req.body;

    // Normalizar campos
    const normalizedData = {
      ...data,
      telefonoCliente: data.telefonoCliente || data.telefono_cliente,
      nombreCliente: data.nombreCliente || data.nombre_cliente,
      productoServicio: data.productoServicio || data.producto_servicio,
      tipoServicio: data.tipoServicio || data.tipo_servicio,
      fechaDeseada: data.fechaDeseada || data.fecha_deseada,
      estadoPedido: data.estadoPedido || data.estado_pedido,
      resumenPedido: data.resumenPedido || data.resumen_pedido,
      ubicacionGpsUrl: data.ubicacionGpsUrl || data.ubicacion_gps_url,
    };

    const orden = await botOrderService.actualizarOrden(id, normalizedData, botId);

    if (!orden) {
      return res.status(404).json({
        ok: false,
        message: 'Orden no encontrada o no pertenece a este bot',
      });
    }

    res.json({
      ok: true,
      message: 'Orden actualizada correctamente',
      data: orden,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al actualizar orden',
      error: error.message,
    });
  }
}

async function cambiarEstado(req, res) {
  try {
    const { botId, id } = req.params;
    const { estado } = req.body;

    if (!estado) {
      return res.status(400).json({
        ok: false,
        message: 'El campo estado es obligatorio',
      });
    }

    const orden = await botOrderService.cambiarEstado(id, estado, botId);

    if (!orden) {
      return res.status(404).json({
        ok: false,
        message: 'Orden no encontrada o no pertenece a este bot',
      });
    }

    res.json({
      ok: true,
      message: `Estado actualizado a "${estado}" correctamente`,
      data: orden,
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      message: error.message,
    });
  }
}

async function eliminar(req, res) {
  try {
    const { botId, id } = req.params;
    const orden = await botOrderService.eliminarOrden(id, botId);

    if (!orden) {
      return res.status(404).json({
        ok: false,
        message: 'Orden no encontrada o no pertenece a este bot',
      });
    }

    res.json({
      ok: true,
      message: 'Orden eliminada correctamente',
      data: orden,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al eliminar orden',
      error: error.message,
    });
  }
}

module.exports = {
  listar,
  obtenerPorId,
  crear,
  actualizar,
  cambiarEstado,
  eliminar,
};
