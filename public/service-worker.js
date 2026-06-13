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

// Separate cache that only ever holds the current frontend bundle. The bundle
// is served at https://at-chat.app/frontend.<random alphanumeric string>.js and
// the random part changes every deploy, so we key on the full URL: a different
// hash means a new version and the old one gets evicted (see below).
const frontendCacheName = 'frontend_cache_v1';

self.addEventListener('fetch', (event) => {
    // Check if this is a request for an image
    const url = event.request.url;

    const domain = 'https://at-chat.app/';

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
            }
            return fetchedResponse;
        }));
        return;
    }

    if (url.startsWith(domain + 'file/t/')
        || url.startsWith(domain + 'file/0')
        || url.startsWith(domain + 'file/1')
        || url.startsWith(domain + 'file/2')
        || url.startsWith(domain + 'file/3')
        || url.startsWith(domain + 'file/4')
        || url.startsWith(domain + 'file/5')
        || url.startsWith(domain + 'file/6')
        || url.startsWith(domain + 'file/7')
        || url.startsWith(domain + 'file/8')
        || url.startsWith(domain + 'file/9')
        ) {

        event.respondWith(caches.open(cacheName).then((cache) => {
            // Go to the cache first
            return cache.match(url).then((cachedResponse) => {
                // Return a cached response if we have one
                if (cachedResponse) {
                    return cachedResponse;
                }

                // Otherwise, hit the network
                return fetch(event.request).then((fetchedResponse) => {

                    const size = Number(fetchedResponse.headers.get("content-length"));
                    const isValid = size < 1000 * 1000;

                    if (fetchedResponse.ok && isValid) {
                        cache.put(event.request, fetchedResponse.clone());
                    }

                    return fetchedResponse;
                });
            });
        }));
    } else {
    return;
    }
});