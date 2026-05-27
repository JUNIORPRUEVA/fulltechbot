const storageService = require('../services/storage.service');

function construirBaseUrl(req) {
  const forwardedProto = req.headers['x-forwarded-proto'];
  const protocol = forwardedProto || req.protocol || 'https';

  return `${protocol}://${req.get('host')}`;
}

async function subirArchivo(req, res) {
  try {
    const resultado = await storageService.subirArchivo(req.file);
    const proxyUrl = `${construirBaseUrl(req)}/api/storage/file/${resultado.key}`;

    res.status(201).json({
      ok: true,
      message: 'Archivo subido correctamente',
      data: {
        ...resultado,
        url: resultado.url || proxyUrl,
        proxyUrl,
      },
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      message: error.message || 'Error al subir archivo',
    });
  }
}

async function obtenerArchivo(req, res) {
  try {
    const key = req.params[0];
    const archivo = await storageService.obtenerArchivo(key);

    res.setHeader('Content-Type', archivo.contentType);
    res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');

    if (archivo.contentLength) {
      res.setHeader('Content-Length', archivo.contentLength);
    }

    if (archivo.etag) {
      res.setHeader('ETag', archivo.etag);
    }

    if (archivo.lastModified) {
      res.setHeader('Last-Modified', new Date(archivo.lastModified).toUTCString());
    }

    archivo.body.pipe(res);
  } catch (error) {
    res.status(404).json({
      ok: false,
      message: error.message || 'Archivo no encontrado',
    });
  }
}

async function eliminarArchivo(req, res) {
  try {
    const { key } = req.body;

    await storageService.eliminarArchivo(key);

    res.json({
      ok: true,
      message: 'Archivo eliminado correctamente',
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      message: error.message || 'Error al eliminar archivo',
    });
  }
}

module.exports = {
  subirArchivo,
  obtenerArchivo,
  eliminarArchivo,
};
