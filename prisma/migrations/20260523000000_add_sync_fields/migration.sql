-- Migración: Agregar campos de sincronización a todas las tablas
-- Esta migración agrega deleted_at, is_deleted, sync_status, updated_at donde falten

-- ============================================
-- 1. Tabla: catalogo
-- ============================================
ALTER TABLE catalogo 
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sync_status VARCHAR(20) NOT NULL DEFAULT 'synced',
  ADD COLUMN IF NOT EXISTS device_id VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_catalogo_deleted_at ON catalogo(deleted_at);
CREATE INDEX IF NOT EXISTS idx_catalogo_is_deleted ON catalogo(is_deleted);
CREATE INDEX IF NOT EXISTS idx_catalogo_sync_status ON catalogo(sync_status);

-- ============================================
-- 2. Tabla: bot_clients
-- ============================================
ALTER TABLE bot_clients 
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sync_status VARCHAR(20) NOT NULL DEFAULT 'synced',
  ADD COLUMN IF NOT EXISTS device_id VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_bot_clients_deleted_at ON bot_clients(deleted_at);
CREATE INDEX IF NOT EXISTS idx_bot_clients_is_deleted ON bot_clients(is_deleted);
CREATE INDEX IF NOT EXISTS idx_bot_clients_sync_status ON bot_clients(sync_status);

-- ============================================
-- 3. Tabla: bot_conversations
-- ============================================
ALTER TABLE bot_conversations 
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sync_status VARCHAR(20) NOT NULL DEFAULT 'synced',
  ADD COLUMN IF NOT EXISTS device_id VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_bot_conversations_deleted_at ON bot_conversations(deleted_at);
CREATE INDEX IF NOT EXISTS idx_bot_conversations_is_deleted ON bot_conversations(is_deleted);
CREATE INDEX IF NOT EXISTS idx_bot_conversations_sync_status ON bot_conversations(sync_status);

-- ============================================
-- 4. Tabla: bot_quotations
-- ============================================
ALTER TABLE bot_quotations 
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sync_status VARCHAR(20) NOT NULL DEFAULT 'synced',
  ADD COLUMN IF NOT EXISTS device_id VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_bot_quotations_deleted_at ON bot_quotations(deleted_at);
CREATE INDEX IF NOT EXISTS idx_bot_quotations_is_deleted ON bot_quotations(is_deleted);
CREATE INDEX IF NOT EXISTS idx_bot_quotations_sync_status ON bot_quotations(sync_status);

-- ============================================
-- 5. Tabla: bot_orders
-- ============================================
ALTER TABLE bot_orders 
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sync_status VARCHAR(20) NOT NULL DEFAULT 'synced',
  ADD COLUMN IF NOT EXISTS device_id VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_bot_orders_deleted_at ON bot_orders(deleted_at);
CREATE INDEX IF NOT EXISTS idx_bot_orders_is_deleted ON bot_orders(is_deleted);
CREATE INDEX IF NOT EXISTS idx_bot_orders_sync_status ON bot_orders(sync_status);

-- ============================================
-- 6. Tabla: bot_campaigns
-- ============================================
ALTER TABLE bot_campaigns 
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sync_status VARCHAR(20) NOT NULL DEFAULT 'synced',
  ADD COLUMN IF NOT EXISTS device_id VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_bot_campaigns_deleted_at ON bot_campaigns(deleted_at);
CREATE INDEX IF NOT EXISTS idx_bot_campaigns_is_deleted ON bot_campaigns(is_deleted);
CREATE INDEX IF NOT EXISTS idx_bot_campaigns_sync_status ON bot_campaigns(sync_status);

-- ============================================
-- 7. Tabla: conversation_campaign_context
-- ============================================
ALTER TABLE conversation_campaign_context 
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sync_status VARCHAR(20) NOT NULL DEFAULT 'synced',
  ADD COLUMN IF NOT EXISTS device_id VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_conv_campaign_deleted_at ON conversation_campaign_context(deleted_at);
CREATE INDEX IF NOT EXISTS idx_conv_campaign_is_deleted ON conversation_campaign_context(is_deleted);
CREATE INDEX IF NOT EXISTS idx_conv_campaign_sync_status ON conversation_campaign_context(sync_status);

-- ============================================
-- 8. Tabla: bots
-- ============================================
ALTER TABLE bots 
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sync_status VARCHAR(20) NOT NULL DEFAULT 'synced',
  ADD COLUMN IF NOT EXISTS device_id VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_bots_deleted_at ON bots(deleted_at);
CREATE INDEX IF NOT EXISTS idx_bots_is_deleted ON bots(is_deleted);
CREATE INDEX IF NOT EXISTS idx_bots_sync_status ON bots(sync_status);

-- ============================================
-- 9. Tabla: catalogo_kit_componentes (si existe)
-- ============================================
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'catalogo_kit_componentes') THEN
    ALTER TABLE catalogo_kit_componentes 
      ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
      ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false,
      ADD COLUMN IF NOT EXISTS sync_status VARCHAR(20) NOT NULL DEFAULT 'synced',
      ADD COLUMN IF NOT EXISTS device_id VARCHAR(100);
    
    CREATE INDEX IF NOT EXISTS idx_kit_componentes_deleted_at ON catalogo_kit_componentes(deleted_at);
    CREATE INDEX IF NOT EXISTS idx_kit_componentes_is_deleted ON catalogo_kit_componentes(is_deleted);
    CREATE INDEX IF NOT EXISTS idx_kit_componentes_sync_status ON catalogo_kit_componentes(sync_status);
  END IF;
END $$;
