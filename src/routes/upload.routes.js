const express = require('express');

const uploadController = require('../controllers/upload.controller');
const { uploadImageMiddleware } = require('../middleware/upload.middleware');

const router = express.Router();

router.post('/image', uploadImageMiddleware.single('image'), uploadController.uploadImage);

module.exports = router;
