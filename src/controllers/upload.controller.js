const uploadService = require('../services/upload.service');

function construirBaseUrl(req) {
  const forwardedProto = req.headers['x-forwarded-proto'];
  const protocol = forwardedProto || req.protocol || 'https';

  return `${protocol}://${req.get('host')}`;
}

async function uploadImage(req, res) {
  try {
    const result = await uploadService.uploadImage(req.file, {
      folder: req.body.folder,
      context: req.body.context,
      botId: req.body.bot_id,
      baseUrl: construirBaseUrl(req),
    });

    res.status(201).json(result);
  } catch (error) {
    res.status(400).json({
      ok: false,
      message: error.message || 'No se pudo subir la imagen',
    });
  }
}

module.exports = {
  uploadImage,
};
