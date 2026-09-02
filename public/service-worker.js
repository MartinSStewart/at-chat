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

// Number of unread messages shown on the app icon (home screen, dock, taskbar) via
// the Badging API. The app itself sets this to the number of messages with a red
// notification circle whenever that count changes, and each push that arrives while
// the app is closed adds one to it. It's kept in Cache Storage rather than a variable
// because the service worker is shut down between pushes, so an in-memory count would
// be back to zero by the time the next one arrives, and because the app writes the
// same entry (see set_app_badge_to_js in elm-pkg-js/stuff.js).
const badgeCountCacheName = 'app_badge_count';

const badgeCountKey = 'count';

async function incrementAppBadge() {
    if (!("setAppBadge" in navigator)) {
        return;
    }

    let count = 1;

    // Failing to read or write the count is not a reason to skip the badge itself,
    // so this gets its own try/catch and falls back to showing a count of one.
    try {
        const cache = await caches.open(badgeCountCacheName);
        const stored = await cache.match(badgeCountKey);

        if (stored) {
            const previous = Number(await stored.text());

            if (Number.isFinite(previous) && previous > 0) {
                count = previous + 1;
            }
        }

        await cache.put(
            badgeCountKey,
            new Response(String(count), {
                status: 200,
                statusText: 'OK',
                headers: { 'Content-Type': 'text/plain' }
            })
        );
    }
    catch (error) {
        log("Badge count storage error: " + error.message);
    }

    try {
        // Browsers that only badge installed apps reject this when the site is
        // running in a normal tab, which is nothing to worry about.
        await navigator.setAppBadge(count);
    }
    catch (error) {
        log("Set app badge error: " + error.message);
    }
}

// Register event listener for the 'push' event.
self.addEventListener('push', function(event) {
    // The badge write is async, so the work has to be wrapped in waitUntil to stop
    // the service worker being terminated halfway through it.
    event.waitUntil((async () => {
        try
        {
            const data = event.data.json().notification;

            await self.registration.showNotification(
                data.title,
                { body: data.body
                , icon: data.icon
                , data: data.data
                });
            await incrementAppBadge();
            log("Push event: " + JSON.stringify(event.data.json()));
        }
        catch(error)
        {
            log("Push event error: " + error.message);
        }
    })());
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


// Keys for encrypted file attachments, written by the page (see fileKeyWithStore in
// elm-pkg-js/stuff.js) and only ever read here. Each entry is a non-exportable CryptoKey
// stored under the hash the ciphertext is served at, so the raw key is never on disk and
// this worker can decrypt without being able to hand the key to anything else.
const fileKeyDbName = "at-chat-file-keys";
const fileKeyStoreName = "file-keys";

function fileKeyOpenDb() {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(fileKeyDbName, 1);
        request.onerror = () => reject(request.error);
        request.onupgradeneeded = () => {
            // The page normally creates the store first. Creating it here too means a
            // request that arrives before the page has stored anything opens an empty
            // store rather than a database with no store in it.
            if (!request.result.objectStoreNames.contains(fileKeyStoreName)) {
                request.result.createObjectStore(fileKeyStoreName);
            }
        };
        request.onsuccess = () => resolve(request.result);
    });
}

function readFileKey(fileHash) {
    return fileKeyOpenDb().then(db => new Promise((resolve, reject) => {
        const transaction = db.transaction(fileKeyStoreName, "readonly");
        const request = transaction.objectStore(fileKeyStoreName).get(fileHash);
        request.onerror = () => { db.close(); reject(request.error); };
        request.onsuccess = () => { db.close(); resolve(request.result); };
    }));
}

// The page stores a key as it decrypts the message the file is attached to, and the
// browser can ask for the file before that write has landed. Only encrypted files reach
// this, so waiting costs nothing anywhere else.
const fileKeyWaitAttempts = 20;

const fileKeyWaitMs = 100;

async function waitForFileKey(fileHash) {
    for (let attempt = 0; attempt < fileKeyWaitAttempts; attempt++) {
        try {
            const key = await readFileKey(fileHash);

            if (key) {
                return key;
            }
        } catch (error) {
            log("File key lookup error: " + error.message);
            return null;
        }

        await new Promise((resolve) => setTimeout(resolve, fileKeyWaitMs));
    }

    return null;
}

// Encrypted attachments are addressed as /file/e/<content type>/<hash> so that this worker
// knows to decrypt them, and so that a browser without it installed gets a plain 404
// instead of rendering ciphertext. The bytes themselves are stored at the ordinary
// /file/<content type>/<hash>, which is what gets fetched here.
async function decryptedFileResponse(encryptedUrl) {
    const rest = encryptedUrl.slice(encryptedUrl.indexOf('/file/e/') + '/file/e/'.length);
    const separator = rest.indexOf('/');

    if (separator < 0) {
        return new Response("Not an encrypted file address", { status: 404 });
    }

    const fileHash = rest.slice(separator + 1);

    // The bytes themselves sit at the ordinary address. The content type is part of it, so
    // the response that comes back names the type correctly even though what it served was
    // ciphertext.
    const cipherTextUrl = encryptedUrl.replace('/file/e/', '/file/');

    const key = await waitForFileKey(fileHash);

    if (!key) {
        return new Response("No key is stored on this device for that file", { status: 404 });
    }

    // Only the ciphertext is cached. Keeping the decrypted body out of Cache Storage means
    // a file that is encrypted on the server isn't sitting in the clear on disk here.
    const cache = await caches.open(cacheName);
    let cipherTextResponse = await cache.match(cipherTextUrl);

    if (!cipherTextResponse) {
        cipherTextResponse = await fetch(cipherTextUrl);

        if (!cipherTextResponse.ok) {
            return cipherTextResponse;
        }
    }

    const contentType = cipherTextResponse.headers.get("content-type") || "application/octet-stream";

    // Read once and cache from the bytes rather than caching a clone. Draining two branches
    // of a teed body truncates whichever is read second once it runs past the browser's tee
    // buffer, which is the same trap the frontend bundle above works around.
    const cipherText = await cipherTextResponse.arrayBuffer();

    if (cipherText.byteLength < 1000 * 1000) {
        await cache.put(
            cipherTextUrl,
            new Response(cipherText, { status: 200, headers: { "Content-Type": contentType } }));
    }

    try {
        const plainText = await crypto.subtle.decrypt(
            { name: "AES-GCM", iv: cipherText.slice(0, 12) }, key, cipherText.slice(12));

        return new Response(plainText, {
            status: 200,
            statusText: "OK",
            headers: { "Content-Type": contentType }
        });
    } catch (error) {
        log("File decrypt error: " + error.message);
        return new Response("This file could not be decrypted", { status: 404 });
    }
}

self.addEventListener('fetch', (event) => {
    try
    {
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

    if (url.startsWith(domain + 'file/e/')) {
        event.respondWith(decryptedFileResponse(url));
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
    }
    catch (error)
    {
        log("Fetch event error: " + error.message);
    }
});