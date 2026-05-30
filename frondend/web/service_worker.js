/**
 * FULLTECH STORE - Service Worker (DESACTIVADO)
 * 
 * IMPORTANTE: Este Service Worker está desactivado intencionalmente.
 * 
 * El Service Worker anterior estaba cacheando la versión vieja de la app
 * (FullTech Bot admin) y sirviéndola en lugar de la nueva versión con la tienda.
 * 
 * Para evitar este problema, el Service Worker se desregistra a sí mismo
 * y limpia todos los caches al activarse.
 * 
 * La app funciona perfectamente sin Service Worker.
 */

const SW_VERSION = 'fulltech-sw-DISABLED';

self.addEventListener('install', (event) => {
  console.log(`[SW ${SW_VERSION}] Instalado - DESACTIVADO intencionalmente`);
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  console.log(`[SW ${SW_VERSION}] Activado - Limpiando todo y desregistrándome`);
  
  event.waitUntil(
    Promise.all([
      // Limpiar TODOS los caches
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => caches.delete(cacheName))
        );
      }),
      // Desregistrarse a sí mismo
      self.registration.unregister(),
      // Tomar control de todas las pestañas
      self.clients.claim(),
    ]).then(() => {
      console.log(`[SW ${SW_VERSION}] Caches limpiados y auto-desregistrado`);
      // Notificar a todas las pestañas que recarguen
      self.clients.matchAll().then(clients => {
        clients.forEach(client => {
          client.postMessage({ type: 'SW_DISABLED', message: 'Service Worker desactivado. Recargando para obtener versión fresca.' });
        });
      });
    })
  );
});

// No interceptar ninguna petición
self.addEventListener('fetch', () => {
  // No hacer nada - dejar pasar todas las peticiones directamente
});
