function log(text) {
    let request = indexedDB.open("at-chat-db", 1);
    request.onerror = (event) => {};
    request.onupgradeneeded = function(event) {
        let db = event.target.result;
        let objectStore = db.createObjectStore("at-chat-object-store", { keyPath: "id" });
    };
    request.onsuccess = function(event) {
        let db = event.target.result;
        let transaction = db.transaction("at-chat-object-store", "readwrite");
        let objectStore = transaction.objectStore("at-chat-object-store");

        // Random suffix so two logs written in the same millisecond don't
        // collide on the keyPath and get silently dropped by add().
        let data = { id: Date.now().toString() + "_" + Math.random().toString(36).slice(2, 8), name: text };
        objectStore.add(data);
    };
}

// Activate a newer service-worker.js as soon as it finishes installing instead
// of waiting for every tab to close, and immediately take over already-open
// pages so the new version applies without a manual reload.
self.addEventListener('install', (event) => {
    // Record when this service worker was installed so it can be surfaced in
    // the debug section. Stored in Cache Storage because that's readable from
    // both the service worker and the page. The body is a human-readable ISO
    // timestamp so it's obvious when inspected directly in devtools.
    event.waitUntil((async () => {
        try {
            const cache = await caches.open('service_worker_installed_at');
            await cache.put(
                'installedAt',
                new Response(new Date().toISOString(), {
                    status: 200,
                    statusText: 'OK',
                    headers: { 'Content-Type': 'text/plain' }
                })
            );
        } catch (error) {
            log("Install event error: " + error.message);
        }
        await self.skipWaiting();
    })());
});

self.addEventListener('activate', (event) => {
    event.waitUntil(self.clients.claim());
});

// Register event listener for the 'push' event.
self.addEventListener('push', function(event) {
    try
    {
        const data = event.data.json().notification;

        self.registration.showNotification(
            data.title,
            { body: data.body
            , icon: data.icon
            , data: data.data
            });
        log("Push event: " + JSON.stringify(event.data.json()));
    }
    catch(error)
    {
        log("Push event error: " + error.message);
    }
});

self.addEventListener('notificationclick', function(event) {

    const notificationData = event.notification.data || '/';
    log("Notification clicked: " + JSON.stringify(notificationData));

    try {
        event.notification.close();

        // Wrap the async work in waitUntil so the service worker isn't terminated
        // before it finishes.
        event.waitUntil(
            clients.matchAll({ type: "window", includeUncontrolled: true })
                .then((windowClients) => {
                    // If a window is already open, navigate it and bring it to the
                    // foreground.
                    for (const client of windowClients) {
                        if ('focus' in client) {
                            client.postMessage(notificationData);
                            return client.focus();
                        }
                    }

                    // No window open (the common case when the app is closed): open
                    // a new one. Previously this branch was commented out, so the
                    // notification closed without opening anything.
                    if (clients.openWindow) {
                        return clients.openWindow(notificationData);
                    }
                })
        );
    }
    catch (e) {
        log("Notification clicked error: " + e.message);
    }

});

// Original code found here https://developer.chrome.com/docs/workbox/caching-strategies-overview/#cache_first_falling_back_to_network
// Establish a cache name
const cacheName = 'resource_cache_v1';

const frontendCacheName = 'frontend_cache_v1';

// Uploaded files never change: the last path segment is a hash of the file's
// contents, so a cached response can't go stale. The cache still needs an upper
// bound though. Cache Storage counts against the origin's storage quota, and
// when an origin goes over quota the browser evicts *all* of its storage, which
// would throw away the frontend bundle along with every avatar and put us back
// to fetching each one over the network.
const maxCachedResources = 500;

// cache.keys() walks every entry, so trimming after each stored file would make
// writes O(number of cached files). Amortize it across a batch of writes
// instead. Sitting a little over the cap between trims costs nothing.
const putsBetweenTrims = 20;

let putsSinceTrim = 0;

// Trims run one at a time. Files are stored concurrently, so two overlapping
// trims would both read the entry list before either one's deletes landed, both
// compute an overflow against that same stale length, and between them delete
// far more than the cache is actually over by.
let trimming = Promise.resolve();

function trimCache(cache) {
    putsSinceTrim = putsSinceTrim + 1;
    if (putsSinceTrim < putsBetweenTrims) {
        return trimming;
    }
    putsSinceTrim = 0;

    trimming = trimming.then(async () => {
        const keys = await cache.keys();
        const overflow = keys.length - maxCachedResources;

        // Guard the slice: slice(0, negative) counts back from the end of the
        // list and would delete entries while the cache is still under the cap.
        if (overflow <= 0) {
            return;
        }

        // keys() returns entries in insertion order, so the front of the list is
        // the least recently stored.
        await Promise.all(keys.slice(0, overflow).map((key) => cache.delete(key)));
    });

    return trimming;
}

