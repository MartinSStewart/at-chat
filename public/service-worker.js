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
    }
    catch(error)
    {
        self.registration.showNotification("error", { body : error });
    }
});

// The push service can unilaterally invalidate a subscription (FCM token
// rotation, browser update, storage eviction, etc.) without ever setting an
// expirationTime. When that happens the browser fires 'pushsubscriptionchange'
// here. If nothing resubscribes and tells the server, the backend keeps pushing
// to the dead endpoint and gets "push subscription has unsubscribed or expired"
// (FCM Error 11). So resubscribe with the same VAPID key and forward the new
// subscription to any open page, which sends it to the backend. If no page is
// open, the next app load re-registers (see register_push_subscription_to_js in
// elm-pkg-js/stuff.js).
self.addEventListener('pushsubscriptionchange', function(event) {
    event.waitUntil((async () => {
        try {
            // Reuse the VAPID public key from the old subscription so we resubscribe
            // with the same key the server signs with.
            const applicationServerKey =
                (event.oldSubscription && event.oldSubscription.options && event.oldSubscription.options.applicationServerKey)
                || (event.newSubscription && event.newSubscription.options && event.newSubscription.options.applicationServerKey)
                || null;

            // Some browsers already provide the replacement subscription; otherwise
            // create one ourselves.
            let subscription = event.newSubscription || await self.registration.pushManager.getSubscription();
            if (!subscription && applicationServerKey) {
                subscription = await self.registration.pushManager.subscribe({
                    userVisibleOnly: true,
                    applicationServerKey: applicationServerKey
                });
            }

            if (!subscription) {
                return;
            }

            const clientsList = await self.clients.matchAll({ type: "window", includeUncontrolled: true });
            for (const client of clientsList) {
                client.postMessage({ type: "pushsubscriptionchange", subscription: subscription.toJSON() });
            }
        } catch (error) {
        }
    })());
});

self.addEventListener('notificationclick', function(event) {
    // The URL to navigate to was stored as the notification's `data` (see the
    // push payload built in Broadcast.elm). It's either a full URL string or
    // null/undefined when the notification isn't tied to a specific route.
    const notificationData = event.notification.data || '/';

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