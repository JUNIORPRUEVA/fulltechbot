const multer = require('multer');

const IMAGE_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024;

const uploadImageMiddleware = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: MAX_IMAGE_SIZE_BYTES,
  },
  fileFilter: (req, file, cb) => {
    if (!IMAGE_MIME_TYPES.includes(file.mimetype)) {
      cb(new Error('Solo se permiten imagenes PNG, JPG o WEBP'));
      return;
    }

    cb(null, true);
  },
});

module.exports = {
  IMAGE_MIME_TYPES,
  MAX_IMAGE_SIZE_BYTES,
  uploadImageMiddleware,
};
