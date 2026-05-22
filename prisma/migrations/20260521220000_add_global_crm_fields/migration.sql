-- Migración segura: Agregar campos globales CRM
-- No borra datos existentes
-- No elimina columnas existentes

-- ===== bot_clients =====
ALTER TABLE bot_clients ADD COLUMN IF NOT EXISTS source_bot_id TEXT;
ALTER TABLE bot_clients ADD COLUMN IF NOT EXISTS ultima_instancia_whatsapp TEXT;
ALTER TABLE bot_clients ADD COLUMN IF NOT EXISTS origen TEXT;

-- ===== bot_orders =====
ALTER TABLE bot_orders ADD COLUMN IF NOT EXISTS source_bot_id TEXT;
ALTER TABLE bot_orders ADD COLUMN IF NOT EXISTS instancia_whatsapp TEXT;
ALTER TABLE bot_orders ADD COLUMN IF NOT EXISTS origen TEXT;
ALTER TABLE bot_orders ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

-- ===== bot_quotations =====
ALTER TABLE bot_quotations ADD COLUMN IF NOT EXISTS source_bot_id TEXT;
ALTER TABLE bot_quotations ADD COLUMN IF NOT EXISTS instancia_whatsapp TEXT;
ALTER TABLE bot_quotations ADD COLUMN IF NOT EXISTS origen TEXT;
