# PLAN DE MIGRACIÓN: ADMINISTRACIÓN DE TIENDA AL PANEL PRINCIPAL

## ESTADO: COMPLETADO ✅

### AUDITORÍA COMPLETA

#### Estado Inicial:
1. **Ruta `/admin/tienda`** en `app.dart` → renderizaba `StorefrontAdminScreen`
2. **`StorefrontAdminScreen`** en `frondend/lib/features/storefront_admin/screens/storefront_admin_screen.dart` (1254 líneas)
   - Tabs: Configuración, Banners, Productos, Carritos, Pagos
   - Usaba `StorefrontApiService` para llamadas admin
   - Dependía de `BotProvider` para obtener botId
3. **Backend**: Rutas admin en `/api/storefront/admin/:botId/*` (storefront.routes.js)
   - Config: GET/PUT
   - Banners: CRUD
   - Product Settings: GET/PUT
   - Carts: GET
   - Payments: GET
   - Delivery Zones: CRUD
4. **Sidebar/Drawer** en `bot_dashboard_page.dart`:
   - Drawer: "Tienda Online" → navegaba a `/admin/tienda`
   - Sidebar: "Tienda Online" → navegaba a `/admin/tienda`
5. **Footer** en `storefront_footer.dart`: valores hardcodeados
6. **No había módulo de Políticas** en el admin
7. **No había módulo PWA** en el admin
8. **No había endpoints de políticas** en el backend

## IMPLEMENTACIÓN REALIZADA

### FASE 1: Backend - Endpoints faltantes ✅
- [x] Crear tabla storefront_policies en BD (scripts/sql/crear_tabla_storefront_policies.sql)
- [x] Agregar endpoints CRUD para políticas en storefront.routes.js
- [x] Agregar endpoints públicos para políticas
- [x] Agregar campos faltantes a storefront_config (email, instagram, facebook, maps_url, horario, mensaje_principal)

### FASE 2: Frontend Admin - Nuevo módulo Tienda en el panel principal ✅
- [x] Crear `StoreAdminScreen` - Contenedor principal con tabs internas
- [x] Crear `StoreConfigScreen` - Configuración de tienda (nombre, slug, descripción, logo, WhatsApp, teléfono, email, Instagram, Facebook, dirección, Google Maps URL, horario, mensaje principal, estado activo/inactivo)
- [x] Crear `StoreBannersScreen` - Gestión de banners (CRUD, activar/desactivar, orden)
- [x] Crear `StoreCartsScreen` - Gestión de carritos (filtros por estado, detalle, WhatsApp)
- [x] Crear `StorePaymentsScreen` - Gestión de pagos
- [x] Crear `StorePoliciesScreen` - Gestión de políticas (privacidad, términos, garantía, envío, devoluciones, contacto)
- [x] Crear `StoreAdminApiService` - Servicio API con autenticación
- [x] Crear `StoreAdminProvider` - Provider con estados loading/error

### FASE 3: Integración en el panel principal ✅
- [x] Agregar "Tienda" como sección en el drawer de BotDashboardPage
- [x] Agregar "Tienda" como sección en el sidebar de BotDashboardPage
- [x] Conectar navegación desde el menú principal a `/admin/tienda`
- [x] Registrar `StoreAdminProvider` en `main.dart`

### FASE 4: Eliminar ruta /admin/tienda de la tienda pública ✅
- [x] Eliminar ruta `/admin/tienda` de `app.dart` (ruta pública)
- [x] Redirigir a `/` si alguien intenta acceder desde la tienda pública
- [x] Eliminar import de `StorefrontAdminScreen` de `app.dart`
- [x] La ruta `/admin/tienda` ahora solo existe dentro del panel admin protegido

### FASE 5: Actualizar footer para usar datos dinámicos ✅
- [x] `StorefrontFooter` ya usa datos desde `StorefrontApiService.getConfig()`
- [x] Eliminar valores hardcodeados del footer
- [x] Footer muestra: dirección, WhatsApp, teléfono, email, redes sociales, políticas

### FASE 6: Limpieza ✅
- [x] Verificar que no queden referencias a la ruta vieja en la tienda pública
- [x] Verificar que la tienda pública funcione correctamente
- [x] Pruebas de seguridad: endpoints admin requieren token, endpoints públicos son solo lectura

## ARCHIVOS CREADOS/MODIFICADOS

### Nuevos archivos:
- `frondend/lib/features/store_admin/services/store_admin_api_service.dart` - API service con autenticación
- `frondend/lib/features/store_admin/providers/store_admin_provider.dart` - Provider con estados
- `frondend/lib/features/store_admin/screens/store_admin_screen.dart` - Pantalla principal con tabs
- `frondend/lib/features/store_admin/screens/store_config_screen.dart` - Configuración de tienda
- `frondend/lib/features/store_admin/screens/store_banners_screen.dart` - Gestión de banners
- `frondend/lib/features/store_admin/screens/store_carts_screen.dart` - Gestión de carritos
- `frondend/lib/features/store_admin/screens/store_payments_screen.dart` - Gestión de pagos
- `frondend/lib/features/store_admin/screens/store_policies_screen.dart` - Gestión de políticas

### Archivos modificados:
- `frondend/lib/app.dart` - Ruta /admin/tienda redirigida al panel admin
- `frondend/lib/main.dart` - Registro de StoreAdminProvider
- `frondend/lib/features/bots/pages/bot_dashboard_page.dart` - Enlaces a Tienda en drawer/sidebar
- `src/routes/storefront.routes.js` - Endpoints de políticas agregados
- `src/controllers/storefront.controller.js` - Controladores de políticas
- `src/services/storefront.service.js` - Servicios de políticas
- `scripts/sql/crear_tabla_storefront_policies.sql` - Script SQL para tabla de políticas

## ESTRUCTURA FINAL

### Panel Admin Principal:
```
Administración > Tienda
├── Configuración (nombre, slug, descripción, contacto, dirección, estado)
├── Banners (CRUD, activar/desactivar, orden)
├── Carritos (filtros: activos/abandonados/completados, detalle, WhatsApp)
├── Pagos (lista de pagos con estado, método, monto)
└── Políticas (privacidad, términos, garantía, envío, devoluciones, contacto)
```

### Tienda Pública (solo para clientes):
```
Home
├── Productos
├── Categorías
├── Carrito
├── Checkout/Contacto
└── Políticas (footer)
```

### Endpoints Backend:
```
Públicos (solo lectura):
- GET /api/storefront/public/:botId/config
- GET /api/storefront/public/:botId/banners
- GET /api/storefront/public/:botId/products
- GET /api/storefront/public/:botId/categories
- GET /api/storefront/public/:botId/policies

Protegidos (requieren token):
- GET/PUT /api/storefront/admin/:botId/config
- CRUD /api/storefront/admin/:botId/banners
- GET /api/storefront/admin/:botId/carts
- GET /api/storefront/admin/:botId/payments
- CRUD /api/storefront/admin/:botId/policies
```
