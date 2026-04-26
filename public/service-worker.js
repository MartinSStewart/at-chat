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
    // Access the data that was stored with the notification
    const notificationData = event.notification.data;

    // Use the data as needed
    console.log('Notification data:', notificationData);

    // Close the notification
    event.notification.close();

    // Example: Open a URL based on the data
    clients.matchAll({ type: "window", includeUncontrolled: true })
        .then((windowClients) => {
            if (windowClients.length > 0) {
                windowClients[0].postMessage(notificationData);
            }
            else {
                //clients.openWindow(notificationData);
            }
        });

});

// Original code found here https://developer.chrome.com/docs/workbox/caching-strategies-overview/#cache_first_falling_back_to_network
// Establish a cache name
const cacheName = 'resource_cache_v1';
const guildIconCacheName = 'guild_icon_cache_v1';

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
            // Check the dedicated guild icon cache first so pre-cached icons are served even if evicted from the general cache
            return caches.match(url, { cacheName: guildIconCacheName }).then((guildIconResponse) => {
                if (guildIconResponse) {
                    return guildIconResponse;
                }

                // Go to the general cache next
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
            });
        }));
    } else {
    return;
    }
});

// Pre-cache guild icons that the user is a part of, so they're available offline and on slow connections.
// Both normal guild icons and Discord guild icons are stored as local files served from at-chat.app/file/<n>/<hash>,
// so a single URL list covers both kinds.
self.addEventListener('message', (event) => {
    if (!event.data || event.data.type !== 'cache-guild-icons') {
        return;
    }

    const urls = Array.isArray(event.data.urls) ? event.data.urls : [];
    if (urls.length === 0) {
        return;
    }

    event.waitUntil(caches.open(guildIconCacheName).then((cache) => {
        return cache.keys().then((existingRequests) => {
            const wantedUrls = new Set(urls);
            const existingUrls = new Set(existingRequests.map((req) => req.url));

            // Drop icons for guilds the user is no longer a part of
            const removals = existingRequests
                .filter((req) => !wantedUrls.has(req.url))
                .map((req) => cache.delete(req));

            // Fetch and store any icons we don't already have
            const additions = urls
                .filter((url) => !existingUrls.has(url))
                .map((url) => cache.add(url).catch(() => {}));

            return Promise.all(removals.concat(additions));
        });
    }));
});