// Everything the file server hands out under these paths is immutable and safe
// to keep forever: /file/<content type index>/<content hash> for uploads (the
// content type is an index into the server's content type table, so it's always
// a number), /file/t/<content hash> for generated thumbnails, and
// /file/discord-sticker/<sticker id> for stickers proxied from Discord.
//
// Deliberately not matched are /file/upload, /file/upload-url and
// /file/internal/*, which are POSTs whose responses depend on the request body.
function isCacheableFile(url, domain) {
    const prefix = domain + 'file/';
    if (!url.startsWith(prefix)) {
        return false;
    }

    const path = url.slice(prefix.length);
    return path.startsWith('t/')
        || path.startsWith('discord-sticker/')
        || (path.length > 0 && path[0] >= '0' && path[0] <= '9');
}

self.addEventListener('fetch', (event) => {
    try
    {
    // Check if this is a request for an image
    const url = event.request.url;

    // Derived from the service worker's own location rather than hardcoded, so
    // the caching still applies when the app is served from somewhere other
    // than https://at-chat.app (a staging domain, a local build, ngrok).
    const domain = self.location.origin + '/';

    // cache.put() rejects for anything other than GET, and uploads have request
    // bodies that would make a cached response meaningless anyway.
    if (event.request.method !== 'GET') {
        return;
    }

    // The hashed frontend bundle, e.g. https://at-chat.app/frontend.a1b2c3.js
    if (url.startsWith(domain + 'frontend.') && url.endsWith('.js')) {
        event.respondWith(caches.open(frontendCacheName).then(async (cache) => {
            // Cache first: if this exact version is already cached, serve it
            // straight from disk so the site loads faster.
            const cachedResponse = await cache.match(url);
            if (cachedResponse) {
                return cachedResponse;
            }

            // Cache miss means the hash differs from what we have stored, i.e. a
            // new version was deployed. Fetch it, then delete every previously
            // cached frontend bundle before storing the new one so only the
            // current version is ever kept.
            const fetchedResponse = await fetch(event.request);
            if (fetchedResponse.ok) {
                const keys = await cache.keys();
                await Promise.all(keys.map((key) => cache.delete(key)));
                await cache.put(event.request, fetchedResponse.clone());

                // Serve the freshly cached copy rather than `fetchedResponse`
                // itself. Reading the network body twice (once via the clone we
                // hand to cache.put, once via the response we return) tees the
                // stream, and the branch that is drained second can be truncated
                // to the browser's tee buffer limit (~320 KiB). Lamdera's
                // hot-reload loads the new bundle with `<script type="module">`,
                // so a truncated body reaches the parser mid-expression and
                // throws "missing ) after argument list", breaking the in-place
                // upgrade (a full page refresh then works because it reads the
                // complete bytes back out of this cache). Returning the cached
                // copy guarantees the page receives the same complete bytes we
                // just stored.
                const cachedFetchedResponse = await cache.match(event.request);
                if (cachedFetchedResponse) {
                    return cachedFetchedResponse;
                }
            }
            return fetchedResponse;
        }));
        return;
    }

    if (isCacheableFile(url, domain)) {
        event.respondWith(caches.open(cacheName).then((cache) => {
            // Go to the cache first
            return cache.match(url).then((cachedResponse) => {
                // Return a cached response if we have one
                if (cachedResponse) {
                    return cachedResponse;
                }

                // Otherwise, hit the network
                return fetch(event.request).then((fetchedResponse) => {

                    // A response sent with chunked encoding has no
                    // content-length, which reads back as 0 here. That's treated
                    // as small enough to keep rather than as a reason to skip
                    // caching, otherwise nothing behind a gzipping proxy would
                    // ever be stored.
                    const size = Number(fetchedResponse.headers.get("content-length"));
                    const isValid = size < 1000 * 1000;

                    if (fetchedResponse.ok && isValid) {
                        // Hand the response to the page immediately and write to
                        // the cache in the background, but keep the write alive
                        // with waitUntil. Without it the browser is free to shut
                        // the service worker down as soon as this fetch handler
                        // settles, dropping the put half finished, and the file
                        // gets refetched on the next page load.
                        event.waitUntil(
                            cache
                                .put(event.request, fetchedResponse.clone())
                                .then(() => trimCache(cache))
                                .catch((error) => log("Cache put error: " + error.message))
                        );
                    }

                    return fetchedResponse;
                });
            });
        }));
    } else {
    return;
    }
    }
    catch (error)
    {
        log("Fetch event error: " + error.message);
    }
});