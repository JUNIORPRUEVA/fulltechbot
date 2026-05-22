-- ============================================================
-- SQL MANUAL: Crear tabla catalogo_kit_componentes
-- ============================================================
-- Esta tabla NO está en el schema de Prisma.
-- El backend la usa con SQL raw (src/services/catalogoKitComponente.service.js)
-- Ejecutar directamente en PostgreSQL antes de usar la funcionalidad de componentes del kit.
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo_kit_componentes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kit_id UUID NOT NULL REFERENCES catalogo(id) ON DELETE CASCADE,
    componente_id UUID NOT NULL REFERENCES catalogo(id) ON DELETE CASCADE,
    cantidad DOUBLE PRECISION NOT NULL DEFAULT 1,
    incluido BOOLEAN NOT NULL DEFAULT true,
    es_opcional BOOLEAN NOT NULL DEFAULT false,
    nota TEXT,
    orden INTEGER NOT NULL DEFAULT 0,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Un producto solo puede estar una vez en un kit
    CONSTRAINT uq_kit_componente UNIQUE (kit_id, componente_id)
);

-- Índices para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_kit_componentes_kit_id ON catalogo_kit_componentes(kit_id);
CREATE INDEX IF NOT EXISTS idx_kit_componentes_componente_id ON catalogo_kit_componentes(componente_id);

-- Trigger para actualizar actualizado_en automáticamente
CREATE OR REPLACE FUNCTION update_catalogo_kit_componentes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_catalogo_kit_componentes_updated_at ON catalogo_kit_componentes;
CREATE TRIGGER trg_catalogo_kit_componentes_updated_at
    BEFORE UPDATE ON catalogo_kit_componentes
    FOR EACH ROW
    EXECUTE FUNCTION update_catalogo_kit_componentes_updated_at();
