const {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  GetObjectCommand,
} = require('@aws-sdk/client-s3');
const crypto = require('crypto');
const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');

const LOCAL_UPLOADS_DIR = path.resolve(__dirname, '../../uploads');

function getStorageConfig() {
  return {
    endpoint: process.env.R2_ENDPOINT || process.env.STORAGE_ENDPOINT,
    accessKeyId: process.env.R2_ACCESS_KEY_ID || process.env.STORAGE_ACCESS_KEY_ID,
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY || process.env.STORAGE_SECRET_ACCESS_KEY,
    bucket: process.env.R2_BUCKET || process.env.STORAGE_BUCKET,
    publicUrl: process.env.R2_PUBLIC_URL || process.env.STORAGE_PUBLIC_URL || '',
  };
}

function hasRemoteStorage() {
  const config = getStorageConfig();

  return Boolean(
    config.endpoint &&
      config.accessKeyId &&
      config.secretAccessKey &&
      config.bucket,
  );
}

function createStorageClient() {
  const config = getStorageConfig();

  if (!hasRemoteStorage()) {
    return null;
  }

  return new S3Client({
    region: 'auto',
    endpoint: config.endpoint,
    credentials: {
      accessKeyId: config.accessKeyId,
      secretAccessKey: config.secretAccessKey,
    },
    forcePathStyle: true,
  });
}

function sanitizePathSegment(value, fallback = 'general') {
  const normalized = (value || '')
    .toString()
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9/_-]+/g, '-')
    .replace(/\/+/g, '/')
    .replace(/^\/+|\/+$/g, '');

  if (!normalized) {
    return fallback;
  }

  return normalized
    .split('/')
    .filter((segment) => segment && segment !== '.' && segment !== '..')
    .join('/');
}

