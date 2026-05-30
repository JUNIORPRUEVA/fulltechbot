/**
 * FULLTECH STORE - Service Worker personalizado
 * 
 * Estrategia de cache:
 * - API dinámica (storefront): Siempre fresh (network-only)
 * - Imágenes: Cache-first con versionado por URL (?v=...)
 * - Assets estáticos (Flutter): Cache-first con actualización en background
 * - Navegación: Network-first con fallback a cache
 * 
 * IMPORTANTE: La navegación SIEMPRE intenta ir a la red primero.
 * Si el service worker está cacheando una versión anterior, 
 * al recargar la página (Ctrl+F5) se obtendrá la última versión.
 * 
 * Versión: 3.0.0 - Forzar siempre red para navegación
 */

const SW_VERSION = 'fulltech-sw-v3.0.0';
const CACHE_NAME = 'fulltech-store-v3';
const STATIC_ASSETS_CACHE = 'fulltech-static-v3';
const IMAGE_CACHE = 'fulltech-images-v3';

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
  console.log(`[SW ${SW_VERSION}] Instalando nueva versión...`);
  
  // Forzar activación inmediata sin esperar a que se cierren las pestañas
  self.skipWaiting();
  
  event.waitUntil(
    caches.open(STATIC_ASSETS_CACHE).then((cache) => {
      return cache.addAll([
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
  console.log(`[SW ${SW_VERSION}] Activando, limpiando caches viejos...`);
  
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
      // Tomar control de todas las pestañas inmediatamente
      self.clients.claim(),
    ]).then(() => {
      console.log(`[SW ${SW_VERSION}] Activado y controlando todas las pestañas`);
      // Notificar a todas las pestañas que hay una nueva versión
      self.clients.matchAll().then(clients => {
        clients.forEach(client => {
          client.postMessage({ type: 'SW_ACTIVATED', version: SW_VERSION });
        });
      });
    })
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
  // 4. Navegación (HTML): SIEMPRE network-first
  //    NUNCA cachear index.html para evitar servir versión antigua
  // ==========================================
  if (event.request.mode === 'navigate') {
    event.respondWith(networkFirstNavigation(event.request));
    return;
  }
  
  // ==========================================
  // 5. index.html directo: Siempre fresh
  // ==========================================
  if (path === '/' || path === '/index.html') {
    event.respondWith(networkFirstNavigation(event.request));
    return;
  }
  
  // ==========================================
  // 6. Otros: Network-first
  // ==========================================
  event.respondWith(networkFirstWithFallback(event.request));
});

// ============================================
// ESTRATEGIAS
// ============================================

/**
 * Network-only: Siempre va a la red, nunca cachea.
 */
async function networkOnly(request) {
  try {
    const response = await fetch(request);
    return response;
  } catch (error) {
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
 */
async function imageCacheStrategy(request) {
  const cache = await caches.open(IMAGE_CACHE);
  
  const cachedResponse = await cache.match(request);
  if (cachedResponse) {
    return cachedResponse;
  }
  
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
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
  
  if (cachedResponse) {
    fetchPromise.catch(() => {});
    return cachedResponse;
  }
  
  return fetchPromise;
}

/**
 * Network-first para navegación: SIEMPRE va a la red primero.
 * NUNCA cachea el HTML para evitar servir versiones antiguas.
 * Solo usa cache como fallback si no hay red.
 */
async function networkFirstNavigation(request) {
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      // NO cacheamos la respuesta de navegación para evitar
      // que se sirva una versión antigua del HTML
      return networkResponse;
    }
    return networkResponse;
  } catch (error) {
    // Sin conexión: usar cache como fallback
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    
    // Fallback final: index.html del cache
    const fallback = await caches.match('/index.html');
    if (fallback) {
      return fallback;
    }
    
    return new Response('Offline', { status: 503 });
  }
}

/**
 * Network-first con fallback a cache (para recursos no críticos).
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
  
  if (event.data?.type === 'CHECK_VERSION') {
    event.ports?.[0]?.postMessage({ version: SW_VERSION });
  }
});
