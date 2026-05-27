const path = require('path');

const storageService = require('./storage.service');
const { IMAGE_MIME_TYPES, MAX_IMAGE_SIZE_BYTES } = require('../middleware/upload.middleware');

function sanitizeFolder(value) {
  return (value || 'storefront/general')
    .toString()
    .trim()
    .replace(/\\/g, '/')
    .replace(/[^a-zA-Z0-9/_-]+/g, '-')
    .replace(/\/+/g, '/')
    .replace(/^\/+|\/+$/g, '') || 'storefront/general';
}

function sanitizeBotId(value) {
  return (value || '')
    .toString()
    .trim()
    .replace(/[^a-zA-Z0-9_-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function buildAbsoluteUrl(baseUrl, url) {
  if (!url) {
    return url;
  }

  if (/^https?:\/\//i.test(url)) {
    return url;
  }

  return `${baseUrl.replace(/\/+$/, '')}/${url.replace(/^\/+/, '')}`;
}

async function uploadImage(file, options = {}) {
  const folder = sanitizeFolder(options.folder);
  const botId = sanitizeBotId(options.botId);
  const context = (options.context || 'image').toString().trim();

  const result = await storageService.subirArchivo(file, {
    folder,
    botId,
    maxSizeBytes: MAX_IMAGE_SIZE_BYTES,
    allowedMimeTypes: IMAGE_MIME_TYPES,
  });

  return {
    ok: true,
    url: buildAbsoluteUrl(options.baseUrl || '', result.url),
    key: result.key,
    mimeType: result.mimeType,
    size: result.size,
    context,
    fileName: path.basename(result.key),
  };
}

module.exports = {
  uploadImage,
};
