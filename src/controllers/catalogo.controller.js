const catalogoService = require('../services/catalogo.service');
const storageService = require('../services/storage.service');

function construirBaseUrl(req) {
  const forwardedProto = req.headers['x-forwarded-proto'];
  const protocol = forwardedProto || req.protocol || 'https';

  return `${protocol}://${req.get('host')}`;
}

function normalizarMediaUrl(req, value) {
  if (!value || typeof value !== 'string') {
    return value;
  }

  const trimmedValue = value.trim();

  if (!trimmedValue) {
    return null;
  }

  if (/^https?:\/\//i.test(trimmedValue)) {
    return trimmedValue;
  }

  const key = storageService.normalizarKeyArchivo(trimmedValue);

  return key ? `${construirBaseUrl(req)}/api/storage/file/${key}` : trimmedValue;
}

function normalizarProducto(req, producto) {
  if (!producto) {
    return producto;
  }

  return {
    ...producto,
    imagen1: normalizarMediaUrl(req, producto.imagen1),
    imagen2: normalizarMediaUrl(req, producto.imagen2),
    imagen3: normalizarMediaUrl(req, producto.imagen3),
    video: normalizarMediaUrl(req, producto.video),
  };
}

function validarProducto(data) {
  if (!data.titulo || String(data.titulo).trim() === '') {
    return 'El titulo es obligatorio';
  }

  if (!data.categoria || String(data.categoria).trim() === '') {
    return 'La categoria es obligatoria';
  }

  if (data.precio === undefined || data.precio === null || data.precio === '') {
    return 'El precio es obligatorio';
  }

  if (Number.isNaN(Number(data.precio)) || Number(data.precio) <= 0) {
    return 'El precio debe ser un numero mayor que 0';
  }

  if (
    data.precioMinimo !== undefined &&
    data.precioMinimo !== '' &&
    Number(data.precioMinimo) < 0
  ) {
    return 'El precio minimo no puede ser negativo';
  }

  if (
    data.precioOferta !== undefined &&
    data.precioOferta !== '' &&
    Number(data.precioOferta) < 0
  ) {
    return 'El precio de oferta no puede ser negativo';
  }

  if (
    data.stock !== undefined &&
    data.stock !== '' &&
    Number(data.stock) < 0
  ) {
    return 'El stock no puede ser negativo';
  }

  return null;
}

async function listar(req, res) {
  try {
    const botId = req.query.botId || req.params.botId || null;
    const productos = await catalogoService.listarCatalogo(botId);

    res.json({
      ok: true,
      message: 'Catalogo listado correctamente',
      data: productos.map((producto) => normalizarProducto(req, producto)),
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al listar el catalogo',
      error: error.message,
    });
  }
}

async function listarActivos(req, res) {
  try {
    const botId = req.query.botId || req.params.botId || null;
    const productos = await catalogoService.listarCatalogoActivo(botId);

    res.json({
      ok: true,
      message: 'Catalogo activo listado correctamente',
      data: productos.map((producto) => normalizarProducto(req, producto)),
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al listar productos activos',
      error: error.message,
    });
  }
}

async function obtenerPorId(req, res) {
  try {
    const { id } = req.params;

    const producto = await catalogoService.obtenerProductoPorId(id);

    if (!producto) {
      return res.status(404).json({
        ok: false,
        message: 'Producto no encontrado',
      });
    }

    res.json({
      ok: true,
      message: 'Producto encontrado',
      data: normalizarProducto(req, producto),
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al obtener producto',
      error: error.message,
    });
  }
}

async function crear(req, res) {
  try {
    const data = req.body;
    // Si viene de ruta anidada, asignar botId automáticamente
    if (req.params.botId) {
      data.bot_id = req.params.botId;
    }

    const errorValidacion = validarProducto(data);

    if (errorValidacion) {
      return res.status(400).json({
        ok: false,
        message: errorValidacion,
      });
    }

    const producto = await catalogoService.crearProducto(data);

    res.status(201).json({
      ok: true,
      message: 'Producto creado correctamente',
      data: normalizarProducto(req, producto),
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al crear producto',
      error: error.message,
    });
  }
}

async function actualizar(req, res) {
  try {
    const { id } = req.params;
    const data = req.body;

    const existe = await catalogoService.obtenerProductoPorId(id);

    if (!existe) {
      return res.status(404).json({
        ok: false,
        message: 'Producto no encontrado',
      });
    }

    const errorValidacion = validarProducto(data);

    if (errorValidacion) {
      return res.status(400).json({
        ok: false,
        message: errorValidacion,
      });
    }

    const producto = await catalogoService.actualizarProducto(id, data);

    res.json({
      ok: true,
      message: 'Producto actualizado correctamente',
      data: normalizarProducto(req, producto),
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al actualizar producto',
      error: error.message,
    });
  }
}

async function cambiarEstado(req, res) {
  try {
    const { id } = req.params;
    const { estado } = req.body;

    const estadosPermitidos = ['activo', 'inactivo', 'agotado'];

    if (!estado || !estadosPermitidos.includes(estado)) {
      return res.status(400).json({
        ok: false,
        message: 'Estado invalido. Usa: activo, inactivo o agotado',
      });
    }

    const existe = await catalogoService.obtenerProductoPorId(id);

    if (!existe) {
      return res.status(404).json({
        ok: false,
        message: 'Producto no encontrado',
      });
    }

    const producto = await catalogoService.cambiarEstadoProducto(id, estado);

    res.json({
      ok: true,
      message: 'Estado actualizado correctamente',
      data: normalizarProducto(req, producto),
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al cambiar estado',
      error: error.message,
    });
  }
}

async function eliminar(req, res) {
  try {
    const { id } = req.params;

    const existe = await catalogoService.obtenerProductoPorId(id);

    if (!existe) {
      return res.status(404).json({
        ok: false,
        message: 'Producto no encontrado',
      });
    }

    await catalogoService.eliminarProducto(id);

    res.json({
      ok: true,
      message: 'Producto eliminado correctamente',
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al eliminar producto',
      error: error.message,
    });
  }
}

module.exports = {
  listar,
  listarActivos,
  obtenerPorId,
  crear,
  actualizar,
  cambiarEstado,
  eliminar,
};
