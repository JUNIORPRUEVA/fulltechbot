CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS bot_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bot_id TEXT NOT NULL,
  campaign_code TEXT NOT NULL,
  campaign_name TEXT NOT NULL,
  keywords JSONB NOT NULL DEFAULT '[]'::jsonb,
  trigger_phrases JSONB NOT NULL DEFAULT '[]'::jsonb,
  initial_message TEXT,
  campaign_context TEXT,
  media_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_campaign_bot_code UNIQUE (bot_id, campaign_code)
);

CREATE INDEX IF NOT EXISTS idx_bot_campaigns_bot_id ON bot_campaigns(bot_id);
CREATE INDEX IF NOT EXISTS idx_bot_campaigns_active ON bot_campaigns(active);

ALTER TABLE bot_campaigns
  DROP CONSTRAINT IF EXISTS bot_campaigns_bot_id_fkey;

ALTER TABLE bot_campaigns
  ADD CONSTRAINT bot_campaigns_bot_id_fkey
  FOREIGN KEY (bot_id) REFERENCES bots(id) ON DELETE CASCADE ON UPDATE CASCADE;

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

CREATE INDEX IF NOT EXISTS idx_conv_campaign_bot_id ON conversation_campaign_context(bot_id);
CREATE INDEX IF NOT EXISTS idx_conv_campaign_conversation_id ON conversation_campaign_context(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conv_campaign_campaign_id ON conversation_campaign_context(campaign_id);
CREATE INDEX IF NOT EXISTS idx_conv_campaign_status ON conversation_campaign_context(status);
CREATE INDEX IF NOT EXISTS idx_conv_campaign_created_at ON conversation_campaign_context(created_at DESC);

ALTER TABLE conversation_campaign_context
  DROP CONSTRAINT IF EXISTS conversation_campaign_context_bot_id_fkey;

ALTER TABLE conversation_campaign_context
  ADD CONSTRAINT conversation_campaign_context_bot_id_fkey
  FOREIGN KEY (bot_id) REFERENCES bots(id) ON DELETE CASCADE ON UPDATE CASCADE;
