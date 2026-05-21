const express = require('express');
const multer = require('multer');

const storageController = require('../controllers/storage.controller');

const router = express.Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 80 * 1024 * 1024,
  },
});

router.post('/upload', upload.single('file'), storageController.subirArchivo);
router.delete('/delete', storageController.eliminarArchivo);

module.exports = router;