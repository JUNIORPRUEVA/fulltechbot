# Store Frontend Fixes

## Problema real de imagenes

La tienda estaba mezclando varias formas de representar imagenes:

- URLs absolutas
- rutas relativas del backend como `uploads/...` y `api/...`
- claves o paths de Cloudflare R2
- valores guardados desde el panel admin

Ademas, el frontend del panel estaba leyendo mal la respuesta del upload:

- el backend devolvia `data.url`
- el frontend estaba buscando `url` en la raiz del JSON

Eso podia dejar logos, banners y media administrativa con valores vacios o inconsistentes.

## Como se resolvio

Se creo un resolvedor central:

- `frondend/lib/features/storefront/services/storefront_image_resolver.dart`

Reglas:

- Si viene `http://` o `https://`, se usa directo.
- Si viene `assets/...`, se trata como asset local.
- Si viene `/uploads`, `uploads/`, `/api/...` o `api/...`, se une con `API_BASE_URL`.
- Si viene una key/path de storage, se une con `STORAGE_PUBLIC_URL`.
- Si no hay `STORAGE_PUBLIC_URL`, se usa el proxy del backend: `/api/storage/file/...`

Tambien se creo un widget reutilizable:

- `frondend/lib/features/storefront/widgets/storefront_smart_image.dart`

## Configuracion de frontend

La app usa:

- `API_BASE_URL`
- `STORAGE_PUBLIC_URL`

Ubicacion:

- `frondend/lib/core/constants/api_config.dart`

Ejemplo de build:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.midominio.com \
  --dart-define=STORAGE_PUBLIC_URL=https://storage-publico.midominio.com
```

## Configuracion en EasyPanel

Build Args del servicio PWA:

- `API_BASE_URL=https://api.midominio.com`
- `STORAGE_PUBLIC_URL=https://storage-publico.midominio.com`

No colocar aqui:

- `DATABASE_URL`
- `STORAGE_ACCESS_KEY_ID`
- `STORAGE_SECRET_ACCESS_KEY`
- credenciales privadas

Esas variables deben quedarse solo en backend.

## Docker

El Dockerfile de la PWA acepta:

- `ARG API_BASE_URL`
- `ARG STORAGE_PUBLIC_URL`

## Como probar imagenes

1. Abrir la tienda en navegador.
2. Revisar `Network` en DevTools.
3. Confirmar que logo, banners, slider y detalle usen URL publica correcta.
4. Verificar que no aparezcan rutas `localhost`, `file://`, `C:\` o `/mnt/` en produccion.

## Busqueda en vivo

La tienda ahora abre una busqueda premium desde el icono o la tarjeta de busqueda.

Comportamiento:

- debounce de 320ms
- filtra localmente por nombre, categoria, descripcion y palabras clave
- cuando hay 2 o mas letras, consulta tambien el endpoint publico de productos

## PWA

Se ajusto:

- `web/manifest.json`
- `web/index.html`

Para que instalada se vea como app:

- `display: standalone`
- `theme_color` y `background_color` alineados a marca
- meta tags de iOS y mobile web app

Limitacion real:

- en Chrome normal no se puede esconder la barra del navegador por codigo
- instalada como PWA si se abre como app independiente

## Si un banner no aparece

Revisar:

1. que `imagen_url` exista
2. que la URL sea absoluta o resolvible
3. que `STORAGE_PUBLIC_URL` sea correcto
4. que el archivo exista realmente en storage
5. que el backend no este devolviendo una key rota o vacia
