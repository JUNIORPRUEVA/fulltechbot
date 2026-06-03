-- ============================================
-- STOREFRONT POLICIES - Políticas de tienda
-- ============================================
CREATE TABLE IF NOT EXISTS public.storefront_policies (
  id BIGSERIAL PRIMARY KEY,
  bot_id TEXT NOT NULL,
  tipo TEXT NOT NULL,
  titulo TEXT NOT NULL,
  contenido TEXT,
  activo BOOLEAN DEFAULT true,
  creado_en TIMESTAMPTZ DEFAULT NOW(),
  actualizado_en TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (bot_id, tipo)
);

CREATE INDEX IF NOT EXISTS idx_storefront_policies_bot_id ON public.storefront_policies(bot_id);
CREATE INDEX IF NOT EXISTS idx_storefront_policies_tipo ON public.storefront_policies(tipo);

-- ============================================
-- AGREGAR CAMPOS FALTANTES A storefront_config
-- ============================================
ALTER TABLE public.storefront_config ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.storefront_config ADD COLUMN IF NOT EXISTS instagram TEXT;
ALTER TABLE public.storefront_config ADD COLUMN IF NOT EXISTS facebook TEXT;
ALTER TABLE public.storefront_config ADD COLUMN IF NOT EXISTS maps_url TEXT;
ALTER TABLE public.storefront_config ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
