# 🚀 Despliegue en EasyPanel

## ⚠️ Diagnóstico del error

Tu error actual:

```
path "/etc/easypanel/projects/fulltech_bot/fulltechbot_app/code/backend" not found
```

**Causa**: Tienes EasyPanel configurado con `Build context = ./backend`, pero la carpeta `backend/` no existe en tu repositorio remoto de GitHub (aunque sí existe localmente).

**Solución**: Cambia la configuración en EasyPanel a:

| Campo | Valor |
|-------|-------|
| **Build context** | `./` (raíz del repositorio) |
| **Dockerfile path** | `./Dockerfile` |
| **Puerto interno** | `3000` |
| **Healthcheck path** | `/api/health` |

El `Dockerfile` en la raíz ya está preparado para copiar todo desde `backend/`.

## Estructura del Proyecto

```
FULLTECH_BOT/              ← Este es el repositorio en GitHub
├── Dockerfile             ← ✅ EasyPanel usará este (contexto raíz)
├── .dockerignore          ← Ignora frontend, .env, node_modules
├── backend/               ← Código del backend
│   ├── entrypoint.sh
│   ├── src/
│   ├── prisma/
│   ├── prisma.config.ts
│   └── package.json
├── frondend/              ← Frontend (ignorado por Docker)
└── .env.example
```

## Variables de Entorno en EasyPanel

| Variable | Descripción |
|----------|-------------|
| `PORT` | `3000` |
| `DATABASE_URL` | `postgres://usuario:password@host:5432/fulltech_bot?sslmode=disable` |
| `STORAGE_ENDPOINT` | Endpoint de Cloudflare R2 |
| `STORAGE_ACCESS_KEY_ID` | Access Key de R2 |
| `STORAGE_SECRET_ACCESS_KEY` | Secret Key de R2 |
| `STORAGE_BUCKET` | `fulltechbot` |
| `STORAGE_PUBLIC_URL` | URL pública del bucket R2 |

## Probar Localmente

```bash
# Desde la RAÍZ del proyecto
docker build -t fulltechbot-backend .
docker run -p 3000:3000 -e DATABASE_URL="postgres://..." fulltechbot-backend
curl http://localhost:3000/api/health
```

## Notas

- ✅ Migraciones automáticas al iniciar
- ✅ Usuario no-root por seguridad
- ✅ Health check cada 30s
- ✅ Sin docker-compose
- ✅ Frontend no incluido en la imagen
