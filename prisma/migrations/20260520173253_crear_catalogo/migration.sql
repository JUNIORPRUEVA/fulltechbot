-- CreateTable
CREATE TABLE "catalogo" (
    "id" TEXT NOT NULL,
    "titulo" TEXT NOT NULL,
    "categoria" TEXT NOT NULL,
    "descripcion" TEXT,
    "informacion" TEXT,
    "precio" DOUBLE PRECISION NOT NULL,
    "precioMinimo" DOUBLE PRECISION,
    "precioOferta" DOUBLE PRECISION,
    "stock" INTEGER NOT NULL DEFAULT 0,
    "imagen1" TEXT,
    "imagen2" TEXT,
    "imagen3" TEXT,
    "video" TEXT,
    "palabrasClave" TEXT,
    "reglasNegociacion" TEXT,
    "estado" TEXT NOT NULL DEFAULT 'activo',
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizadoEn" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "catalogo_pkey" PRIMARY KEY ("id")
);
