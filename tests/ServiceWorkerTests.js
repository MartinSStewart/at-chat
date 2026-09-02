// Checks that public/service-worker.js decrypts an encrypted attachment the way
// elm-pkg-js/stuff.js encrypted it. The end-to-end tests can't reach this: they run the Elm
// app without a browser, and a service worker only exists inside one.
//
// Run with: node tests/ServiceWorkerTests.js

const fs = require("fs");
const path = require("path");
const vm = require("vm");

const domain = "https://at-chat.app/";

const fileHash = "abc123";

const contentType = "image/png";

// What stuff.js writes when it encrypts a file: a fresh key, and a 12 byte IV in front of
// the ciphertext so that decrypting needs nothing but the one blob.
async function encryptFile(plainText) {
    const key = await crypto.subtle.generateKey(
        { name: "AES-GCM", length: 256 }, true, ["encrypt", "decrypt"]);

    const iv = crypto.getRandomValues(new Uint8Array(12));
    const cipherText = await crypto.subtle.encrypt({ name: "AES-GCM", iv: iv }, key, plainText);

    const combined = new Uint8Array(iv.length + cipherText.byteLength);
    combined.set(iv, 0);
    combined.set(new Uint8Array(cipherText), iv.length);

    return { key: key, cipherText: combined };
}

// Just enough IndexedDB for the two functions the service worker uses. Databases are a Map
// of store name to a Map of key to value.
function fakeIndexedDb(databases) {
    return {
        open(name) {
            const request = { result: null, error: null };

            queueMicrotask(() => {
                const isNew = !databases.has(name);

                if (isNew) {
                    databases.set(name, new Map());
                }

                request.result = {
                    objectStoreNames: { contains: (store) => databases.get(name).has(store) },
                    createObjectStore: (store) => databases.get(name).set(store, new Map()),
                    transaction: (store) => ({
                        objectStore: (storeName) => ({
                            get(key) {
                                const getRequest = { result: undefined };
                                queueMicrotask(() => {
                                    getRequest.result = databases.get(name).get(storeName).get(key);
                                    if (getRequest.onsuccess) { getRequest.onsuccess(); }
                                });
                                return getRequest;
                            },
                            add() { return { }; }
                        })
                    }),
                    close() {}
                };

                if (isNew && request.onupgradeneeded) {
                    request.onupgradeneeded({ target: request });
                }

                if (request.onsuccess) {
                    request.onsuccess({ target: request });
                }
            });

            return request;
        }
    };
}

// The real Cache API keys entries by url whether it is handed a Request or a string, so
// this does the same rather than telling the two apart.
function cacheKey(request) {
    return typeof request === "string" ? request : request.url;
}

function fakeCaches() {
    const caches = new Map();

    return {
        open(name) {
            if (!caches.has(name)) {
                caches.set(name, new Map());
            }

            const entries = caches.get(name);

            return Promise.resolve({
                // The real Cache API hands out a fresh Response each time, so reading one
                // entry twice has to work here too.
                match: (key) => {
                    const stored = entries.get(cacheKey(key));
                    return Promise.resolve(stored === undefined ? undefined : stored.clone());
                },
                put: (key, response) => { entries.set(cacheKey(key), response); return Promise.resolve(); },
                keys: () => Promise.resolve([...entries.keys()]),
                delete: (key) => { entries.delete(cacheKey(key)); return Promise.resolve(); },
                matchAll: () => Promise.resolve([...entries.values()])
            });
        }
    };
}

function loadServiceWorker(options) {
    const listeners = {};

    const context = {
        self: {
            addEventListener: (name, handler) => { listeners[name] = handler; },
            skipWaiting: () => Promise.resolve(),
            clients: { claim: () => Promise.resolve() },
            registration: {}
        },
        indexedDB: options.indexedDB,
        caches: options.caches,
        fetch: options.fetch,
        crypto: crypto,
        Response: Response,
        Request: Request,
        setTimeout: setTimeout,
        console: console,
        navigator: {},
        Date: Date,
        Math: Math,
        Number: Number,
        String: String,
        Promise: Promise,
        Uint8Array: Uint8Array
    };

    context.clients = context.self.clients;
    vm.createContext(context);
    vm.runInContext(
        fs.readFileSync(path.join(__dirname, "..", "public", "service-worker.js"), "utf8"),
        context);

    return listeners;
}

