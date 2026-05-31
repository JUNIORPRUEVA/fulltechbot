# PLAN DE OPTIMIZACIÓN - CARGA INSTANTÁNEA DE FULLTECH STORE

## Diagnóstico Inicial

### 🔴 BLOQUEOS CRÍTICOS IDENTIFICADOS

1. **index.html redirect bloquea Flutter** (Líneas 226-234): `window.location.replace("/#/tienda/fulltech")` + `return` detiene la carga de Flutter. El splash se queda visible hasta 15 segundos.

2. **PublicEntryScreen hace llamada API antes de mostrar Home**: Si no hay slug preferido, llama `_resolveStore()` que hace fetch a `/api/storefront/public/default` con timeout de 6 segundos.

3. **StorefrontHomeScreen `_loading = true` inicial**: El primer frame muestra skeleton en lugar del Home real.

4. **AppBar carga SharedPreferences de forma bloqueante**: `_loadCartCount()` usa `await SharedPreferences.getInstance()` que puede ser lento en web.

### 🟡 PROBLEMAS SEVEROS

5. No hay timeout de splash en index.html (solo se oculta cuando Flutter llama hideSplash)
6. Service Worker no tiene control de versión efectivo
7. nginx.conf no tiene brotli activado
8. Faltan logs [PERF] completos

## Plan de Corrección

### Fase 1: index.html - Eliminar redirect bloqueante
- [x] Eliminar `window.location.replace` que corta la carga de Flutter
- [x] Usar solo hash navigation sin redirect
- [x] Agregar timeout de splash máximo 2 segundos
- [x] Agregar logs de rendimiento en JS

### Fase 2: app.dart - Ruta raíz directa a Home
- [x] Ruta "/" ya redirige directo a StorefrontHomeScreen (slug: 'fulltech')
- [x] Verificar que no haya llamadas API antes

### Fase 3: StorefrontHomeScreen - Carga instantánea
- [x] Eliminar `_loading = true` inicial, mostrar Home inmediatamente
- [x] Mostrar skeletons solo para secciones sin datos
- [x] Cargar todo en segundo plano después del primer frame
- [x] Agregar logs [PERF] completos con Stopwatch
- [x] Timeout en todas las llamadas API
- [x] Manejo defensivo de datos vacíos/null

### Fase 4: StorefrontAppBar - Eliminar carga bloqueante
- [x] No esperar SharedPreferences en initState
- [x] Cargar contador de carrito en segundo plano

### Fase 5: Service Worker - Mejorar control de versión
- [x] Forzar actualización inmediata en clientes existentes
- [x] Mejorar limpieza de caches antiguos

### Fase 6: nginx.conf - Activar brotli y optimizar
- [x] Activar brotli
- [x] Mejorar cache-control

### Fase 7: Dockerfile - Mejorar build
- [x] Asegurar --web-renderer html
- [x] Mejorar versionado

### Fase 8: Pruebas y validación
- [ ] flutter analyze
- [ ] flutter build web --release
- [ ] Verificar logs [PERF]
