/**
 * FULLTECH STORE - Service Worker
 * 
 * ESTRATEGIA: Network-first con actualización automática.
 * 
 * - No cachea archivos críticos (index.html, main.dart.js, etc.)
 * - Cachea solo assets con hash (imágenes, fuentes, etc.)
 * - Detecta cambios de versión y fuerza actualización
 * - Auto-desregistra versiones anteriores
 */

const CACHE_NAME = 'fulltech-store-v3';
const SW_VERSION = '2026.05.30.03';

// Archivos que NUNCA deben cachearse
const NEVER_CACHE = [
  '/index.html',
  '/flutter_bootstrap.js',
  '/flutter.js',
  '/main.dart.js',
  '/version.json',
  '/manifest.json',
  '/service_worker.js',
  '/flutter_service_worker.js',
  '/clear-cache.html',
];

self.addEventListener('install', (event) => {
  console.log(`[SW ${SW_VERSION}] Instalando...`);
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  console.log(`[SW ${SW_VERSION}] Activado - Limpiando caches antiguos`);
  
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log(`[SW] Eliminando cache antiguo: ${cacheName}`);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      return self.clients.claim();
    }).then(() => {
      // Notificar a todas las pestañas que el SW está listo
      self.clients.matchAll().then(clients => {
        clients.forEach(client => {
          client.postMessage({ 
            type: 'SW_ACTIVATED', 
            version: SW_VERSION,
            message: 'Service Worker actualizado correctamente.'
          });
        });
      });
    })
  );
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  const path = url.pathname;
  
  // No interceptar archivos críticos - siempre van a red
  if (NEVER_CACHE.includes(path)) {
    return;
  }
  
  // Solo cachear assets de Flutter (tienen hash en el nombre)
  if (path.startsWith('/assets/')) {
    event.respondWith(
      caches.match(event.request).then((cachedResponse) => {
        if (cachedResponse) {
          return cachedResponse;
        }
        return fetch(event.request).then((response) => {
          if (response && response.status === 200) {
            const clone = response.clone();
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(event.request, clone);
            });
          }
          return response;
        });
      })
    );
    return;
  }
  
  // Para todo lo demás, network-first
  event.respondWith(
    fetch(event.request).catch(() => {
      return caches.match(event.request);
    })
  );
});
