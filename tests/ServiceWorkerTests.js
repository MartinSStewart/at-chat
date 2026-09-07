// Checks that public/service-worker.js decrypts an encrypted attachment the way
// elm-pkg-js/stuff.js encrypted it. The end-to-end tests can't reach this: they run the Elm
// app without a browser, and a service worker only exists inside one.
//
// Run with: node tests/ServiceWorkerTests.js

const fs = require("fs");
const path = require("path");
const vm = require("vm");

// Deliberately not at-chat.app: the worker takes the domain it intercepts from wherever it
// was served, so serving it from somewhere else is what shows it isn't hardcoded. This one
// isn't a localhost address either, so the worker is exercised the way it runs deployed,
// where the app and the files share an origin.
const origin = "https://at-chat.example";

const domain = origin + "/";

const fileHash = "abc123";

const contentType = "image/png";

// Where the encrypted address names the file's type, spelled out and percent encoded rather
// than numbered (see FileStatus.encryptedFileUrl).
const encryptedUrl = domain + "file/e/" + encodeURIComponent(contentType) + "/" + fileHash;

// Where the ciphertext itself is asked for: application/octet-stream, whatever the file
// turns out to be, so the server is never told what kind of file it is holding.
const octetStreamUrl = domain + "file/136/" + fileHash;

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
    const servedFrom = options.origin === undefined ? origin : options.origin;

    const context = {
        self: {
            addEventListener: (name, handler) => { listeners[name] = handler; },
            skipWaiting: () => Promise.resolve(),
            clients: { claim: () => Promise.resolve() },
            registration: {},
            // Where the worker script itself was served from.
            location: { origin: servedFrom, href: servedFrom + "/service-worker.js" }
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

function readRepoFile(relativePath) {
    return fs.readFileSync(path.join(__dirname, "..", relativePath), "utf8");
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

    function expectEqual(actual, expected, what) {
        const actualText = JSON.stringify(actual);
        const expectedText = JSON.stringify(expected);

        if (actualText !== expectedText) {
            throw new Error(what + " was " + actualText + " rather than " + expectedText);
        }
    }

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
        octetStreamUrl,
        () => new Response(encrypted.cipherText, {
            status: 200,
            headers: { "Content-Type": "application/octet-stream" }
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

        const response = await requestFile(listeners, encryptedUrl);
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
        const response = await requestFile(listeners, encryptedUrl);
        const body = new Uint8Array(await response.arrayBuffer());

        if (fetchCount !== before) {
            throw new Error("The second read went back to the network");
        }

        if (Buffer.compare(Buffer.from(body), Buffer.from(plainText)) !== 0) {
            throw new Error("The body read back out of the cache isn't the file");
        }

        // What's stored has to still be unreadable, otherwise caching has undone the
        // encryption for anything that can read Cache Storage.
        const cached = await (await caches.open("resource_cache_v1")).match(octetStreamUrl);
        const cachedBody = new Uint8Array(await cached.arrayBuffer());

        if (Buffer.compare(Buffer.from(cachedBody), Buffer.from(plainText)) === 0) {
            throw new Error("The decrypted file was written to the cache");
        }
    });

    // The address the ciphertext is read from is all the server learns about an encrypted
    // attachment, so it must not name the kind of file it is holding.
    await check("The server isn't told what kind of file the ciphertext is", async () => {
        const asked = [];

        const askedListeners = loadServiceWorker({
            indexedDB: fakeIndexedDb(databases),
            caches: fakeCaches(),
            fetch: (request) => {
                asked.push(cacheKey(request));
                return Promise.resolve(new Response(encrypted.cipherText, { status: 200 }));
            }
        });

        const response = await requestFile(askedListeners, encryptedUrl);

        expectEqual(asked, [octetStreamUrl], "the address the ciphertext was read from");

        if (response.headers.get("content-type") !== contentType) {
            throw new Error(
                "The decrypted file was handed back as "
                    + response.headers.get("content-type"));
        }
    });

    await check("A file with no key stored is refused rather than served raw", async () => {
        const unknownHash = "no-key-here";
        served.set(
            domain + "file/136/" + unknownHash,
            () => new Response(encrypted.cipherText, { status: 200 }));

        const response = await requestFile(
            listeners, domain + "file/e/" + encodeURIComponent(contentType) + "/" + unknownHash);

        if (response.status === 200) {
            throw new Error("Ciphertext was handed to the page as if it were the file");
        }
    });

    // A thumbnail is stored under the file's hash and encrypted with the file's key, so
    // taking the /file/e/ off the front of its address finds it where the server already
    // serves thumbnails from, and the key is already there to open it.
    await check("An encrypted thumbnail is served decrypted as webp", async () => {
        const thumbnail = crypto.getRandomValues(new Uint8Array(256));
        const encryptedThumbnail = await crypto.subtle.encrypt(
            { name: "AES-GCM", iv: encrypted.cipherText.slice(0, 12) },
            encrypted.key,
            thumbnail);

        // The same shape the page uploads: a fresh iv in front of the ciphertext.
        const combined = new Uint8Array(12 + encryptedThumbnail.byteLength);
        combined.set(encrypted.cipherText.slice(0, 12), 0);
        combined.set(new Uint8Array(encryptedThumbnail), 12);

        served.set(
            domain + "file/t/" + fileHash,
            () => new Response(combined, {
                status: 200,
                headers: { "Content-Type": "image/webp" }
            }));

        const response = await requestFile(listeners, domain + "file/e/t/" + fileHash);
        const body = new Uint8Array(await response.arrayBuffer());

        if (response.status !== 200) {
            throw new Error("Got status " + response.status);
        }

        if (response.headers.get("content-type") !== "image/webp") {
            throw new Error("Got content type " + response.headers.get("content-type"));
        }

        if (Buffer.compare(Buffer.from(body), Buffer.from(thumbnail)) !== 0) {
            throw new Error("The body isn't the thumbnail that was encrypted");
        }
    });

    await check("A file served from somewhere else is left alone", async () => {
        const elsewhere =
            "https://somewhere-else.example/file/e/" + encodeURIComponent(contentType) + "/" + fileHash;
        served.set(elsewhere, () => new Response(encrypted.cipherText, { status: 200 }));

        let responded = false;
        listeners.fetch({ request: { url: elsewhere }, respondWith: () => { responded = true; } });

        if (responded) {
            throw new Error("The worker answered for an address outside the origin it was served from");
        }
    });

    await check("An unencrypted file is left alone", async () => {
        const response = await requestFile(listeners, octetStreamUrl);
        const body = new Uint8Array(await response.arrayBuffer());

        if (Buffer.compare(Buffer.from(body), Buffer.from(encrypted.cipherText)) !== 0) {
            throw new Error("The plain address didn't serve what the server sent");
        }
    });

    // Running locally, lamdera live and the rust server are on different ports, so reading
    // the ciphertext is a cross origin fetch that the file endpoints send no cors header
    // for. The worker goes through the proxy on 8001 to get at it. Deployed there is no
    // proxy and no second origin, which every test above covers.
    await check("Locally the ciphertext is fetched through the proxy", async () => {
        const localDatabases = new Map();
        localDatabases.set(
            "at-chat-file-keys",
            new Map([["file-keys", new Map([[fileHash, encrypted.key]])]]));

        const asked = [];

        const localListeners = loadServiceWorker({
            origin: "http://localhost:8000",
            indexedDB: fakeIndexedDb(localDatabases),
            caches: fakeCaches(),
            fetch: (request) => {
                asked.push(cacheKey(request));
                return Promise.resolve(new Response(encrypted.cipherText, {
                    status: 200,
                    headers: { "Content-Type": contentType }
                }));
            }
        });

        const response = await requestFile(
            localListeners,
            "http://localhost:3000/file/e/" + encodeURIComponent(contentType) + "/" + fileHash);
        const body = new Uint8Array(await response.arrayBuffer());

        expectEqual(
            asked,
            ["http://localhost:8001/http://localhost:3000/file/136/" + fileHash],
            "the address the ciphertext was read from");

        if (Buffer.compare(Buffer.from(body), Buffer.from(plainText)) !== 0) {
            throw new Error("The body isn't the file that was encrypted");
        }
    });

    // The worker asks for the ciphertext under a hardcoded index into the server's content
    // type list, and the type it puts on the decrypted file comes from Elm rather than from
    // the server's answer. Both stop being right the moment the two lists drift apart.
    await check("The content type lists agree with the index the worker uses", async () => {
        const quoted = (text) => Array.from(text.matchAll(/"([^"]*)"/g), (match) => match[1]);

        const elmSource = readRepoFile("src/FileStatus.elm");
        const elmStart = elmSource.indexOf("contentTypes : OneToOne ContentType String");
        const elmList = quoted(
            elmSource.slice(elmStart, elmSource.indexOf("]", elmStart)));

        const rustSource = readRepoFile("rust-server/src/content_types.rs");
        const rustList = quoted(
            rustSource.slice(rustSource.indexOf("["), rustSource.indexOf("];")));

        expectEqual(elmList.length, rustList.length, "the number of content types");

        // FileStatus.contentTypeHeader adds the charset back on, so the two lists only
        // line up once the same rule is applied here.
        const mismatch = elmList.findIndex((contentType2, index) =>
            (contentType2.startsWith("text/") ? contentType2 + "; charset=UTF-8" : contentType2)
                !== rustList[index]);

        if (mismatch >= 0) {
            throw new Error(
                "Entry " + mismatch + " is " + elmList[mismatch] + " in Elm and "
                    + rustList[mismatch] + " in Rust");
        }

        const worker = readRepoFile("public/service-worker.js");
        const index = Number(/const octetStreamContentType = (\d+);/.exec(worker)[1]);

        expectEqual(
            [elmList[index], rustList[index]],
            ["application/octet-stream", "application/octet-stream"],
            "what the worker's octet stream index names");
    });

    if (failures.length > 0) {
        console.log("\n" + failures.length + " service worker test(s) failed");
        process.exit(1);
    }

    console.log("\nAll service worker tests passed!");
}

run().catch((error) => { console.error(error); process.exit(1); });
