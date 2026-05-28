/**
 * FULLTECH STORE - Service Worker personalizado
 * 
 * Estrategia de cache:
 * - API dinámica (storefront): Siempre fresh (network-only)
 * - Imágenes: Cache-first con versionado por URL (?v=...)
 * - Assets estáticos (Flutter): Cache-first con actualización en background
 * - Navegación: Network-first con fallback a cache
 * 
 * Después de deploy, detecta nueva versión y actualiza automáticamente.
 * El usuario nunca debe borrar cache manualmente.
 */

const CACHE_NAME = 'fulltech-store-v2';
const STATIC_ASSETS_CACHE = 'fulltech-static-v2';
const IMAGE_CACHE = 'fulltech-images-v2';

// URLs de API que NUNCA deben cachearse
const API_PATTERNS = [
  '/api/storefront/',
  '/api/bots/',
  '/api/catalogo',
  '/api/ofertas',
  '/api/categorias',
];

// Extensiones de imágenes para cache largo
const IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg', '.ico'];

// ============================================
// INSTALL: Precargar assets críticos
// ============================================
self.addEventListener('install', (event) => {
  console.log('[SW] Instalando nueva versión...');
  
  // Forzar activación inmediata sin esperar a que se cierren las pestañas
  self.skipWaiting();
  
  event.waitUntil(
    caches.open(STATIC_ASSETS_CACHE).then((cache) => {
      return cache.addAll([
        '/',
        '/index.html',
        '/main.dart.js',
        '/flutter.js',
        '/flutter_bootstrap.js',
        '/manifest.json',
      ]).catch((err) => {
        console.warn('[SW] Precarga parcial:', err.message);
      });
    })
  );
});

// ============================================
// ACTIVATE: Limpiar caches viejos
// ============================================
self.addEventListener('activate', (event) => {
  console.log('[SW] Activando nueva versión, limpiando caches viejos...');
  
  const validCaches = [CACHE_NAME, STATIC_ASSETS_CACHE, IMAGE_CACHE];
  
  event.waitUntil(
    Promise.all([
      // Limpiar caches que ya no corresponden
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (!validCaches.includes(cacheName)) {
              console.log('[SW] Eliminando cache viejo:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      }),
      // Tomar control de todas las pestañas
      self.clients.claim(),
    ])
  );
});

// ============================================
// FETCH: Estrategia de cache
// ============================================
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  const path = url.pathname;
  
  // ==========================================
  // 1. API dinámica: SIEMPRE network-only
  // ==========================================
  if (API_PATTERNS.some((pattern) => path.includes(pattern))) {
    event.respondWith(networkOnly(event.request));
    return;
  }
  
  // ==========================================
  // 2. Imágenes: Cache-first con versionado
  //    Si la URL tiene ?v=..., se cachea con esa versión
  //    Si cambia la versión, se descarga la nueva imagen
  // ==========================================
  if (isImageRequest(path)) {
    event.respondWith(imageCacheStrategy(event.request));
    return;
  }
  
  // ==========================================
  // 3. Assets de Flutter (main.dart.js, etc.)
  //    Stale-while-revalidate: sirve rápido, actualiza en background
  // ==========================================
  if (isFlutterAsset(path)) {
    event.respondWith(staleWhileRevalidate(event.request, STATIC_ASSETS_CACHE));
    return;
  }
  
  // ==========================================
  // 4. Navegación (HTML): Network-first
  // ==========================================
  if (event.request.mode === 'navigate') {
    event.respondWith(networkFirstWithFallback(event.request));
    return;
  }
  
  // ==========================================
  // 5. Otros: Network-first
  // ==========================================
  event.respondWith(networkFirstWithFallback(event.request));
});

// ============================================
// ESTRATEGIAS
// ============================================

/**
 * Network-only: Siempre va a la red, nunca cachea.
 * Para APIs dinámicas de productos, precios, ofertas.
 */
async function networkOnly(request) {
  try {
    const response = await fetch(request);
    return response;
  } catch (error) {
    // Si no hay red, devolver error
    return new Response(
      JSON.stringify({ ok: false, message: 'Sin conexión' }),
      {
        status: 503,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
}

/**
 * Cache-first para imágenes con versionado.
 * Si la URL tiene ?v=..., busca en cache primero.
 * Si no encuentra, va a la red y cachea.
 * Si la versión cambia, la URL es diferente, así que descarga la nueva.
 */
async function imageCacheStrategy(request) {
  const cache = await caches.open(IMAGE_CACHE);
  
  // Intentar servir desde cache primero
  const cachedResponse = await cache.match(request);
  if (cachedResponse) {
    return cachedResponse;
  }
  
  // No está en cache, ir a la red
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      // Cachear la imagen para futuras solicitudes
      // Como la URL incluye ?v=version, si la versión cambia,
      // la URL será diferente y se descargará la nueva imagen
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    // Si no hay red y no está en cache, devolver placeholder
    return new Response(
      '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200"><rect fill="#F1F5F9" width="200" height="200"/><text fill="#94A3B8" font-family="Arial" font-size="14" x="50%" y="50%" text-anchor="middle" dominant-baseline="middle">Sin imagen</text></svg>',
      {
        status: 200,
        headers: { 'Content-Type': 'image/svg+xml' },
      }
    );
  }
}

/**
 * Stale-while-revalidate: Sirve desde cache rápido, actualiza en background.
 */
async function staleWhileRevalidate(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cachedResponse = await cache.match(request);
  
  const fetchPromise = fetch(request).then((networkResponse) => {
    if (networkResponse.ok) {
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  }).catch(() => cachedResponse);
  
  // Si hay cache, devolverlo inmediatamente
  if (cachedResponse) {
    // Pero actualizar en background
    fetchPromise.catch(() => {});
    return cachedResponse;
  }
  
  // No hay cache, esperar la red
  return fetchPromise;
}

/**
 * Network-first con fallback a cache.
 */
async function networkFirstWithFallback(request) {
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    
    // Fallback final: index.html para navegación
    if (request.mode === 'navigate') {
      const fallback = await caches.match('/index.html');
      if (fallback) {
        return fallback;
      }
    }
    
    return new Response('Offline', { status: 503 });
  }
}

// ============================================
// HELPERS
// ============================================

function isImageRequest(path) {
  return IMAGE_EXTENSIONS.some((ext) => path.toLowerCase().includes(ext));
}

function isFlutterAsset(path) {
  return (
    path.includes('main.dart.js') ||
    path.includes('flutter.js') ||
    path.includes('flutter_bootstrap.js') ||
    path.includes('flutter_service_worker.js') ||
    path.includes('assets/') ||
    path.includes('canvaskit/') ||
    path.endsWith('.wasm')
  );
}

// ============================================
// MENSAJES: Para comunicación con la app
// ============================================
self.addEventListener('message', (event) => {
  if (event.data === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data === 'CLEAR_CACHES') {
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => caches.delete(cacheName))
      );
    }).then(() => {
      console.log('[SW] Caches limpiados por solicitud de la app');
    });
  }
});
