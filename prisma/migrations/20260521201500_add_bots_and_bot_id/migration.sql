-- CreateTable: bots
CREATE TABLE IF NOT EXISTS "bots" (
    "id" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "descripcion" TEXT,
    "tipoNegocio" TEXT,
    "estado" TEXT NOT NULL DEFAULT 'activo',
    "promptBase" TEXT,
    "tono" TEXT,
    "instrucciones" TEXT,
    "reglasNegocio" TEXT,
    "instanciaWhatsapp" TEXT,
    "telefonoWhatsapp" TEXT,
    "apiKeyChatGPT" TEXT,
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizadoEn" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "bots_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "bots_slug_key" ON "bots"("slug");

-- Add bot_id column to catalogo (nullable initially)
ALTER TABLE "catalogo" ADD COLUMN IF NOT EXISTS "bot_id" TEXT;

-- Add bot_id column to bot_clients (nullable initially)
ALTER TABLE "bot_clients" ADD COLUMN IF NOT EXISTS "bot_id" TEXT;

-- Add bot_id column to bot_conversations (nullable initially)
ALTER TABLE "bot_conversations" ADD COLUMN IF NOT EXISTS "bot_id" TEXT;

-- Add bot_id column to bot_quotations (nullable initially)
ALTER TABLE "bot_quotations" ADD COLUMN IF NOT EXISTS "bot_id" TEXT;

-- Create indexes for bot_id
CREATE INDEX IF NOT EXISTS "idx_catalogo_bot_id" ON "catalogo"("bot_id");
CREATE INDEX IF NOT EXISTS "idx_bot_clients_bot_id" ON "bot_clients"("bot_id");
CREATE INDEX IF NOT EXISTS "idx_bot_conversations_bot_id" ON "bot_conversations"("bot_id");
CREATE INDEX IF NOT EXISTS "idx_bot_quotations_bot_id" ON "bot_quotations"("bot_id");

-- Add foreign keys (ON DELETE SET NULL to preserve data)
ALTER TABLE "catalogo" DROP CONSTRAINT IF EXISTS "catalogo_bot_id_fkey";
ALTER TABLE "catalogo" ADD CONSTRAINT "catalogo_bot_id_fkey" FOREIGN KEY ("bot_id") REFERENCES "bots"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "bot_clients" DROP CONSTRAINT IF EXISTS "bot_clients_bot_id_fkey";
ALTER TABLE "bot_clients" ADD CONSTRAINT "bot_clients_bot_id_fkey" FOREIGN KEY ("bot_id") REFERENCES "bots"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "bot_conversations" DROP CONSTRAINT IF EXISTS "bot_conversations_bot_id_fkey";
ALTER TABLE "bot_conversations" ADD CONSTRAINT "bot_conversations_bot_id_fkey" FOREIGN KEY ("bot_id") REFERENCES "bots"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "bot_quotations" DROP CONSTRAINT IF EXISTS "bot_quotations_bot_id_fkey";
ALTER TABLE "bot_quotations" ADD CONSTRAINT "bot_quotations_bot_id_fkey" FOREIGN KEY ("bot_id") REFERENCES "bots"("id") ON DELETE SET NULL ON UPDATE CASCADE;