// The service worker answers with respondWith, so the response has to be caught on the way
// past rather than returned.
function requestFile(listeners, url) {
    let responded = null;

    listeners.fetch({
        request: { url: url },
        respondWith: (response) => { responded = response; }
    });

    if (responded === null) {
        throw new Error("The service worker didn't answer " + url);
    }

    return responded;
}

async function run() {
    const failures = [];

    async function check(name, body) {
        try {
            await body();
            console.log("  passed: " + name);
        } catch (error) {
            failures.push(name + ": " + error.message);
            console.log("  FAILED: " + name + ": " + error.message);
        }
    }

    const plainText = crypto.getRandomValues(new Uint8Array(2048));
    const encrypted = await encryptFile(plainText);

    const databases = new Map();
    databases.set("at-chat-file-keys", new Map([["file-keys", new Map()]]));

    const served = new Map();
    served.set(
        domain + "file/2/" + fileHash,
        () => new Response(encrypted.cipherText, {
            status: 200,
            headers: { "Content-Type": contentType }
        }));

    let fetchCount = 0;

    const caches = fakeCaches();

    const listeners = loadServiceWorker({
        indexedDB: fakeIndexedDb(databases),
        caches: caches,
        fetch: (request) => {
            fetchCount++;
            const handler = served.get(cacheKey(request));
            return Promise.resolve(
                handler ? handler() : new Response("Not found", { status: 404 }));
        }
    });

    await check("An encrypted attachment is served decrypted", async () => {
        // Stored the way stuff.js stores it: imported back from the raw bytes as a key that
        // can only decrypt and that the browser won't hand out again.
        const storedKey = await crypto.subtle.importKey(
            "raw",
            await crypto.subtle.exportKey("raw", encrypted.key),
            "AES-GCM",
            false,
            ["decrypt"]);

        databases.get("at-chat-file-keys").get("file-keys").set(fileHash, storedKey);

        const response = await requestFile(listeners, domain + "file/e/2/" + fileHash);
        const body = new Uint8Array(await response.arrayBuffer());

        if (response.status !== 200) {
            throw new Error("Got status " + response.status);
        }

        if (response.headers.get("content-type") !== contentType) {
            throw new Error("Got content type " + response.headers.get("content-type"));
        }

        if (Buffer.compare(Buffer.from(body), Buffer.from(plainText)) !== 0) {
            throw new Error("The body isn't the file that was encrypted");
        }
    });

    await check("The ciphertext is cached, not the decrypted bytes", async () => {
        const before = fetchCount;
        const response = await requestFile(listeners, domain + "file/e/2/" + fileHash);
        const body = new Uint8Array(await response.arrayBuffer());

        if (fetchCount !== before) {
            throw new Error("The second read went back to the network");
        }

        if (Buffer.compare(Buffer.from(body), Buffer.from(plainText)) !== 0) {
            throw new Error("The body read back out of the cache isn't the file");
        }

        // What's stored has to still be unreadable, otherwise caching has undone the
        // encryption for anything that can read Cache Storage.
        const cached = await (await caches.open("resource_cache_v1"))
            .match(domain + "file/2/" + fileHash);
        const cachedBody = new Uint8Array(await cached.arrayBuffer());

        if (Buffer.compare(Buffer.from(cachedBody), Buffer.from(plainText)) === 0) {
            throw new Error("The decrypted file was written to the cache");
        }
    });

    await check("A file with no key stored is refused rather than served raw", async () => {
        const unknownHash = "no-key-here";
        served.set(
            domain + "file/2/" + unknownHash,
            () => new Response(encrypted.cipherText, { status: 200 }));

        const response = await requestFile(listeners, domain + "file/e/2/" + unknownHash);

        if (response.status === 200) {
            throw new Error("Ciphertext was handed to the page as if it were the file");
        }
    });

    await check("An unencrypted file is left alone", async () => {
        const response = await requestFile(listeners, domain + "file/2/" + fileHash);
        const body = new Uint8Array(await response.arrayBuffer());

        if (Buffer.compare(Buffer.from(body), Buffer.from(encrypted.cipherText)) !== 0) {
            throw new Error("The plain address didn't serve what the server sent");
        }
    });

    if (failures.length > 0) {
        console.log("\n" + failures.length + " service worker test(s) failed");
        process.exit(1);
    }

    console.log("\nAll service worker tests passed!");
}

run().catch((error) => { console.error(error); process.exit(1); });
