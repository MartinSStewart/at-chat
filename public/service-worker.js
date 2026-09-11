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

self.addEventListener('install', (event) => {
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

const badgeCountCacheName = 'app_badge_count';

const badgeCountKey = 'count';

async function incrementAppBadge() {
    if (!("setAppBadge" in navigator)) {
        return;
    }

    let count = 1;

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
        await navigator.setAppBadge(count);
    }
    catch (error) {
        log("Set app badge error: " + error.message);
    }
}

const e2eeDbName = "at-chat-e2ee";
const e2eeStoreName = "dm-keys";

function e2eeOpenDb() {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(e2eeDbName, 1);
        request.onerror = () => reject(request.error);
        request.onupgradeneeded = () => {
            if (!request.result.objectStoreNames.contains(e2eeStoreName)) {
                request.result.createObjectStore(e2eeStoreName);
            }
        };
        request.onsuccess = () => resolve(request.result);
    });
}

function readConversationKey(otherUserId) {
    return e2eeOpenDb().then(db => new Promise((resolve, reject) => {
        const transaction = db.transaction(e2eeStoreName, "readonly");
        const request = transaction.objectStore(e2eeStoreName).get(otherUserId);
        request.onerror = () => { db.close(); reject(request.error); };
        request.onsuccess = () => { db.close(); resolve(request.result); };
    }));
}

async function decryptNotificationBody(sentBy, encryptedBody) {
    if (typeof sentBy !== "number" || typeof encryptedBody !== "string") {
        return "Error while decrypting message";
    }

    try {
        const key = await readConversationKey(sentBy);

        if (!key) {
            return "Private key missing, message couldn't be decrypted.";
        }

        const bytes = Uint8Array.from(atob(encryptedBody), (character) => character.charCodeAt(0));

        const plainText = await crypto.subtle.decrypt(
            { name: "AES-GCM", iv: bytes.slice(0, 12) }, key, bytes.slice(12));

        return new TextDecoder().decode(plainText);
    }
    catch (error) {
        log("Notification decryption error: " + error.message);
        return "Message decryption failed";
    }
}

self.addEventListener('push', function(event) {
    event.waitUntil((async () => {
        try
        {
            const data = event.data.json().notification;

            const decrypted = data.encrypted_body === undefined
                ? null
                : await decryptNotificationBody(data.sent_by, data.encrypted_body);

            await self.registration.showNotification(
                data.title,
                { body: decrypted === null ? data.body : decrypted
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

        event.waitUntil(
            clients.matchAll({ type: "window", includeUncontrolled: true })
                .then((windowClients) => {
                    for (const client of windowClients) {
                        if ('focus' in client) {
                            client.postMessage(notificationData);
                            return client.focus();
                        }
                    }

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

// Where application/octet-stream sits in the server's content type list (see
// rust-server/src/content_types.rs and FileStatus.contentTypes, which are the same list in
// the same order). The ciphertext is asked for under this so that the server is never told
// what kind of file it is holding.
const octetStreamContentType = 136;

// A thumbnail the browser made is webp where it could write one and jpeg where it couldn't,
// and the address it is served from says neither, so the first bytes are what tell the two
// apart. Jpeg is the one worth spotting: anything else the page is handed here was written
// as webp.
function thumbnailContentType(plainText) {
    const bytes = new Uint8Array(plainText, 0, Math.min(3, plainText.byteLength));

    return bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff
        ? "image/jpeg"
        : "image/webp";
}


async function decryptedFileResponse(isDevelopment, encryptedUrl) {
    const start = encryptedUrl.indexOf('/file/e/');
    const rest = encryptedUrl.slice(start + '/file/e/'.length);
    const separator = rest.indexOf('/');

    if (separator < 0) {
        return new Response("Not an encrypted file address", { status: 404 });
    }

    const fileHash = rest.slice(separator + 1);

    // Thumbnails the browser made sit where the server's own thumbnails do, so their
    // address never carried a content type in the first place. What kind of image one is
    // comes out of the bytes once they have been decrypted.
    const isThumbnail = rest.slice(0, separator) === 't';

    const contentType = isThumbnail
        ? null
        : decodeURIComponent(rest.slice(0, separator));

    const origin = encryptedUrl.slice(0, start);

    let cipherTextUrl = isThumbnail
        ? origin + '/file/t/' + fileHash
        : origin + '/file/' + octetStreamContentType + '/' + fileHash;
    if (isDevelopment) {
        cipherTextUrl = "http://localhost:8001/" + cipherTextUrl;
    }

    const key = await waitForFileKey(fileHash);

    if (!key) {
        return new Response("No key is stored on this device for that file", { status: 404 });
    }

    const cache = await caches.open(cacheName);
    let cipherTextResponse = await cache.match(cipherTextUrl);

    if (!cipherTextResponse) {
        cipherTextResponse = await fetch(cipherTextUrl);

        if (!cipherTextResponse.ok) {
            return cipherTextResponse;
        }
    }

    const cipherText = await cipherTextResponse.arrayBuffer();

    if (cipherText.byteLength < 1000 * 1000) {
        await cache.put(
            cipherTextUrl,
            new Response(cipherText, { status: 200, headers: { "Content-Type": "application/octet-stream" } }));
    }

    try {
        const plainText = await crypto.subtle.decrypt(
            { name: "AES-GCM", iv: cipherText.slice(0, 12) }, key, cipherText.slice(12));

        return new Response(plainText, {
            status: 200,
            statusText: "OK",
            headers: {
                "Content-Type": contentType === null
                    ? thumbnailContentType(plainText)
                    : contentType
            }
        });
    } catch (error) {
        log("File decrypt error: " + error.message);
        return new Response("This file could not be decrypted", { status: 404 });
    }
}

self.addEventListener('fetch', (event) => {
    try
    {
    const url = event.request.url;

    const isDevelopment = self.location.origin.startsWith("http://localhost:");

    const domain = self.location.origin + '/';
    let apiDomain = domain;
    if (isDevelopment) {
        apiDomain = "http://localhost:3000/";
    }

    // The hashed frontend bundle, e.g. https://at-chat.app/frontend.a1b2c3.js
    if (url.startsWith(domain + 'frontend.') && url.endsWith('.js')) {
        event.respondWith(caches.open(frontendCacheName).then(async (cache) => {
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
                // to the browser's tee buffer limit (~320 KiB).
                const cachedFetchedResponse = await cache.match(event.request);
                if (cachedFetchedResponse) {
                    return cachedFetchedResponse;
                }
            }
            return fetchedResponse;
        }));
        return;
    }

    if (url.startsWith(apiDomain + 'file/e/')) {
        event.respondWith(decryptedFileResponse(isDevelopment, url));
        return;
    }

    if (url.startsWith(apiDomain + 'file/t/')
        || url.startsWith(apiDomain + 'file/0')
        || url.startsWith(apiDomain + 'file/1')
        || url.startsWith(apiDomain + 'file/2')
        || url.startsWith(apiDomain + 'file/3')
        || url.startsWith(apiDomain + 'file/4')
        || url.startsWith(apiDomain + 'file/5')
        || url.startsWith(apiDomain + 'file/6')
        || url.startsWith(apiDomain + 'file/7')
        || url.startsWith(apiDomain + 'file/8')
        || url.startsWith(apiDomain + 'file/9')
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