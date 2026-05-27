# Store Public Home Routing Fix

## Que estaba mal

- El dominio principal en produccion podia terminar mostrando flujos administrativos o una build vieja donde aparecia `Seleccionar Bot`.
- La portada publica de la tienda tenia bloques repetidos:
  - hero principal
  - buscador separado
  - chips de confianza aparte
  - banner secundario adicional
- El resultado visual se sentia cargado y no como una portada comercial unica.

## Por que abria admin o bot selector

En el codigo actual, el bot selector vive solamente dentro de `MainNavigation`, que se usa para rutas `/admin*`.

Archivo de control principal:

- `frondend/lib/app.dart`

La ruta inicial publica ya estaba separada, pero en despliegues anteriores se estaba sirviendo una build vieja o una build que no resolvia bien la tienda publica por defecto.

## Como quedo la ruta inicial

Rutas publicas:

- `/`
- `/tienda`
- `/tienda/:slug`
- `/producto/:id`
- `/tienda/:slug/producto/:id`
- `/carrito`
- `/checkout`

Comportamiento:

- `/` y `/tienda` resuelven la tienda publica activa.
- Si existe `DEFAULT_STOREFRONT_SLUG`, la app redirige directo a la tienda sin esperar la API.
- Si no hay slug por entorno, intenta resolver la tienda activa por backend.

## Rutas admin protegidas

- `/admin`
- `/admin/bots`
- `/admin/tienda`
- `/admin/productos`
- `/admin/banners`
- `/admin/pedidos`
- `/admin/clientes`
- `/admin/pagos`

Proteccion:

- si no hay sesion, se redirige a `/login`
- si hay sesion, permite entrar

## Como se carga la tienda publica por defecto

Orden de resolucion:

1. slug recibido por ruta
2. `DEFAULT_STOREFRONT_SLUG`
3. endpoint backend `GET /api/storefront/public/default`
4. fallback a landing publica si de verdad no existe tienda activa

## Nuevo hero slider principal

Componente nuevo:

- `frondend/lib/features/storefront/widgets/storefront_main_hero_slider.dart`

Responsabilidades:

- integra banners reales si existen
- usa fallback premium si no hay imagen
- contiene logo/nombre
- contiene carrito
- contiene acceso a login/admin
- contiene boton de busqueda
- contiene CTA comerciales
- contiene chips de confianza
- incluye indicadores y auto slide

## Bloques repetidos eliminados

Se eliminaron de la portada publica:

- buscador separado debajo del hero
- chips de confianza duplicados debajo del hero
- banner secundario repetido debajo del hero

La home ahora arranca asi:

- hero slider premium
- categorias rapidas
- ofertas del dia
- productos destacados
- catalogo

## Como funciona el buscador

- movil:
  - boton `Buscar productos` dentro del hero
  - abre bottom sheet de busqueda en vivo
- desktop:
  - CTA de busqueda dentro del hero y superficie de busqueda integrada

La busqueda:

- usa debounce
- filtra por nombre, categoria, descripcion y palabras clave
- mezcla resultados locales y remotos

## Como probar en movil y PC

1. abrir `/`
2. confirmar que entra a la tienda y no a `Seleccionar Bot`
3. verificar que el hero grande aparece primero
4. verificar que no existe buscador repetido debajo
5. verificar que el login/admin esta accesible:
   - movil: icono en el hero y opcion en menu
   - desktop: boton visible arriba
6. abrir `/admin` sin sesion
7. confirmar redireccion a `/login`
