# Deploy EasyPanel Web/PWA

## A. Diagnostico del problema actual

EasyPanel estaba intentando construir el repositorio con el Dockerfile del backend Node.js + Prisma. Ese flujo requiere `DATABASE_URL`, por eso el despliegue fallaba con `PrismaConfigEnvError: Cannot resolve environment variable: DATABASE_URL`.

Para la tienda web/PWA el servicio correcto no debe tocar Prisma ni depender del backend en build time.

## B. Estructura correcta

- Backend/API Node.js + Prisma: raiz del repositorio.
- Tienda Flutter Web/PWA: `frondend/`.

Servicios separados:

- Servicio PWA: construye `frondend/Dockerfile` y sirve `build/web` con Nginx en puerto `80`.
- Servicio backend: construye `Dockerfile` de la raiz y expone la API en puerto `3000`.

## C. Configuracion del servicio PWA en EasyPanel

Crear un servicio nuevo desde el mismo repositorio.

- Repositorio: este mismo repo.
- Rama: la que vayas a desplegar.
- Root Directory / Ruta de compilacion: `/frondend`
- Tipo de compilacion: `Dockerfile`
- Archivo: `Dockerfile`
- Puerto interno: `80`
- Dominio recomendado: `tienda.midominio.com`
- SSL: activado

Build args recomendados:

- `API_BASE_URL=https://api.midominio.com`

Notas:

- EasyPanel ya soporta Root Directory en este proyecto; tu captura muestra `Ruta de compilacion`.
- No necesitas `DATABASE_URL` para la PWA.

## D. Configuracion del servicio backend

- Root Directory / Ruta de compilacion: `/`
- Tipo de compilacion: `Dockerfile`
- Archivo: `Dockerfile`
- Puerto interno: `3000`
- Dominio recomendado: `api.midominio.com`

Variables necesarias:

- `DATABASE_URL=...`
- `NODE_ENV=production`
- `PORT=3000`

## E. Como probar localmente la PWA con Docker

Desde `frondend/`:

```bash
docker build -t fulltech-tienda-web .
docker run -p 8080:80 fulltech-tienda-web
```

Abrir:

```text
http://localhost:8080
```

Si quieres compilar contra una API publica concreta:

```bash
docker build -t fulltech-tienda-web --build-arg API_BASE_URL=https://api.midominio.com .
```

## F. Como verificar imagenes

- Abrir DevTools del navegador.
- Revisar la pestaña `Network`.
- Buscar respuestas `404` de imagenes.
- Validar mayusculas/minusculas exactas en rutas.
- Confirmar que no existan rutas `C:\`, `file://`, `localhost` o `/mnt/`.

Hallazgo real en este repo:

- No hay carpeta `frondend/assets/` en uso para la tienda.
- No encontre `Image.asset(...)` en la storefront.
- El problema principal de imagenes era el uso de rutas relativas del backend como `uploads/...` o `api/...` en algunos widgets, especialmente banners y carrito, que ahora se normalizan contra `ApiConfig.baseUrl`.

## G. Como conectar la PWA con el backend

La PWA lee la API desde:

```dart
const String.fromEnvironment('API_BASE_URL')
```

Compilacion recomendada:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://api.midominio.com
```

Para produccion:

- usar el dominio publico real del backend
- no usar `localhost`

## Root Directory vs fallback

### Opcion recomendada

Usar `Root Directory` = `/frondend` y `frondend/Dockerfile`.

### Si alguna vez no puedes usar Root Directory

Existe un Dockerfile alternativo en la raiz:

- Archivo: `Dockerfile.web`

Ese Dockerfile construye la PWA desde `frondend/` usando contexto raiz.
