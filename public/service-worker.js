console.log("service-worker");
// Register event listener for the 'push' event.
self.addEventListener('push', function(event) {
    try
    {
        const data = event.data.json().notification;

        self.registration.showNotification(
            data.title,
            { body: data.body
            , icon: data.icon
            });
    }
    catch(error)
    {
        self.registration.showNotification("error", { body : error });
    }
});


// Original code found here https://developer.chrome.com/docs/workbox/caching-strategies-overview/#cache_first_falling_back_to_network
// Establish a cache name
const cacheName = 'resource_cache_v1';

self.addEventListener('fetch', (event) => {
    // Check if this is a request for an image
    const url = event.request.url;
    console.log(url);

    //const domain = 'https://at-chat.app';
    const domain = 'https://https://at-chat.app/';
    if (url.startsWith(domain + '/file/t/')
        || url.startsWith(domain + '/file/0')
        || url.startsWith(domain + '/file/1')
        || url.startsWith(domain + '/file/2')
        || url.startsWith(domain + '/file/3')
        || url.startsWith(domain + '/file/4')
        || url.startsWith(domain + '/file/5')
        || url.startsWith(domain + '/file/6')
        || url.startsWith(domain + '/file/7')
        || url.startsWith(domain + '/file/8')
        || url.startsWith(domain + '/file/9')
        ) {
        console.log(event.request.destination);
        event.respondWith(caches.open(cacheName).then((cache) => {
            // Go to the cache first
            return cache.match(url).then((cachedResponse) => {
                // Return a cached response if we have one
                if (cachedResponse) {
                    return cachedResponse;
                }

                // Otherwise, hit the network
                return fetch(event.request).then((fetchedResponse) => {
                    const clone = fetchedResponse.clone();

                    console.log(fetchedResponse);
                    console.log(fetchedResponse.headers["Content-Length"]);
                    console.log(fetchedResponse.headers.entries());
                    console.log(fetchedResponse.headers.get("Content-Length"));
                    console.log(fetchedResponse.headers["content-length"]);
                    console.log(fetchedResponse.headers.entries());
                    console.log(fetchedResponse.headers.get("content-length"));

                    if (fetchedResponse.ok && Number(fetchedResponse.headers["Content-Length"]) < 1000 * 1000) {
                        cache.put(event.request, clone);
                    }

                    return fetchedResponse;
                });
            });
        }));
    } else {
    return;
    }
});