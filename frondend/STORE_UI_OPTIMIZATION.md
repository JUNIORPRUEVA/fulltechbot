# STORE UI Optimization

## Objetivo
Optimizar la home pÃºblica de la tienda FULLTECH con enfoque mobile-first para que se vea mÃ¡s compacta, comercial y premium sin dejar secciones vacÃ­as ni textos cortados.

## Componentes modificados
- `lib/features/storefront/screens/storefront_home_screen.dart`
- `lib/features/storefront/widgets/storefront_main_hero_slider.dart`
- `lib/features/storefront/widgets/storefront_product_card.dart`
- `lib/features/public/widgets/public_store_layout.dart`

## Cambios en el header
- En mÃ³vil el hero ahora usa un top bar compacto:
  - hamburguesa a la izquierda
  - bÃºsqueda, usuario y carrito a la derecha
  - el nombre de la tienda solo aparece si hay ancho suficiente
- Ya no se fuerza logo grande ni nombre largo en el header mÃ³vil.
- En desktop el top bar sÃ­ muestra logo, nombre, accesos a categorÃ­as/ofertas, login, bÃºsqueda y carrito.

## Cambios en el slider
- El hero principal ahora se renderiza con `AspectRatio` en mÃ³vil y altura controlada en desktop.
- Proporciones mÃ³viles:
  - `< 360px`: `1.05`
  - `< 520px`: `1.10`
  - resto mÃ³vil/tablet chico: `1.16`
- Altura desktop:
  - `520px` o `560px` segÃºn ancho
- El hero ahora usa:
  - overlay oscuro con degradado premium
  - esquinas redondeadas grandes
  - sombras suaves
  - chips de confianza
  - indicadores compactos
  - botones `Buscar productos` y `Ver ofertas`
- Si no hay imagen, se muestra un fallback visual premium con gradiente e iconografÃ­a, no un bloque roto.

## CÃ³mo se ocultan secciones vacÃ­as
- `CategorÃ­as rÃ¡pidas` solo se renderiza si hay categorÃ­as.
- `Ofertas del dÃ­a` solo se renderiza si hay productos en oferta.
- `Destacados` solo se renderiza si hay productos destacados.
- Esto evita espacios muertos y encabezados sin contenido.

## Duplicados eliminados
- Los productos destacados que ya aparecen en ofertas se filtran para no repetirse en ambas secciones.
- El CTA de bÃºsqueda se concentra dentro del hero, evitando interfaces duplicadas fuera de la primera pantalla.
- El hero actual reemplaza el protagonismo visual de widgets legacy que ya no eran la ruta principal (`StorefrontHeader`, `StorefrontBannerSlider`).

## Manejo de logo e imÃ¡genes
- El logo ya no se fuerza en mÃ³vil si compromete el layout.
- Las tarjetas y el hero usan `StorefrontSmartImage` con fallback visual.
- Las product cards usan `BoxFit.contain` para mejorar el recorte comercial en catÃ¡logo.
- Si una imagen falla:
  - hero: fallback premium con gradiente
  - producto: placeholder elegante con mensaje `Imagen no disponible`
  - categorÃ­a: placeholder con icono

## Cambios en categorÃ­as, ofertas y catÃ¡logo
- CategorÃ­as:
  - cards horizontales mÃ¡s compactas
  - imagen superior
  - nombre con `maxLines: 2`
  - conteo pequeÃ±o
- Ofertas y destacados:
  - carruseles horizontales compactos
  - tarjetas con ancho controlado
  - sin render cuando no hay datos
- CatÃ¡logo:
  - mÃ³vil: 2 columnas
  - tablet: 3 columnas
  - desktop: 4 columnas
  - padding central con ancho visual mÃ¡ximo cercano a `1240px`

## Cambios en product cards
- Fondo blanco y borde mÃ¡s limpio
- sombra mÃ¡s suave
- badge de oferta refinado
- categorÃ­a opcional arriba
- nombre hasta 2 lÃ­neas
- descripciÃ³n oculta en modo compacto para estabilizar alturas

## Buscador
- Se mantiene como experiencia en `BottomSheet`.
- Se abre desde el botÃ³n del hero y desde el icono superior.
- Hace bÃºsqueda local inmediata y bÃºsqueda remota cuando la consulta tiene 2 o mÃ¡s caracteres.
- Resultados muestran imagen, categorÃ­a, nombre y precio.

## WhatsApp flotante
- En mÃ³vil se usa FAB compacto.
- En desktop se usa FAB extendido con texto.
- Respeta `SafeArea` inferior para no tapar contenido importante.

## CÃ³mo probar
- MÃ³vil pequeÃ±o:
  - verificar que el nombre no se corte en el top bar
  - revisar que el hero no ocupe toda la pantalla
  - confirmar que se vea el inicio de las categorÃ­as al hacer scroll corto
- MÃ³vil grande:
  - validar botones del hero en una fila o `Wrap`
  - validar tarjetas de ofertas y catÃ¡logo sin overflow
- Tablet/desktop:
  - validar hero horizontal
  - validar ancho centrado
  - validar grid de 3 a 4 columnas segÃºn ancho
- Estados vacÃ­os:
  - sin ofertas: no renderiza secciÃ³n
  - sin destacados: no renderiza secciÃ³n
  - imagen rota: muestra placeholder

## Validaciones ejecutadas
- `flutter analyze`
  - sin errores nuevos bloqueantes en los archivos modificados; el proyecto conserva varios `info/warning` previos fuera del alcance de esta tarea
- `flutter build web --release`
  - compilaciÃ³n exitosa
