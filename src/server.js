const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const catalogoRoutes = require('./routes/catalogo.routes');
const catalogoKitComponenteRoutes = require('./routes/catalogoKitComponente.routes');
const storageRoutes = require('./routes/storage.routes');
const uploadRoutes = require('./routes/upload.routes');

const botClientRoutes = require('./routes/botClient.routes');
const botConversationRoutes = require('./routes/botConversation.routes');
const botQuotationRoutes = require('./routes/botQuotation.routes');

const botRoutes = require('./routes/bot.routes');
const botCatalogoRoutes = require('./routes/botCatalogo.routes');
const botClientNestedRoutes = require('./routes/botClient.routes');
const botConversationNestedRoutes = require('./routes/botConversation.routes');
const botQuotationNestedRoutes = require('./routes/botQuotation.routes');
const botOrderRoutes = require('./routes/botOrder.routes');
const botCampaignRoutes = require('./routes/botCampaign.routes');
const campaignContextRoutes = require('./routes/campaignContext.routes');
const followupRoutes = require('./routes/followup.routes');

const orderRoutes = require('./routes/order.routes');
const quotationRoutes = require('./routes/quotation.routes');
const syncRoutes = require('./routes/sync.routes');
const storefrontRoutes = require('./routes/storefront.routes');

const app = express();
const BACKEND_VERSION = 'campaign-module-005-force-rebuild';

console.log(`FULLTECH BOT backend version: ${BACKEND_VERSION}`);

app.use(cors());
app.use(express.json({ limit: '20mb' }));
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.resolve(__dirname, '../uploads')));
app.use((req, res, next) => {
  console.log('[HTTP]', req.method, req.originalUrl);
  next();
});

app.get('/api/health', (req, res) => {
  res.json({
    ok: true,
    message: 'Backend de FULLTECH_BOT funcionando correctamente',
    version: BACKEND_VERSION,
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

app.get('/', (req, res) => {
  res.redirect('/api/health');
});

app.get('/api/debug/routes', (req, res) => {
  res.json({
    ok: true,
    message: 'Backend FULLTECH BOT activo',
    version: BACKEND_VERSION,
    routes: [
      'GET /api/orders',
      'POST /api/orders',
      'GET /api/quotations',
      'POST /api/quotations',
      'GET /api/bots',
      'GET /api/bots/:botId/campaigns',
      'POST /api/bots/:botId/campaigns/detect',
      'GET /api/conversations/:conversationId/campaign-context',
    ],
  });
});

app.use('/api/catalogo', catalogoRoutes);
app.use('/api/catalogo', catalogoKitComponenteRoutes);
app.use('/api/storage', storageRoutes);
app.use('/api/uploads', uploadRoutes);

app.use('/catalogo', (req, res, next) => {
  req.url = `/file/catalogo${req.url}`;
  next();
}, storageRoutes);

app.use('/api/bot/clients', botClientRoutes);
app.use('/api/bot/conversations', botConversationRoutes);
app.use('/api/bot/quotations', botQuotationRoutes);

app.use('/api/bots', botRoutes);
app.use('/api/bots/:botId/catalogo', botCatalogoRoutes);
app.use('/api/bots/:botId/clients', botClientNestedRoutes);
app.use('/api/bots/:botId/conversations', botConversationNestedRoutes);
app.use('/api/bots/:botId/quotations', botQuotationNestedRoutes);
app.use('/api/bots/:botId/orders', botOrderRoutes);
app.use('/api/bots/:botId/campaigns', botCampaignRoutes);
app.use('/api/bots/:botId/followups', followupRoutes);
app.use('/api', campaignContextRoutes);

app.use('/api/orders', (req, res, next) => {
  console.log('ORDERS ROUTE HIT', req.method, req.originalUrl);
  next();
}, orderRoutes);
app.use('/api/quotations', quotationRoutes);

// Ruta de sincronización entre dispositivos
app.use('/api/sync', syncRoutes);

// Storefront - Tienda online/PWA
app.use('/api/storefront', storefrontRoutes);

app.use((req, res) => {
  res.status(404).json({
    ok: false,
    message: `Ruta no encontrada: ${req.method} ${req.originalUrl}`,
  });
});

app.use((err, req, res, next) => {
  console.error('Error interno:', err);
  res.status(500).json({
    ok: false,
    message: err.message || 'Error interno del servidor',
  });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Servidor corriendo en puerto ${PORT}`);
});
