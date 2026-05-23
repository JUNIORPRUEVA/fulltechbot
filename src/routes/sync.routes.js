const express = require('express');
const syncController = require('../controllers/sync.controller');

const router = express.Router();

router.post('/', syncController.sync);
router.get('/status', syncController.syncStatus);

module.exports = router;
