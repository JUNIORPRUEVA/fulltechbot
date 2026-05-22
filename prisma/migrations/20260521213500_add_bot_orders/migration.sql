-- CreateTable: bot_orders
CREATE TABLE IF NOT EXISTS "bot_orders" (
    "id" TEXT NOT NULL,
    "bot_id" TEXT,
    "telefono_cliente" TEXT NOT NULL,
    "nombre_cliente" TEXT,
    "producto_servicio" TEXT,
    "tipo_servicio" TEXT DEFAULT 'otro',
    "direccion" TEXT,
    "fecha_deseada" TEXT,
    "estado_pedido" TEXT DEFAULT 'pendiente',
    "resumen_pedido" TEXT,
    "creado_en" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP,
    "actualizado_en" TIMESTAMP(3),

    CONSTRAINT "bot_orders_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "idx_bot_orders_bot_id" ON "bot_orders"("bot_id");
CREATE INDEX IF NOT EXISTS "idx_bot_orders_estado_pedido" ON "bot_orders"("estado_pedido");
CREATE INDEX IF NOT EXISTS "idx_bot_orders_telefono_cliente" ON "bot_orders"("telefono_cliente");

-- AddForeignKey
ALTER TABLE "bot_orders" DROP CONSTRAINT IF EXISTS "bot_orders_bot_id_fkey";
ALTER TABLE "bot_orders" ADD CONSTRAINT "bot_orders_bot_id_fkey" FOREIGN KEY ("bot_id") REFERENCES "bots"("id") ON DELETE SET NULL ON UPDATE CASCADE;
