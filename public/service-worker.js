// Small IndexedDB helper used to hand off a tapped notification's target route
// to the app. On iOS, Declarative Web Push navigates the window to the payload's
// `navigate` URL when a notification is tapped, which reloads the SPA and
// destroys any client we could postMessage to. IndexedDB survives that reload,
// so the freshly (re)launched app can read the route on boot. See stuff.js for
// the read side.
const pendingNotificationDb = 'at-chat-notifications';
const pendingNotificationStore = 'kv';
const pendingNotificationKey = 'pendingNotificationUrl';

function openPendingNotificationDb() {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(pendingNotificationDb, 1);
        request.onupgradeneeded = () => {
            request.result.createObjectStore(pendingNotificationStore);
        };
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
    });
}

function setPendingNotification(url) {
    return openPendingNotificationDb().then((db) => new Promise((resolve, reject) => {
        const tx = db.transaction(pendingNotificationStore, 'readwrite');
        tx.objectStore(pendingNotificationStore).put({ url: url, time: Date.now() }, pendingNotificationKey);
        tx.oncomplete = () => { db.close(); resolve(); };
        tx.onerror = () => { db.close(); reject(tx.error); };
    }));
}

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
    }
    catch(error)
    {
        self.registration.showNotification("error", { body : error });
    }
});

self.addEventListener('notificationclick', function(event) {
    // The target route to open, stored on the notification by the backend
    // (Broadcast.pushNotification sets `data` to the full target URL).
    const notificationData = event.notification.data;

    // Close the notification
    event.notification.close();

    event.waitUntil((async () => {
        // Persist the target so the (re)launched window can pick it up on boot.
        // On iOS the `navigate` field reloads the window, so this is the only
        // reliable channel; on desktop/Android the postMessage below handles
        // the still-alive window and this stash is cleared (or expires) on the
        // next boot without causing a stray navigation.
        if (typeof notificationData === 'string' && notificationData.length > 0) {
            try { await setPendingNotification(notificationData); } catch (error) {}
        }

        // Fast path: if a window is genuinely still alive (desktop / Android,
        // where tapping does not reload the SPA), hand it the route directly
        // and focus it. The app routes via a model update, so no history entry
        // is added.
        const windowClients = await clients.matchAll({ type: "window", includeUncontrolled: true });
        if (windowClients.length > 0) {
            windowClients[0].postMessage(notificationData);
            if (windowClients[0].focus) {
                try { await windowClients[0].focus(); } catch (error) {}
            }
        }
        // No openWindow fallback: on iOS the declarative `navigate` field
        // already (re)launches the app, and the stashed route above restores
        // the correct page on boot.
    })());
});

// Original code found here https://developer.chrome.com/docs/workbox/caching-strategies-overview/#cache_first_falling_back_to_network
// Establish a cache name
const cacheName = 'resource_cache_v1';

self.addEventListener('fetch', (event) => {
    // Check if this is a request for an image
    const url = event.request.url;

    const domain = 'https://at-chat.app/';

    if (//url.startsWith(domain + 'frontend.') Disabled because it might be messing up deploys
        url.startsWith(domain + 'file/t/')
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
                    const isValid = url.startsWith(domain + 'frontend.') || size < 1000 * 1000;

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