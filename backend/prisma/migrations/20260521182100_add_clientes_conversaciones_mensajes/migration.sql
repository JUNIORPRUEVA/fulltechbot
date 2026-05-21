-- CreateTable: clientes
CREATE TABLE "clientes" (
    "id" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "telefono" TEXT,
    "email" TEXT,
    "direccion" TEXT,
    "notas" TEXT,
    "estado" TEXT NOT NULL DEFAULT 'activo',
    "totalConversaciones" INTEGER NOT NULL DEFAULT 0,
    "totalCompras" INTEGER NOT NULL DEFAULT 0,
    "totalGastado" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "ultimaCompra" TIMESTAMP(3),
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizadoEn" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "clientes_pkey" PRIMARY KEY ("id")
);

-- CreateTable: conversaciones
CREATE TABLE "conversaciones" (
    "id" TEXT NOT NULL,
    "clienteId" TEXT NOT NULL,
    "estado" TEXT NOT NULL DEFAULT 'activa',
    "ultimoMensaje" TEXT,
    "mensajesNoLeidos" INTEGER NOT NULL DEFAULT 0,
    "ultimaActividad" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizadoEn" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "conversaciones_pkey" PRIMARY KEY ("id")
);

-- CreateTable: mensajes
CREATE TABLE "mensajes" (
    "id" TEXT NOT NULL,
    "conversacionId" TEXT NOT NULL,
    "contenido" TEXT NOT NULL,
    "remitente" TEXT NOT NULL DEFAULT 'cliente',
    "tipo" TEXT NOT NULL DEFAULT 'texto',
    "productoId" TEXT,
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mensajes_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "conversaciones" ADD CONSTRAINT "conversaciones_clienteId_fkey" FOREIGN KEY ("clienteId") REFERENCES "clientes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mensajes" ADD CONSTRAINT "mensajes_conversacionId_fkey" FOREIGN KEY ("conversacionId") REFERENCES "conversaciones"("id") ON DELETE CASCADE ON UPDATE CASCADE;
