const express = require('express');
const cors = require('cors');
require('dotenv').config();

const catalogoRoutes = require('./routes/catalogo.routes');
const storageRoutes = require('./routes/storage.routes');
const botClientRoutes = require('./routes/botClient.routes');
const botConversationRoutes = require('./routes/botConversation.routes');
const botQuotationRoutes = require('./routes/botQuotation.routes');

// Nuevas rutas multi-bot
const botRoutes = require('./routes/bot.routes');
const botCatalogoRoutes = require('./routes/botCatalogo.routes');
const botClientNestedRoutes = require('./routes/botClient.routes');
const botConversationNestedRoutes = require('./routes/botConversation.routes');
const botQuotationNestedRoutes = require('./routes/botQuotation.routes');
const botOrderRoutes = require('./routes/botOrder.routes');

// Rutas globales (sin botId obligatorio)
const orderRoutes = require('./routes/order.routes');
const quotationRoutes = require('./routes/quotation.routes');

const app = express();

app.use(cors());
app.use(express.json({ limit: '20mb' }));
app.use(express.urlencoded({ extended: true }));

// Health check para Docker
app.get('/api/health', (req, res) => {
  res.json({
    ok: true,
    message: 'Backend de FULLTECH_BOT funcionando correctamente',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

app.get('/', (req, res) => {
  res.redirect('/api/health');
});

// Rutas del catálogo y storage (se mantienen)
app.use('/api/catalogo', catalogoRoutes);
app.use('/api/storage', storageRoutes);
app.use('/catalogo', (req, res, next) => {
  req.url = `/file/catalogo${req.url}`;
  next();
}, storageRoutes);

// Rutas para bot (clientes, conversaciones, cotizaciones) - se mantienen
app.use('/api/bot/clients', botClientRoutes);
app.use('/api/bot/conversations', botConversationRoutes);
app.use('/api/bot/quotations', botQuotationRoutes);

// ===== NUEVAS RUTAS MULTI-BOT =====
// Gestión de bots
app.use('/api/bots', botRoutes);

// Rutas anidadas por botId
app.use('/api/bots/:botId/catalogo', botCatalogoRoutes);
app.use('/api/bots/:botId/clients', botClientNestedRoutes);
app.use('/api/bots/:botId/conversations', botConversationNestedRoutes);
app.use('/api/bots/:botId/quotations', botQuotationNestedRoutes);
app.use('/api/bots/:botId/orders', botOrderRoutes);

// ===== RUTAS GLOBALES (sin botId obligatorio) =====
app.use('/api/orders', (req, res, next) => {
  console.log('ORDERS ROUTE HIT', req.method, req.originalUrl);
  next();
}, orderRoutes);
app.use('/api/quotations', quotationRoutes);

// ===== MIDDLEWARE 404 JSON =====
// Captura cualquier ruta no definida y devuelve JSON en lugar de HTML
app.use((req, res) => {
  res.status(404).json({
    ok: false,
    message: `Ruta no encontrada: ${req.method} ${req.originalUrl}`,
  });
});

// ===== MIDDLEWARE GLOBAL DE ERRORES =====
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
