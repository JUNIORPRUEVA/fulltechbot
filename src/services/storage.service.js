const {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  GetObjectCommand,
} = require('@aws-sdk/client-s3');
const crypto = require('crypto');
const path = require('path');

const storageClient = new S3Client({
  region: 'auto',
  endpoint: process.env.STORAGE_ENDPOINT,
  credentials: {
    accessKeyId: process.env.STORAGE_ACCESS_KEY_ID,
    secretAccessKey: process.env.STORAGE_SECRET_ACCESS_KEY,
  },
  forcePathStyle: true,
});

function validarVariablesStorage() {
  const requiredVars = [
    'STORAGE_ENDPOINT',
    'STORAGE_ACCESS_KEY_ID',
    'STORAGE_SECRET_ACCESS_KEY',
    'STORAGE_BUCKET',
  ];

  const missingVars = requiredVars.filter((name) => !process.env[name]);

  if (missingVars.length > 0) {
    throw new Error(`Faltan variables de storage: ${missingVars.join(', ')}`);
  }
}

function crearNombreSeguro(originalName) {
  const extension = path.extname(originalName || '').toLowerCase();
  const nombreUnico = crypto.randomUUID();

  return `${nombreUnico}${extension}`;
}

function obtenerCarpetaPorMimeType(mimeType) {
  if (mimeType.startsWith('image/')) {
    return 'catalogo/imagenes';
  }

  if (mimeType.startsWith('video/')) {
    return 'catalogo/videos';
  }

  return 'catalogo/archivos';
}

function validarArchivo(file) {
  if (!file) {
    throw new Error('No se recibió ningún archivo');
  }

  const tiposPermitidos = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    'video/mp4',
    'video/webm',
    'video/quicktime',
  ];

  if (!tiposPermitidos.includes(file.mimetype)) {
    throw new Error(`Tipo de archivo no permitido: ${file.mimetype}`);
  }

  const maxSizeBytes = 80 * 1024 * 1024;

  if (file.size > maxSizeBytes) {
    throw new Error('El archivo supera el tamaño máximo permitido de 80MB');
  }
}

async function subirArchivo(file) {
  validarVariablesStorage();
  validarArchivo(file);

  const carpeta = obtenerCarpetaPorMimeType(file.mimetype);
  const year = new Date().getFullYear();
  const nombreSeguro = crearNombreSeguro(file.originalname);

  const key = `${carpeta}/${year}/${nombreSeguro}`;

  const command = new PutObjectCommand({
    Bucket: process.env.STORAGE_BUCKET,
    Key: key,
    Body: file.buffer,
    ContentType: file.mimetype,
  });

  await storageClient.send(command);

  const publicBaseUrl = process.env.STORAGE_PUBLIC_URL;

  return {
    key,
    url: publicBaseUrl ? `${publicBaseUrl}/${key}` : key,
    mimeType: file.mimetype,
    size: file.size,
    originalName: file.originalname,
  };
}

function normalizarKeyArchivo(value) {
  if (!value) {
    return null;
  }

  const trimmedValue = value.trim();

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

    return cleanPath;
  } catch (error) {
    return trimmedValue.replace(/^\/+/, '');
  }
}

async function obtenerArchivo(keyOrUrl) {
  validarVariablesStorage();

  const key = normalizarKeyArchivo(keyOrUrl);

  if (!key) {
    throw new Error('La key del archivo es obligatoria');
  }

  const command = new GetObjectCommand({
    Bucket: process.env.STORAGE_BUCKET,
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

async function eliminarArchivo(key) {
  validarVariablesStorage();

  const normalizedKey = normalizarKeyArchivo(key);

  if (!normalizedKey) {
    throw new Error('La key del archivo es obligatoria');
  }

  const command = new DeleteObjectCommand({
    Bucket: process.env.STORAGE_BUCKET,
    Key: normalizedKey,
  });

  await storageClient.send(command);

  return true;
}

module.exports = {
  subirArchivo,
  obtenerArchivo,
  eliminarArchivo,
  normalizarKeyArchivo,
};