function sanitizeFileName(name) {
  const baseName = path
    .basename(name || '')
    .replace(/[^\w.-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-+|-+$/g, '');

  return baseName || crypto.randomUUID();
}

function getExtensionFromMimeType(mimeType) {
  const map = {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/webp': '.webp',
    'image/gif': '.gif',
    'video/mp4': '.mp4',
    'video/webm': '.webm',
    'video/quicktime': '.mov',
  };

  return map[mimeType] || '';
}

function createSafeFileName({
  originalName,
  mimeType,
  folder,
  botId,
}) {
  const safeFolder = sanitizePathSegment(folder, 'catalogo/archivos');
  const safeBotId = sanitizePathSegment(botId, '');
  const timestamp = new Date().toISOString().replace(/[-:TZ.]/g, '').slice(0, 14);
  const random = crypto.randomBytes(3).toString('hex');
  const originalExtension = path.extname(originalName || '').toLowerCase();
  const extension = originalExtension || getExtensionFromMimeType(mimeType) || '';
  const fileName = `${timestamp}-${random}${sanitizeFileName(extension)}`;

  return safeBotId ? `${safeFolder}/${safeBotId}/${fileName}` : `${safeFolder}/${fileName}`;
}

function getDefaultFolderByMimeType(mimeType) {
  if (mimeType.startsWith('image/')) {
    return 'catalogo/imagenes';
  }

  if (mimeType.startsWith('video/')) {
    return 'catalogo/videos';
  }

  return 'catalogo/archivos';
}

function validateFile(file, options = {}) {
  if (!file) {
    throw new Error('No se recibio ningun archivo');
  }

  const allowedMimeTypes = options.allowedMimeTypes || [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    'video/mp4',
    'video/webm',
    'video/quicktime',
  ];

  if (!allowedMimeTypes.includes(file.mimetype)) {
    throw new Error(`Tipo de archivo no permitido: ${file.mimetype}`);
  }

  const maxSizeBytes = options.maxSizeBytes || 80 * 1024 * 1024;

  if (file.size > maxSizeBytes) {
    throw new Error(`El archivo supera el tamano maximo permitido de ${Math.round(maxSizeBytes / (1024 * 1024))}MB`);
  }
}

async function ensureLocalDirectory(filePath) {
  await fsp.mkdir(path.dirname(filePath), { recursive: true });
}

async function putObject({ key, buffer, contentType }) {
  const config = getStorageConfig();

  if (hasRemoteStorage()) {
    const storageClient = createStorageClient();
    const command = new PutObjectCommand({
      Bucket: config.bucket,
      Key: key,
      Body: buffer,
      ContentType: contentType,
    });

    await storageClient.send(command);

    return {
      storageMode: 'remote',
      url: config.publicUrl ? `${config.publicUrl.replace(/\/+$/, '')}/${key}` : key,
    };
  }

  const localPath = path.join(LOCAL_UPLOADS_DIR, key);
  await ensureLocalDirectory(localPath);
  await fsp.writeFile(localPath, buffer);

  return {
    storageMode: 'local',
    localPath,
    url: `/uploads/${key}`,
  };
}

function normalizarKeyArchivo(value) {
  if (!value) {
    return null;
  }

  const trimmedValue = value.toString().trim();

  if (!trimmedValue) {
    return null;
  }

  try {
    const parsedUrl = new URL(trimmedValue);
    const cleanPath = parsedUrl.pathname.replace(/^\/+/, '');

    if (!cleanPath) {
      return null;
    }

    if (cleanPath.startsWith('api/storage/file/')) {
      return cleanPath.replace(/^api\/storage\/file\//, '');
    }

    if (cleanPath.startsWith('uploads/')) {
      return cleanPath.replace(/^uploads\//, '');
    }

    return cleanPath;
  } catch (error) {
    return trimmedValue
      .replace(/^\/+/, '')
      .replace(/^api\/storage\/file\//, '')
      .replace(/^uploads\//, '');
  }
}

function getContentTypeFromKey(key) {
  const extension = path.extname(key || '').toLowerCase();
  const map = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
    '.gif': 'image/gif',
    '.mp4': 'video/mp4',
    '.webm': 'video/webm',
    '.mov': 'video/quicktime',
  };

  return map[extension] || 'application/octet-stream';
}

async function subirArchivo(file, options = {}) {
  validateFile(file, options);

  const folder = options.folder || getDefaultFolderByMimeType(file.mimetype);
  const key = createSafeFileName({
    originalName: file.originalname,
    mimeType: file.mimetype,
    folder,
    botId: options.botId,
  });

  const stored = await putObject({
    key,
    buffer: file.buffer,
    contentType: file.mimetype,
  });

  return {
    key,
    url: stored.url,
    mimeType: file.mimetype,
    size: file.size,
    originalName: file.originalname,
    storageMode: stored.storageMode,
  };
}

async function obtenerArchivo(keyOrUrl) {
  const config = getStorageConfig();
  const key = normalizarKeyArchivo(keyOrUrl);

  if (!key) {
    throw new Error('La key del archivo es obligatoria');
  }

  if (hasRemoteStorage()) {
    const storageClient = createStorageClient();
    const command = new GetObjectCommand({
      Bucket: config.bucket,
      Key: key,
    });

    const response = await storageClient.send(command);

    return {
      key,
      body: response.Body,
      contentType: response.ContentType || 'application/octet-stream',
      contentLength: response.ContentLength,
      etag: response.ETag,
      lastModified: response.LastModified,
    };
  }

  const localPath = path.join(LOCAL_UPLOADS_DIR, key);
  const stats = await fsp.stat(localPath);

  return {
    key,
    body: fs.createReadStream(localPath),
    contentType: getContentTypeFromKey(key),
    contentLength: stats.size,
    lastModified: stats.mtime,
  };
}

async function eliminarArchivo(keyOrUrl) {
  const config = getStorageConfig();
  const key = normalizarKeyArchivo(keyOrUrl);

  if (!key) {
    throw new Error('La key del archivo es obligatoria');
  }

  if (hasRemoteStorage()) {
    const storageClient = createStorageClient();
    const command = new DeleteObjectCommand({
      Bucket: config.bucket,
      Key: key,
    });

    await storageClient.send(command);
    return true;
  }

  const localPath = path.join(LOCAL_UPLOADS_DIR, key);
  await fsp.rm(localPath, { force: true });
  return true;
}

module.exports = {
  LOCAL_UPLOADS_DIR,
  hasRemoteStorage,
  subirArchivo,
  obtenerArchivo,
  eliminarArchivo,
  normalizarKeyArchivo,
};
