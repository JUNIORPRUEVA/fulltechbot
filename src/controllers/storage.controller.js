const storageService = require('../services/storage.service');
const crypto = require('crypto');

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

async function obtenerImagenOptimizada(req, res) {
  try {
    const key = req.params[0];
    const width = clampInteger(req.query.w, 32, 2400);
    const height = clampInteger(req.query.h, 32, 2400);
    const quality = clampInteger(req.query.q, 35, 90) || 72;
    const requestedFormat = normalizeFormat(req.query.format);
    const fit = normalizeFit(req.query.fit);
    const archivo = await storageService.obtenerArchivoBuffer(key);
    const isTransformableImage = /^image\/(jpeg|jpg|png|webp)$/i.test(
      archivo.contentType || '',
    );

    if (!isTransformableImage || (!width && !height && !requestedFormat)) {
      setImageCacheHeaders(res, req.query.v);
      res.setHeader('Content-Type', archivo.contentType);
      if (archivo.contentLength) {
        res.setHeader('Content-Length', archivo.contentLength);
      }
      return res.end(archivo.body);
    }

    const format = requestedFormat || preferredImageFormat(req);
    const transformed = await storageService.transformarImagen(archivo.body, {
      width,
      height,
      quality,
      format,
      fit,
    });
    const etagSeed = `${archivo.etag || archivo.key}:${width || 0}:${
      height || 0
    }:${quality}:${format}:${fit}:${req.query.v || ''}`;

    setImageCacheHeaders(res, req.query.v);
    res.setHeader('Content-Type', transformed.contentType);
    res.setHeader('Content-Length', transformed.buffer.length);
    res.setHeader('ETag', `"${crypto.createHash('sha1').update(etagSeed).digest('hex')}"`);

    return res.end(transformed.buffer);
  } catch (error) {
    return res.status(404).json({
      ok: false,
      message: error.message || 'Imagen no encontrada',
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
  obtenerImagenOptimizada,
  eliminarArchivo,
};

function clampInteger(value, min, max) {
  const parsed = Number.parseInt(value, 10);
  if (Number.isNaN(parsed)) {
    return null;
  }

  return Math.min(Math.max(parsed, min), max);
}

function normalizeFormat(value) {
  const normalized = value?.toString().trim().toLowerCase();
  if (normalized === 'jpg') return 'jpeg';
  if (['jpeg', 'png', 'webp'].includes(normalized)) {
    return normalized;
  }
  return null;
}

function normalizeFit(value) {
  const normalized = value?.toString().trim().toLowerCase();
  if (['cover', 'contain', 'fill', 'inside', 'outside'].includes(normalized)) {
    return normalized;
  }
  return 'inside';
}

function preferredImageFormat(req) {
  const acceptHeader = req.get('accept') || '';
  if (acceptHeader.includes('image/webp')) {
    return 'webp';
  }
  return 'jpeg';
}

function setImageCacheHeaders(res, version) {
  if (version) {
    res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    return;
  }

  res.setHeader('Cache-Control', 'public, max-age=86400, stale-while-revalidate=604800');
}
