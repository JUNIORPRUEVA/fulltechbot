# Routing Public/Admin Fix

## Problema original

La app mezclaba la entrada publica con el panel administrativo:

- La raiz `/` dependia solo de `DEFAULT_STOREFRONT_SLUG` en frontend.
- Si esa variable no resolvia bien, la experiencia publica caia en una pantalla de espera o en flujos administrativos.
- `/admin` usaba una compuerta incrustada, no un login independiente ni una proteccion clara por rutas.
- No existia un resolvedor backend para detectar la tienda publica activa cuando ya habia una tienda valida.

## Rutas publicas

- `/`
  - Resuelve la tienda publica activa y redirige a `/tienda/:slug`.
  - Si no existe tienda activa, muestra una landing publica con CTA a login admin.
- `/tienda`
  - Igual que `/`.
- `/tienda/:slug`
  - Abre la tienda publica por slug.
- `/producto/:id`
  - Resuelve la tienda publica activa y redirige a `/tienda/:slug/producto/:id`.
- `/tienda/:slug/producto/:id`
  - Abre el detalle publico del producto.
- `/carrito`
  - Resuelve la tienda publica activa y redirige a `/tienda/:slug/carrito`.
- `/checkout`
  - Resuelve la tienda publica activa y redirige a `/tienda/:slug/checkout`.

## Rutas de autenticacion

- `/login`
  - Login administrativo.
- `/admin/login`
  - Alias del login admin.

## Rutas protegidas

- `/admin`
- `/admin/bots`
- `/admin/tienda`
- `/admin/catalogo`
- `/admin/productos`
- `/admin/banners`
- `/admin/pedidos`
- `/admin/clientes`
- `/admin/pagos`

Todas pasan por `AdminRouteGuard`. Si no hay sesion, redirigen a `/login?redirect=...`.

## Como funciona el login

- El login usa `AdminLoginScreen`.
- La sesion se persiste en `SharedPreferences` con `AdminSessionService`.
- Si el usuario ya esta autenticado y entra a `/login`, se redirige al destino pedido o a `/admin`.
- Si no existe backend de auth conectado, la implementacion temporal usa `ADMIN_USERNAME` y `ADMIN_PASSWORD` por `--dart-define`.
- Esta compuerta temporal protege la UI, pero no sustituye un backend/token real.

## Como funciona el AuthGuard

- `AdminRouteGuard` valida sesion antes de pintar cualquier ruta `/admin`.
- Sin sesion:
  - redirige a `/login`
  - conserva la ruta de retorno con `redirect`
- Con sesion:
  - deja pasar a la vista protegida

## Como se define la tienda publica por defecto

Se agrego un resolvedor backend en `GET /api/storefront/public/default` con esta prioridad:

1. `slug` solicitado explicitamente.
2. `DEFAULT_STOREFRONT_SLUG` del backend, si existe y esta activo.
3. Una unica tienda activa.
4. Entre varias tiendas activas, la mas consistente segun:
   - bot activo
   - productos visibles en storefront
   - fecha de actualizacion

Esto evita mostrar "No hay una tienda publica por defecto configurada todavia" cuando si hay una tienda activa utilizable.

## Como acceder al admin

- Desde la tienda publica:
  - boton visible `Iniciar sesion` en desktop/tablet
  - opcion `Iniciar sesion` dentro del menu hamburguesa en movil
- Directo por URL:
  - `/login`
  - `/admin/login`

## Como abrir la tienda publica

- Cliente final:
  - `/`
  - `/#/`
  - `/tienda/:slug`
- Desde admin:
  - el boton `Ver tienda online` abre `/` si la tienda actual coincide con la publica por defecto
  - si no coincide, abre `/tienda/:slug`

## Como probar en local

1. Backend:
   - iniciar la API y confirmar `GET /api/storefront/public/default`
2. Frontend:
   - ejecutar `flutter run -d chrome`
3. Probar:
   - `/#/`
   - `/#/admin`
   - `/#/login`
   - `/#/tienda/<slug>`

## Como probar desplegado en EasyPanel

- Si mantienes Flutter Web con hash routes, deben funcionar:
  - `/#/`
  - `/#/tienda/<slug>`
  - `/#/login`
  - `/#/admin`
- Si luego migras a `PathUrlStrategy`, en Nginx debes servir siempre `index.html`:
  - `try_files $uri $uri/ /index.html;`
- Define variables recomendadas:
  - `API_BASE_URL`
  - `STORAGE_PUBLIC_URL`
  - `ADMIN_USERNAME`
  - `ADMIN_PASSWORD`
  - `DEFAULT_STOREFRONT_SLUG` opcional

## Archivos principales tocados

- `src/services/storefront.service.js`
- `src/controllers/storefront.controller.js`
- `src/routes/storefront.routes.js`
- `frondend/lib/app.dart`
- `frondend/lib/features/public/screens/public_entry_screen.dart`
- `frondend/lib/features/public/screens/public_store_redirect_screen.dart`
- `frondend/lib/features/public/services/public_store_service.dart`
- `frondend/lib/features/public/widgets/public_store_layout.dart`
- `frondend/lib/features/auth/screens/admin_login_screen.dart`
- `frondend/lib/features/auth/widgets/admin_route_guard.dart`
- `frondend/lib/features/storefront/screens/storefront_home_screen.dart`
- `frondend/lib/features/storefront_admin/screens/storefront_admin_screen.dart`
- `frondend/lib/features/bots/pages/bot_dashboard_page.dart`
- `frondend/test/widget_test.dart`
