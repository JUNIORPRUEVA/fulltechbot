const express = require('express');
const cors = require('cors');
require('dotenv').config();

const catalogoRoutes = require('./routes/catalogo.routes');
const storageRoutes = require('./routes/storage.routes');
const botClientRoutes = require('./routes/botClient.routes');
const botConversationRoutes = require('./routes/botConversation.routes');
const botQuotationRoutes = require('./routes/botQuotation.routes');

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

// Nuevas rutas para bot (clientes, conversaciones, cotizaciones)
app.use('/api/bot/clients', botClientRoutes);
app.use('/api/bot/conversations', botConversationRoutes);
app.use('/api/bot/quotations', botQuotationRoutes);

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Servidor corriendo en puerto ${PORT}`);
});
