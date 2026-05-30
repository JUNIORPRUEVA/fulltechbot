# FULLTECH BOT - Progreso de Tareas

## 🔧 FIX DEFINITIVO: Ruteo - La raíz del dominio debe abrir la tienda

### Problema original
Cuando el usuario entra a `https://fulltechrd.com`, NO se muestra la tienda. Se muestra el panel/admin o una pantalla incorrecta. Solo funciona si el usuario entra a `https://fulltechrd.com/#/tienda/fulltech-seguridad` o en modo incógnito.

### Causa raíz (2 problemas combinados)

**Problema 1 - Ruteo en Flutter (`app.dart`):**
Cuando el path es `/`, el router de Flutter llamaba a `PublicEntryScreen()` que intentaba resolver la tienda vía API (`/api/storefront/public/default`). Si la API no respondía rápido o no había tienda configurada, se quedaba en una pantalla de "cargando" o mostraba el panel admin como fallback.

**Problema 2 - Service Worker cacheando versión anterior:**
El Service Worker de Flutter (generado automáticamente) cacheaba el `index.html` y assets de la versión anterior de la app (FullTech Bot admin). Incluso después de desplegar la nueva versión, el SW seguía sirviendo la versión cacheada.

### Solución aplicada (6 archivos modificados + 1 creado)

#### 1. `frondend/lib/app.dart` - FIX en el router de Flutter
**CAUSA DEL PROBLEMA REAL:** La línea 37:
```dart
if (uri.path == '/' || uri.path == '/tienda') {
```
Redirigía a `PublicEntryScreen` que dependía de una API para resolver la tienda.

**SOLUCIÓN:** Ahora cuando el path es `/`, redirige DIRECTAMENTE a `StorefrontHomeScreen(slug: 'fulltech-seguridad')` sin depender de ninguna API:
```dart
if (uri.path == '/') {
  return _route(
    settings,
    const StorefrontHomeScreen(slug: 'fulltech-seguridad'),
  );
}
```

#### 2. `frondend/web/index.html` - Redirect ANTES de que Flutter cargue
Se agregó un script que se ejecuta inmediatamente al cargar la página (antes de que Flutter se inicialice) que:
- Detecta si el path es `/` y el hash está vacío
- Redirige inmediatamente a `/#/tienda/fulltech-seguridad`
- También desregistra Service Workers viejos y limpia caches

#### 3. `frondend/web/service_worker.js` - Service Worker desactivado
Se reescribió para que:
- Se desregistre a sí mismo al activarse
- Limpie todos los caches
- No intercepte ninguna petición
- Versión: `fulltech-sw-DISABLED`

#### 4. `frondend/web/clear-cache.html` - Página de limpieza (NUEVO)
Página accesible en `https://fulltechrd.com/clear-cache.html` que:
- Desregistra todos los Service Workers
- Limpia todos los caches del navegador
- Limpia localStorage de claves relacionadas con cache/routing
- Redirige automáticamente a la tienda después de limpiar

#### 5. `frondend/nginx.conf` - Headers anti-cache
- `index.html`, `clear-cache.html`, `service_worker.js`: `Cache-Control: no-store, no-cache, must-revalidate, private, max-age=0`
- `flutter_bootstrap.js`, `main.dart.js`: No cachear
- Assets estáticos con hash: Cache largo (30 días, immutable)

#### 6. `frondend/Dockerfile` - Compilar sin PWA
Se agregó `--pwa-strategy=none` al comando de build para que Flutter NO genere su propio service worker automático.

### Archivos modificados
| Archivo | Cambio |
|---------|--------|
| `frondend/lib/app.dart` | Ruta `/` redirige directo a la tienda sin API |
| `frondend/web/index.html` | Redirect inmediato + limpieza SW/caches |
| `frondend/web/service_worker.js` | SW desactivado que se autodestruye |
| `frondend/web/clear-cache.html` | **NUEVO** - Página de limpieza de cache |
| `frondend/nginx.conf` | Headers anti-cache agresivos |
| `frondend/Dockerfile` | `--pwa-strategy=none` en el build |

### Cómo desplegar
```bash
# 1. Hacer commit y push a GitHub (si usas EasyPanel)
git add .
git commit -m "Fix: ruteo raiz del dominio a la tienda + desactivar SW"
git push

# 2. O construir manualmente
cd frondend
flutter build web --release --pwa-strategy=none
docker build -t fulltech-frontend .
docker push fulltech-frontend  # o desplegar en tu servidor
```

### Cómo probar
1. Después de desplegar, abre `https://fulltechrd.com` en navegador NORMAL (no incógnito)
2. Debe redirigir automáticamente a `https://fulltechrd.com/#/tienda/fulltech-seguridad`
3. Si aún ves la versión anterior, visita `https://fulltechrd.com/clear-cache.html` para forzar limpieza
4. También puedes probar:
   - `https://fulltechrd.com/#/` → debe ir a la tienda
   - `https://fulltechrd.com/#/tienda/fulltech-seguridad` → debe ir a la tienda
   - `https://fulltechrd.com/#/login` → debe ir al login
   - `https://fulltechrd.com/#/admin` → debe ir al panel admin (con sesión)
