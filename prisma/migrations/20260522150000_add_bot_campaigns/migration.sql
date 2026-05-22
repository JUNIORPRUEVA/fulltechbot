-- Tabla de campañas por bot
CREATE TABLE IF NOT EXISTS bot_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bot_id TEXT NOT NULL,
  campaign_code TEXT NOT NULL,
  campaign_name TEXT NOT NULL,
  campaign_description TEXT,
  product_name TEXT,
  product_id TEXT,
  normal_price DOUBLE PRECISION DEFAULT 0,
  offer_price DOUBLE PRECISION DEFAULT 0,
  currency TEXT DEFAULT 'DOP',
  campaign_status TEXT DEFAULT 'activa',
  trigger_phrases JSONB DEFAULT '[]',
  keywords JSONB DEFAULT '[]',
  initial_message TEXT,
  agent_context TEXT,
  sales_instructions TEXT,
  negotiation_rules JSONB DEFAULT '{}',
  objection_handling JSONB DEFAULT '[]',
  closing_questions JSONB DEFAULT '[]',
  extra_camera_price DOUBLE PRECISION DEFAULT 0,
  minimum_extra_camera_price DOUBLE PRECISION DEFAULT 0,
  location_rules JSONB DEFAULT '{}',
  warranty_info TEXT,
  installation_info TEXT,
  media_urls JSONB DEFAULT '[]',
  crm_initial_status TEXT DEFAULT 'Nuevo interesado',
  crm_tag TEXT,
  priority INTEGER DEFAULT 0,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT uq_campaign_bot_code UNIQUE (bot_id, campaign_code)
);

CREATE INDEX idx_bot_campaigns_bot_id ON bot_campaigns(bot_id);
CREATE INDEX idx_bot_campaigns_active ON bot_campaigns(active);
CREATE INDEX idx_bot_campaigns_priority ON bot_campaigns(priority DESC);

ALTER TABLE bot_campaigns
  DROP CONSTRAINT IF EXISTS bot_campaigns_bot_id_fkey;

ALTER TABLE bot_campaigns
  ADD CONSTRAINT bot_campaigns_bot_id_fkey
  FOREIGN KEY (bot_id) REFERENCES bots(id) ON DELETE CASCADE ON UPDATE CASCADE;

-- Tabla de contexto de campaña detectada en conversaciones
CREATE TABLE IF NOT EXISTS conversation_campaign_context (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bot_id TEXT NOT NULL,
  conversation_id TEXT NOT NULL,
  customer_id TEXT,
  campaign_id UUID REFERENCES bot_campaigns(id) ON DELETE SET NULL,
  campaign_code TEXT,
  campaign_name TEXT,
  matched_keyword TEXT,
  matched_trigger_phrase TEXT,
  customer_message TEXT,
  detection_confidence DOUBLE PRECISION DEFAULT 0,
  source_channel TEXT DEFAULT 'whatsapp',
  status TEXT DEFAULT 'detectada',
  initial_message_sent_at TIMESTAMPTZ,
  last_response_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_conv_campaign_bot_id ON conversation_campaign_context(bot_id);
CREATE INDEX idx_conv_campaign_conversation_id ON conversation_campaign_context(conversation_id);
CREATE INDEX idx_conv_campaign_campaign_id ON conversation_campaign_context(campaign_id);
CREATE INDEX idx_conv_campaign_status ON conversation_campaign_context(status);
CREATE INDEX idx_conv_campaign_created_at ON conversation_campaign_context(created_at DESC);

ALTER TABLE conversation_campaign_context
  DROP CONSTRAINT IF EXISTS conversation_campaign_context_bot_id_fkey;

ALTER TABLE conversation_campaign_context
  ADD CONSTRAINT conversation_campaign_context_bot_id_fkey
  FOREIGN KEY (bot_id) REFERENCES bots(id) ON DELETE CASCADE ON UPDATE CASCADE;
