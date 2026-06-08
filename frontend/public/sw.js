/**
 * Kafe POS — Service Worker
 * Strategiya:
 *   - Statik fayllar (JS, CSS, HTML): Cache First
 *   - API GET so'rovlari (/api/halls, /api/menu): Network First, cache fallback
 *   - API POST so'rovlari: faqat network (oflayn queue IndexedDB da)
 */

const CACHE_NAME   = 'pos-cache-v1'
const API_CACHE    = 'pos-api-v1'
const API_BASE     = '/api'

const STATIC_URLS = [
  '/',
  '/index.html',
]

// ─── Install ──────────────────────────────────────────────────────────────────
self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(STATIC_URLS))
      .then(() => self.skipWaiting())
  )
})

// ─── Activate ─────────────────────────────────────────────────────────────────
self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys
        .filter(k => k !== CACHE_NAME && k !== API_CACHE)
        .map(k => caches.delete(k))
      )
    ).then(() => self.clients.claim())
  )
})

// ─── Fetch ────────────────────────────────────────────────────────────────────
self.addEventListener('fetch', (e) => {
  const { request } = e
  const url = new URL(request.url)

  // POST/PUT/PATCH/DELETE — to'g'ridan network ga
  if (request.method !== 'GET') return

  // API GET so'rovlari — Network First
  if (url.pathname.startsWith(API_BASE)) {
    e.respondWith(networkFirstAPI(request))
    return
  }

  // Statik fayllar — Cache First
  e.respondWith(cacheFirstStatic(request))
})

async function networkFirstAPI(request) {
  try {
    const response = await fetch(request.clone())
    if (response.ok) {
      const cache = await caches.open(API_CACHE)
      cache.put(request, response.clone())
    }
    return response
  } catch {
    // Offline: cache dan qaytarish
    const cached = await caches.match(request)
    if (cached) return cached
    return new Response(JSON.stringify({ error: 'Oflayn rejim', offline: true }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' }
    })
  }
}

async function cacheFirstStatic(request) {
  const cached = await caches.match(request)
  if (cached) return cached
  try {
    const response = await fetch(request.clone())
    if (response.ok) {
      const cache = await caches.open(CACHE_NAME)
      cache.put(request, response.clone())
    }
    return response
  } catch {
    // SPA uchun index.html qaytaramiz
    const fallback = await caches.match('/index.html')
    return fallback || new Response('Oflayn', { status: 503 })
  }
}
