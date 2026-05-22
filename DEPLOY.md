# Deploy en EasyPanel

## Configuracion recomendada

Usa el repositorio raiz y el `Dockerfile` de la raiz.

| Campo | Valor |
|-------|-------|
| Source | GitHub |
| Owner | Tu usuario u organizacion |
| Repository | El repo que realmente contiene estos cambios |
| Branch | La rama donde hiciste push de estos cambios |
| Build path | `/` |
| Builder | `Dockerfile` |
| Dockerfile file | `Dockerfile` |
| Internal port | `3000` |
| Healthcheck path | `/api/health` |

## Variables de entorno

Estas variables deben configurarse en la seccion `Entorno` de EasyPanel. No dependas de `build args` para esto.

| Variable | Ejemplo |
|----------|---------|
| `PORT` | `3000` |
| `NODE_ENV` | `production` |
| `DATABASE_URL` | `postgres://fulltech_bot:password@bot_db_pogres:5432/fulltech_bot?sslmode=disable` |
| `STORAGE_ENDPOINT` | `https://<account>.r2.cloudflarestorage.com` |
| `STORAGE_ACCESS_KEY_ID` | `...` |
| `STORAGE_SECRET_ACCESS_KEY` | `...` |
| `STORAGE_BUCKET` | `fulltechbot` |
| `STORAGE_PUBLIC_URL` | `https://<public-bucket-or-cdn-domain>` |

`STORAGE_PUBLIC_URL` debe ser la URL publica del bucket o del CDN de R2. No debe ser el dominio del backend en EasyPanel.

Si no tienes el bucket publico listo todavia, la app ya puede servir los archivos a traves del backend usando rutas como `/api/storage/file/<key>`. Aun asi, deja `STORAGE_PUBLIC_URL` bien configurada para evitar confusiones operativas.

## Lo que hace el contenedor

Al iniciar, el contenedor:

1. valida que `DATABASE_URL` exista
2. ejecuta `prisma migrate deploy` por defecto
3. inicia el servidor en `PORT`

Durante el build de la imagen se ejecuta `prisma generate`.

Si por alguna razon necesitas desactivar migraciones automaticas, define:

```bash
RUN_PRISMA_MIGRATIONS=false
```

## Verificacion rapida

Cuando el deploy termine, prueba:

```bash
curl https://tu-dominio/api/health
```

Debes recibir un JSON con `ok: true`.

Despues valida que existan las tablas nuevas:

```sql
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('bot_campaigns', 'conversation_campaign_context');
```

## Notas

- El frontend `frondend/` no entra en la imagen.
- El `Dockerfile` ya incluye `HEALTHCHECK`.
- La app corre como usuario `node`, no como root.
- Si EasyPanel sigue mostrando un `Dockerfile` con `RUN npx prisma generate` durante el build, entonces esta construyendo un commit viejo o un repositorio distinto.
