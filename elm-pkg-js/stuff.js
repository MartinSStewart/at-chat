// Encode an ArrayBuffer (such as a push subscription's applicationServerKey)
// as an unpadded base64url string so it can be compared against the VAPID
// public key string we get from the server.
function arrayBufferToBase64Url(buffer) {
    if (!buffer) { return null; }
    const bytes = new Uint8Array(buffer);
    let binary = "";
    for (let i = 0; i < bytes.byteLength; i++) {
        binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary)
        .replace(/\+/g, "-")
        .replace(/\//g, "_")
        .replace(/=+$/, "");
}

// --- End-to-end encryption -------------------------------------------------------
//
// The symmetric key for a DM is derived from the shared secret Elm worked out, then kept
// in IndexedDB as a CryptoKey the browser will not export. Storing the handle rather than
// the bytes is the whole point: nothing on the page can read the key back out afterwards,
// it can only ask for something to be encrypted with it.

const e2eeDbName = "at-chat-e2ee";
const e2eeStoreName = "dm-keys";

function e2eeOpenDb() {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(e2eeDbName, 1);
        request.onupgradeneeded = () => {
            if (!request.result.objectStoreNames.contains(e2eeStoreName)) {
                request.result.createObjectStore(e2eeStoreName);
            }
        };
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
    });
}

function e2eeWithStore(mode, run) {
    return e2eeOpenDb().then(db => new Promise((resolve, reject) => {
        const transaction = db.transaction(e2eeStoreName, mode);
        const request = run(transaction.objectStore(e2eeStoreName));
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
        transaction.oncomplete = () => db.close();
    }));
}

// Keys for encrypted file attachments, which the service worker reads so that it can
// decrypt a file the browser fetches on its own (see public/service-worker.js). Kept apart
// from the conversation keys above so the service worker never opens that database, and so
// adding this store didn't need a version bump on one already in use.
const fileKeyDbName = "at-chat-file-keys";
const fileKeyStoreName = "file-keys";

function fileKeyOpenDb() {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(fileKeyDbName, 1);
        request.onerror = () => reject(request.error);
        request.onupgradeneeded = () => {
            if (!request.result.objectStoreNames.contains(fileKeyStoreName)) {
                request.result.createObjectStore(fileKeyStoreName);
            }
        };
        request.onsuccess = () => resolve(request.result);
    });
}

function fileKeyWithStore(mode, run) {
    return fileKeyOpenDb().then(db => new Promise((resolve, reject) => {
        const transaction = db.transaction(fileKeyStoreName, mode);
        const request = run(transaction.objectStore(fileKeyStoreName));
        request.onerror = () => { db.close(); reject(request.error); };
        request.onsuccess = () => { db.close(); resolve(request.result); };
    }));
}


const e2eeSerializeVersion = 1;

const e2eeToJsStoreSharedSecret = 0;
const e2eeToJsEncryptMessage = 1;
const e2eeToJsDecryptMessage = 2;
const e2eeToJsDecryptManyMessages = 3;
const e2eeToJsEncryptManyMessages = 4;
const e2eeToJsEncryptFile = 5;
const e2eeToJsStoreFileKeys = 6;

const e2eeFromJsSharedSecretStored = 0;
const e2eeFromJsSharedSecretFailed = 1;
const e2eeFromJsMessageEncrypted = 2;
const e2eeFromJsMessageEncryptFailed = 3;
const e2eeFromJsMessageDecrypted = 4;
const e2eeFromJsMessageDecryptFailed = 5;
const e2eeFromJsManyMessagesDecrypted = 6;
const e2eeFromJsManyMessagesEncrypted = 7;
const e2eeFromJsManyMessagesEncryptFailed = 8;
const e2eeFromJsFileEncrypted = 9;
const e2eeFromJsFileEncryptFailed = 10;

function e2eeReadToJs(dataView) {
    if (dataView.byteLength < 3 || dataView.getUint8(0) !== e2eeSerializeVersion) { return null; }

    switch (dataView.getUint16(1, false)) {
        case e2eeToJsStoreSharedSecret:
            return {
                tag: "store-shared-secret",
                otherUserId: dataView.getFloat64(3, false),
                sharedSecret: e2eeReadBytesField(dataView, 11),
            };

        case e2eeToJsEncryptMessage:
            return {
                tag: "encrypt-message",
                requestId: dataView.getFloat64(3, false),
                otherUserId: dataView.getFloat64(11, false),
                data: new Uint8Array(
                    dataView.buffer, dataView.byteOffset + 19, dataView.byteLength - 19),
            };

        case e2eeToJsDecryptMessage:
            return {
                tag: "decrypt-message",
                requestId: dataView.getFloat64(3, false),
                otherUserId: dataView.getFloat64(11, false),
                data: e2eeReadBytesField(dataView, 19),
            };

        case e2eeToJsDecryptManyMessages: {
            const count = dataView.getUint32(19, false);
            const messages = [];
            let offset = 23;

            for (let i = 0; i < count; i++) {
                const message = e2eeReadBytesField(dataView, offset);
                messages.push(message);
                offset += 4 + message.length;
            }

            return {
                tag: "decrypt-many-messages",
                requestId: dataView.getFloat64(3, false),
                otherUserId: dataView.getFloat64(11, false),
                data: messages,
            };
        }

        case e2eeToJsEncryptManyMessages: {
            const count = dataView.getUint32(19, false);
            const messages = [];
            let offset = 23;

            for (let i = 0; i < count; i++) {
                const message = e2eeReadBytesField(dataView, offset);
                messages.push(message);
                offset += 4 + message.length;
            }

            return {
                tag: "encrypt-many-messages",
                requestId: dataView.getFloat64(3, false),
                otherUserId: dataView.getFloat64(11, false),
                data: messages,
            };
        }

        case e2eeToJsEncryptFile: {
            const contentTypeLength = dataView.getUint32(11, false);

            return {
                tag: "encrypt-file",
                requestId: dataView.getFloat64(3, false),
                contentType: new TextDecoder().decode(
                    new Uint8Array(dataView.buffer, dataView.byteOffset + 15, contentTypeLength)),
                data: e2eeReadBytesField(dataView, 15 + contentTypeLength),
            };
        }

        case e2eeToJsStoreFileKeys: {
            const count = dataView.getUint32(3, false);
            const keys = [];
            let offset = 7;

            for (let i = 0; i < count; i++) {
                const fileHashLength = dataView.getUint32(offset, false);
                const fileHash = new TextDecoder().decode(
                    new Uint8Array(dataView.buffer, dataView.byteOffset + offset + 4, fileHashLength));
                offset += 4 + fileHashLength;

                const key = e2eeReadBytesField(dataView, offset);
                offset += 4 + key.length;

                keys.push({ fileHash: fileHash, key: key });
            }

            return { tag: "store-file-keys", keys: keys };
        }

        default:
            return null;
    }
}

function e2eeReadBytesField(dataView, offset) {
    return new Uint8Array(
        dataView.buffer,
        dataView.byteOffset + offset + 4,
        dataView.getUint32(offset, false));
}

function e2eeIdMessage(variant, id) {
    const out = new DataView(new ArrayBuffer(11));
    out.setUint8(0, e2eeSerializeVersion);
    out.setUint16(1, variant, false);
    out.setFloat64(3, id, false);
    return out;
}

function e2eeIdAndTextMessage(variant, id, text) {
    const bytes = new TextEncoder().encode(text);
    const out = new DataView(new ArrayBuffer(15 + bytes.length));
    out.setUint8(0, e2eeSerializeVersion);
    out.setUint16(1, variant, false);
    out.setFloat64(3, id, false);
    out.setUint32(11, bytes.length, false);
    new Uint8Array(out.buffer).set(bytes, 15);
    return out;
}

function e2eeMessageEncryptedMessage(requestId, bytes) {
    const out = new DataView(new ArrayBuffer(15 + bytes.length));
    out.setUint8(0, e2eeSerializeVersion);
    out.setUint16(1, e2eeFromJsMessageEncrypted, false);
    out.setFloat64(3, requestId, false);
    out.setUint32(11, bytes.length, false);
    new Uint8Array(out.buffer).set(bytes, 15);
    return out;
}

function e2eeMessageDecryptedMessage(requestId, bytes) {
    const out = new DataView(new ArrayBuffer(11 + bytes.length));
    out.setUint8(0, e2eeSerializeVersion);
    out.setUint16(1, e2eeFromJsMessageDecrypted, false);
    out.setFloat64(3, requestId, false);
    new Uint8Array(out.buffer).set(bytes, 11);
    return out;
}

function e2eeManyMessagesDecryptedMessage(requestId, results) {
    const bodies = results.map((plainText) =>
        plainText === null ? new Uint8Array(0) : plainText);
    const size = 11 + 4 + bodies.reduce((n, body) => n + 2 + body.length, 0);
    const out = new DataView(new ArrayBuffer(size));
    out.setUint8(0, e2eeSerializeVersion);
    out.setUint16(1, e2eeFromJsManyMessagesDecrypted, false);
    out.setFloat64(3, requestId, false);
    out.setUint32(11, results.length, false);

    let offset = 15;

    for (const body of bodies) {
        out.setUint16(offset, body.length === 0 ? 0 : 1, false);
        offset += 2;
        new Uint8Array(out.buffer).set(body, offset);
        offset += body.length;
    }

    return out;
}

function e2eeManyMessagesEncryptedMessage(requestId, cipherTexts) {
    const size = 11 + 4 + cipherTexts.reduce((n, c) => n + 4 + c.length, 0);
    const out = new DataView(new ArrayBuffer(size));
    out.setUint8(0, e2eeSerializeVersion);
    out.setUint16(1, e2eeFromJsManyMessagesEncrypted, false);
    out.setFloat64(3, requestId, false);
    out.setUint32(11, cipherTexts.length, false);

    let offset = 15;

    for (const cipherText of cipherTexts) {
        out.setUint32(offset, cipherText.length, false);
        offset += 4;
        new Uint8Array(out.buffer).set(cipherText, offset);
        offset += cipherText.length;
    }

    return out;
}

// The size and duration Elm reads back as a MeasuredFile (see FileStatus.elm). A Maybe is
// a variant tag of 0 or 1, a Coord is two Quantities and a Quantity is a variant tag of its
// own followed by the number, which is why each measurement is written as a tag and a
// float rather than just a float.
function e2eeMeasuredFileSize(measured) {
    if (measured === null) {
        return 2;
    }

    // Maybe tag, MeasuredFile tag, then two tagged quantities for the size.
    const size = 2 + 2 + 2 * (2 + 8);

    if (measured.kind === "image") {
        return size;
    }

    return size + (measured.durationMs === null ? 2 : 2 + 8);
}

function e2eeWriteMeasuredFile(out, offset, measured) {
    if (measured === null) {
        out.setUint16(offset, 0, false);
        return;
    }

    out.setUint16(offset, 1, false);
    out.setUint16(offset + 2, measured.kind === "image" ? 0 : 1, false);
    out.setUint16(offset + 4, 0, false);
    out.setFloat64(offset + 6, measured.width, false);
    out.setUint16(offset + 14, 0, false);
    out.setFloat64(offset + 16, measured.height, false);

    if (measured.kind === "image") {
        return;
    }

    if (measured.durationMs === null) {
        out.setUint16(offset + 24, 0, false);
    } else {
        out.setUint16(offset + 24, 1, false);
        out.setFloat64(offset + 26, measured.durationMs, false);
    }
}

// A Maybe Bytes: the variant tag, then a length and the bytes when there are any.
function e2eeMaybeBytesSize(bytes) {
    return bytes === null ? 2 : 2 + 4 + bytes.length;
}

function e2eeWriteMaybeBytes(out, offset, bytes) {
    if (bytes === null) {
        out.setUint16(offset, 0, false);
        return;
    }

    out.setUint16(offset, 1, false);
    out.setUint32(offset + 2, bytes.length, false);
    new Uint8Array(out.buffer).set(bytes, offset + 6);
}

function e2eeFileEncryptedMessage(requestId, key, cipherText, thumbnail, measured) {
    const thumbnailOffset = 19 + key.length + cipherText.length;
    const measuredOffset = thumbnailOffset + e2eeMaybeBytesSize(thumbnail);
    const out = new DataView(
        new ArrayBuffer(measuredOffset + e2eeMeasuredFileSize(measured)));
    out.setUint8(0, e2eeSerializeVersion);
    out.setUint16(1, e2eeFromJsFileEncrypted, false);
    out.setFloat64(3, requestId, false);
    out.setUint32(11, key.length, false);
    new Uint8Array(out.buffer).set(key, 15);
    out.setUint32(15 + key.length, cipherText.length, false);
    new Uint8Array(out.buffer).set(cipherText, 19 + key.length);
    e2eeWriteMaybeBytes(out, thumbnailOffset, thumbnail);
    e2eeWriteMeasuredFile(out, measuredOffset, measured);
    return out;
}

// Should match imageMaxHeight in FileStatus.elm and MAX_THUMBNAIL_HEIGHT in the rust
// server, which decide the same thing for a file that isn't encrypted.
const e2eeMaxThumbnailHeight = 600;

// What the browser can work out about a file without parsing it, and a thumbnail of it if
// it is an image big enough to want one. An image decodes to a bitmap that knows its size,
// and a video element reports its size and how long it runs once the metadata at the front
// of the file has loaded. Anything more (the EXIF a camera writes, the codec a container
// names) needs the file parsed, which is the server's job on a file it can read.
//
// The thumbnail comes from the same bitmap the size was read off, so a file is only ever
// decoded once.
async function e2eeInspectFile(bytes, contentType) {
    if (contentType.startsWith("image/")) {
        try {
            const bitmap = await createImageBitmap(
                new Blob([bytes], { type: contentType }),
                // The size the server reports has the rotation a camera asked for already
                // applied, so the size reported here has to as well.
                { imageOrientation: "from-image" });

            const inspected = {
                measured: { kind: "image", width: bitmap.width, height: bitmap.height },
                thumbnail: await e2eeThumbnail(bitmap)
            };

            bitmap.close();
            return inspected;
        } catch (error) {
            return { measured: null, thumbnail: null };
        }
    }

    if (contentType.startsWith("video/")) {
        return { measured: await e2eeMeasureVideo(bytes, contentType), thumbnail: null };
    }

    return { measured: null, thumbnail: null };
}

// Webp to match what the server makes for a file it can read, scaled down to the same box
// it uses. Asking a canvas for a type it can't write is answered with a png rather than
// with an error, so what came back has to be checked rather than trusted.
async function e2eeThumbnail(bitmap) {
    const scale = Math.min(
        (e2eeMaxThumbnailHeight * 3) / bitmap.width,
        e2eeMaxThumbnailHeight / bitmap.height,
        1);

    if (scale === 1) {
        // Small enough to be shown as it is, so a thumbnail would be no smaller than the
        // file it was made from.
        return null;
    }

    try {
        const canvas = document.createElement("canvas");
        canvas.width = Math.max(1, Math.round(bitmap.width * scale));
        canvas.height = Math.max(1, Math.round(bitmap.height * scale));
        canvas.getContext("2d").drawImage(bitmap, 0, 0, canvas.width, canvas.height);

        const blob = await new Promise((resolve) => {
            canvas.toBlob(resolve, "image/webp", 0.8);
        });

        if (blob === null || blob.type !== "image/webp") {
            return null;
        }

        return new Uint8Array(await blob.arrayBuffer());
    } catch (error) {
        return null;
    }
}

function e2eeMeasureVideo(bytes, contentType) {
    return new Promise((resolve) => {
        const url = URL.createObjectURL(new Blob([bytes], { type: contentType }));
        const video = document.createElement("video");

        const finish = (measured) => {
            URL.revokeObjectURL(url);
            video.removeAttribute("src");
            resolve(measured);
        };

        video.preload = "metadata";
        video.onloadedmetadata = () => {
            finish({
                kind: "video",
                width: video.videoWidth,
                height: video.videoHeight,
                // Live streams report Infinity, and a container that doesn't say gives NaN.
                durationMs: Number.isFinite(video.duration) ? video.duration * 1000 : null
            });
        };
        video.onerror = () => finish(null);
        video.src = url;
    });
}

function e2eeMessageDecryptFailedMessage(requestId) {
    const out = new DataView(new ArrayBuffer(11));
    out.setUint8(0, e2eeSerializeVersion);
    out.setUint16(1, e2eeFromJsMessageDecryptFailed, false);
    out.setFloat64(3, requestId, false);
    return out;
}

// The ids of every conversation this browser holds a key for. Sent along with the rest of
// the startup data so that Elm knows from the first render which conversations still need
// a private key typed in, without having to ask and wait.
async function e2eeStoredKeyIds() {
    try {
        return await e2eeWithStore("readonly", store => store.getAllKeys());
    } catch (e) {
        return [];
    }
}


async function requestNotificationPermission(app) {
    if (!("Notification" in window)) {
        app.ports.check_notification_permission_from_js.send("unsupported");
        return "unsupported";
    }

    const permission = await Notification.requestPermission();
    app.ports.check_notification_permission_from_js.send(permission);

    return permission;
}

async function loadAudio(url, context, sounds) {
    try {
        const response = await fetch("/" + url + ".mp3");
        const responseBuffer = await response.arrayBuffer();
        sounds[url] = await context.decodeAudioData(responseBuffer);
    } catch (error) {
        console.log(error);
        sounds[url] = null;
    }
}


exports.init = async function init(app)
{
    // Register a Service Worker.
    let activeNotifications = [];

    const serviceWorkerJs = '/service-worker.js';

    app.ports.register_service_worker_to_js.subscribe(() => {
        if (navigator.serviceWorker) {
            navigator.serviceWorker.register(serviceWorkerJs);
            navigator.serviceWorker.addEventListener("message", (event) => {
                console.log(event);
                app.ports.service_worker_message_from_js.send(event.data);
            });
        }
    });

    app.ports.unregister_service_worker_to_js.subscribe(() => {
        if (navigator.serviceWorker) {
            navigator.serviceWorker.getRegistrations().then(function (registrations) {
              for (let registration of registrations) {
                registration.unregister().then(function () {
                  console.log("Service Worker Unregistered:", registration.scope)
                })
              }
            });
            location.reload();
        }
    });

    app.ports.load_service_worker_data_to_js.subscribe(async () => {
        try {
            if (!navigator.serviceWorker) {
                app.ports.load_service_worker_data_from_js.send("navigator.serviceWorker is not supported in this browser");
                return;
            }

            const describeWorker = (worker) => {
                if (!worker) { return null; }
                return { scriptURL: worker.scriptURL, state: worker.state };
            };

            const describeRegistration = (registration) => {
                if (!registration) { return null; }
                return {
                    scope: registration.scope,
                    updateViaCache: registration.updateViaCache,
                    active: describeWorker(registration.active),
                    installing: describeWorker(registration.installing),
                    waiting: describeWorker(registration.waiting),
                };
            };

            const result = {};

            result.controller = describeWorker(navigator.serviceWorker.controller);

            // The service worker records its install time in Cache Storage on
            // the 'install' event (see public/service-worker.js). Read it back
            // here so we can show when the worker was last installed/updated on
            // this device.
            try {
                const cache = await caches.open('service_worker_installed_at');
                const installedAtResponse = await cache.matchAll();
                if (installedAtResponse[0]) {
                    result.installedAt = await installedAtResponse[0].text();
                } else {
                    result.installedAt = "Unknown (install time not recorded yet)";
                }
            } catch (e) {
                result.installedAt = "Error: " + e.toString();
            }

            // The service worker writes its log entries to IndexedDB (see
            // log() in public/service-worker.js) because that's the only
            // persistent storage both the worker and the page can read.
            try {
                result.serviceWorkerLogs = await new Promise((resolve, reject) => {
                    const openRequest = indexedDB.open("at-chat-db", 1);
                    openRequest.onerror = () => reject(openRequest.error);
                    openRequest.onupgradeneeded = (event) => {
                        // Same schema as the service worker's log() creates, in
                        // case the page opens the database before the worker has
                        // logged anything.
                        event.target.result.createObjectStore("at-chat-object-store", { keyPath: "id" });
                    };
                    openRequest.onsuccess = (event) => {
                        const db = event.target.result;
                        let getAllRequest;
                        try {
                            getAllRequest = db
                                .transaction("at-chat-object-store", "readonly")
                                .objectStore("at-chat-object-store")
                                .getAll();
                        } catch (e) {
                            db.close();
                            reject(e);
                            return;
                        }
                        getAllRequest.onerror = () => { db.close(); reject(getAllRequest.error); };
                        getAllRequest.onsuccess = () => {
                            db.close();
                            // Ids are "<Date.now()>_<random>" (older entries are
                            // just "<Date.now()>").
                            const entries = getAllRequest.result.map((entry) => {
                                const time = Number(String(entry.id).split("_")[0]);
                                return {
                                    time: time,
                                    text: (isNaN(time) ? String(entry.id) : new Date(time).toISOString()) + " " + entry.name
                                };
                            });
                            entries.sort((a, b) => a.time - b.time);
                            resolve(entries.map((entry) => entry.text));
                        };
                    };
                });
            } catch (e) {
                result.serviceWorkerLogs = "Error: " + e.toString();
            }

            const registration = await navigator.serviceWorker.getRegistration(serviceWorkerJs);
            result.registration = describeRegistration(registration);

            const registrations = await navigator.serviceWorker.getRegistrations();
            result.registrations = registrations.map(describeRegistration);

            if (registration) {
                try {
                    const notifications = await registration.getNotifications();
                    result.notifications = notifications.map((n) => ({ title: n.title, body: n.body, tag: n.tag }));
                } catch (e) {
                    result.notifications = "Error: " + e.toString();
                }

                if (registration.pushManager) {
                    try {
                        const subscription = await registration.pushManager.getSubscription();
                        result.pushSubscription = subscription ? subscription.toJSON() : null;
                    } catch (e) {
                        result.pushSubscription = "Error: " + e.toString();
                    }

                    try {
                        result.pushPermissionState = await registration.pushManager.permissionState({ userVisibleOnly: true });
                    } catch (e) {
                        result.pushPermissionState = "Error: " + e.toString();
                    }
                }
            }

            // The count the service worker shows on the app icon, also kept in
            // Cache Storage (see incrementAppBadge in public/service-worker.js).
            try {
                const badgeCache = await caches.open('app_badge_count');
                const badgeCount = await badgeCache.matchAll();
                result.appBadgeCount = badgeCount[0] ? await badgeCount[0].text() : "0";
            } catch (e) {
                result.appBadgeCount = "Error: " + e.toString();
            }

            if ("Notification" in window) {
                result.notificationPermission = Notification.permission;
            }

            if (window.pushManager) {
                const windowPushManager = await window.pushManager.getSubscription();
                result.windowPushManager = windowPushManager.toJSON();
            }
            else {
                result.windowPushManager = null;
            }

            app.ports.load_service_worker_data_from_js.send(JSON.stringify(result, null, 2));
        } catch (e) {
            app.ports.load_service_worker_data_from_js.send("Error loading service worker data: " + e.toString());
        }
    });

    class LottiePlayer extends HTMLElement {
      static get observedAttributes() { return ['src', 'start-playing']; }
      constructor() { super(); this._animation = null; this._playIndex = 0; }
      connectedCallback() { this._loadAnimation(); }
      disconnectedCallback() { this._destroyAnimation(); }
      attributeChangedCallback(name, oldValue, newValue) {
        if (name === 'src' && oldValue !== newValue && this.isConnected) {
          this._loadAnimation();
        }
        if (name === 'start-playing' && this._animation) {
            switch(newValue) {
                case '0': break;
                case '1': {
                    this._animation.play();
                    this._animation.setLoop(true);
                    this._playIndex += 1;
                    const currentPlayIndex = this._playIndex;
                    setTimeout(() => { if (currentPlayIndex == this._playIndex) { this._animation.setLoop(false); } }, 4000);
                    break;
                }
                case '2': {
                    this._animation.play();
                    this._animation.setLoop(true);
                    this._playIndex += 1;
                    break;
                }
            }
        }
      }
      _destroyAnimation() {
        if (this._animation) {
          this._animation.destroy();
          this._animation = null;
        }
      }
      _loadAnimation() {
        this._destroyAnimation();
        let src = this.getAttribute('src');
        if (!src) return;
        if (typeof bodymovin !== 'undefined') {
            this._animation = bodymovin.loadAnimation({
              container: this,
              renderer: 'canvas',
              loop: true,
              autoplay: true,
              path: src,
              rendererSettings: { runExpressions: false }
            });

            this._playIndex += 1;
            const currentPlayIndex = this._playIndex;
            switch(this.getAttribute('start-playing')) {
                case '0': {
                    setTimeout(() => { if (currentPlayIndex == this._playIndex) { this._animation.setLoop(false); } }, 4000);
                    break;
                }
                case '1': {
                    setTimeout(() => { if (currentPlayIndex == this._playIndex) { this._animation.setLoop(false); } }, 4000);
                    break;
                }
                case '2': {
                    break;
                }
            }
        }
        else {
            setTimeout(() => { this._loadAnimation(this); }, 1000);
        }
      }
    }

    if (!customElements.get('lottie-player')) {
        customElements.define('lottie-player', LottiePlayer);
    }

    class AnimatedImagePlayer extends HTMLElement {
      static get observedAttributes() { return ['src', 'start-playing']; }
      constructor() {
        super();
        this._canvas = document.createElement('canvas');
        this._img = document.createElement('img');
        this._playIndex = 0;
        this._loaded = false;
      }
      connectedCallback() { this._loadGif(); }
      disconnectedCallback() {
        this._canvas.remove();
        this._img.remove();
        this._loaded = false;
      }
      attributeChangedCallback(name, oldValue, newValue) {
        if (name === 'src' && oldValue !== newValue && this.isConnected) {
          this._loadGif();
        }
        if (name === 'start-playing' && this._loaded) {
            switch(newValue) {
                case '0': break;
                case '1': { this._play(false); break; }
                case '2': { this._play(true); break; }
            }

        }
      }
      _play(loopForever) {
        // Show the animated img, hide the canvas
        this._canvas.style.display = 'none';
        this._img.src = this.getAttribute('src');
        this._img.style.display = 'block';
        this._playIndex += 1;
        if (!loopForever) {
            const currentPlayIndex = this._playIndex;
            setTimeout(() => {
              if (currentPlayIndex === this._playIndex) {
                this._img.style.display = 'none';
                this._canvas.style.display = 'block';
              }
            }, 5000);
        }
      }
      _loadGif() {
        this._loaded = false;
        this.innerHTML = '';
        const src = this.getAttribute('src');
        if (!src) return;

        this._canvas.style.display = 'block';
        // A canvas defaults to 300x150, so it has to be sized before it goes into the
        // document. Waiting until the image loads leaves a canvas far wider than the
        // emoji it stands in for, which shows up as horizontal scroll until then.
        this._canvas.style.width = '100%';
        this._canvas.style.height = '100%';
        this._img.style.display = 'none';
        this._img.style.width = '100%';
        this._img.style.height = '100%';
        this.appendChild(this._canvas);
        this.appendChild(this._img);

        // Load the image to capture the first frame onto the canvas
        const tempImg = new Image();
        tempImg.crossOrigin = 'anonymous';
        tempImg.onload = () => {
          this._canvas.width = tempImg.naturalWidth;
          this._canvas.height = tempImg.naturalHeight;
          const ctx = this._canvas.getContext('2d');
          ctx.drawImage(tempImg, 0, 0);
          this._loaded = true;

          this._play(this.getAttribute('start-playing') === '2');
        };
        tempImg.src = src;
      }
    }

    if (!customElements.get('animated-image-player')) {
        customElements.define('animated-image-player', AnimatedImagePlayer);
    }

    document.addEventListener('focusout', (event) => {
        app.ports.focus_changed_from_js.send({ id : null });
    });

    document.addEventListener('focusin', (event) => {
        app.ports.focus_changed_from_js.send(event.target);
    });

    document.addEventListener('selectionchange', (event) => {
        const node = document.activeElement;
        if (node) {
            app.ports.selection_changed_from_js.send(node);
        }
    });

    app.ports.exec_command_to_js.subscribe((data) => {
        var textarea = document.getElementById(data.htmlId);
        textarea.focus();
        data.commands.forEach((item) => {
            console.log(item.args[0]);
            switch (item.tag) {
                case 'undo': {
                    document.execCommand(item.tag, false, null);
                    break;
                }
                case 'insertText': {
                    textarea.setSelectionRange(item.args[1].start, item.args[1].end);
                    document.execCommand(item.tag, false, item.args[0]);
                    break;
                }
                case 'selectRange': {
                    textarea.setSelectionRange(item.args[0].start, item.args[0].end, item.args[1]);
                    break;
                }
            }

        });
    });

    app.ports.fix_cursor_position_to_js.subscribe((htmlId) => {
        var a = document.getElementById(htmlId);

        requestAnimationFrame(() =>
        {
            if (a) {
                a.value = a.value + " ";
            }
        });

    });

    app.ports.close_notifications_to_js.subscribe(() => {
        if (navigator.serviceWorker) {
            // Original code found here https://stackoverflow.com/a/64686549
            navigator.serviceWorker.ready.then(reg => {
              reg.getNotifications().then(notifications => {
                for (let i = 0; i < notifications.length; i += 1) {
                  notifications[i].close();
                }
              });
            });

            activeNotifications.forEach((notification) => { try { notification.close(); } catch(error) {} });
            activeNotifications = [];
        }
    });

    app.ports.set_app_badge_to_js.subscribe(async (count) => {
        if (!("setAppBadge" in navigator)) {
            return;
        }

        try {
            if (count > 0) {
                // The service worker counts up from this value when push
                // notifications arrive while the app is closed, so it's stored in
                // the same Cache Storage entry the worker reads (see
                // public/service-worker.js).
                const cache = await caches.open('app_badge_count');
                await cache.put(
                    'count',
                    new Response(String(count), {
                        status: 200,
                        statusText: 'OK',
                        headers: { 'Content-Type': 'text/plain' }
                    })
                );
                await navigator.setAppBadge(count);
            } else {
                await caches.delete('app_badge_count');
                await navigator.clearAppBadge();
            }
        } catch (error) {
            // Browsers that only badge installed apps reject this when the site is
            // running in a normal tab, which is nothing to worry about.
            console.log(error);
        }
    });

    app.ports.register_push_subscription_to_js.subscribe(async (publicKey) => {
        if (navigator.serviceWorker) {
            try {
                const permission = await requestNotificationPermission(app);

                if (permission !== "granted") {
                    app.ports.register_push_subscription_from_js.send({ tag: "SubscribeJsException", args: [ "Notification permission is " + permission ]});
                    return;
                }

                navigator.serviceWorker.ready
                .then(function(registration) {

                    // Use the PushManager to get the user's subscription to the push service.
                    return registration.pushManager.getSubscription()
                    .then(async function(subscription)
                    {
                        // If a subscription was found, reuse it only when it was created with the
                        // same VAPID public key the server is currently signing with. If the keys
                        // were rotated or regenerated, the stale subscription's applicationServerKey
                        // no longer matches the private key used to sign, so the push service rejects
                        // it with "VAPID public key mismatch". In that case drop it and resubscribe.
                        if (subscription) {
                            const existingKey = arrayBufferToBase64Url(subscription.options.applicationServerKey);
                            if (existingKey === publicKey) {
                                return subscription;
                            }
                            await subscription.unsubscribe();
                        }


                        // Otherwise, subscribe the user (userVisibleOnly allows to specify that we don't plan to
                        // send notifications that don't have a visible effect for the user).
                        return registration.pushManager.subscribe({
                            userVisibleOnly: true,
                            applicationServerKey: publicKey
                        });
                    });
                }).then(function(subscription) {
                  // Send the subscription details to the server using the Fetch API.
                  app.ports.register_push_subscription_from_js.send({ tag: "GotSubscribeData", args: [ subscription.toJSON() ]});
                }).catch((e) =>
                    app.ports.register_push_subscription_from_js.send({ tag: "SubscribeJsException", args: [ e.toString() ]})
                );
            }
            catch (e) {
                app.ports.register_push_subscription_from_js.send({ tag: "SubscribeJsException", args: [ e.toString() ]});
            }

        } else {
            app.ports.register_push_subscription_from_js.send({ tag: "SubscribeJsException", args: [ "navigator.serviceWorker is missing" ]});
        }
    });

    async function sendStartupData() {
        // original code found here https://stackoverflow.com/a/13382873
        // Creating invisible container
        const outer = document.createElement('div');
        outer.style.visibility = 'hidden';
        outer.style.overflow = 'scroll'; // forcing scrollbar to appear
        outer.style.msOverflowStyle = 'scrollbar'; // needed for WinJS apps
        document.body.appendChild(outer);

        // Creating inner element and placing it in the container
        const inner = document.createElement('div');
        outer.appendChild(inner);

        // Calculating difference between container's full width and the child width
        const scrollbarWidth = (outer.offsetWidth - inner.offsetWidth);

        // Removing temporary elements from the DOM
        outer.parentNode.removeChild(outer);

        // Check if the app is running as an installed PWA
        const isPwa = window.matchMedia('(display-mode: standalone)').matches ||
            window.navigator.standalone === true ||
            document.referrer.includes('android-app://');

        // The safe-area inset at the top of the screen (e.g. the notch on a phone), in pixels.
        // Touch events report positions relative to the viewport top (behind the inset), but the UI
        // is laid out below it, so the game board needs this to line drops up with the finger.
        const insetProbe = document.createElement('div');
        insetProbe.style.position = 'fixed';
        insetProbe.style.top = '0';
        insetProbe.style.left = '0';
        insetProbe.style.width = '0';
        insetProbe.style.height = 'env(safe-area-inset-top)';
        insetProbe.style.visibility = 'hidden';
        insetProbe.style.pointerEvents = 'none';
        document.body.appendChild(insetProbe);
        const safeAreaInsetTop = insetProbe.getBoundingClientRect().height;
        insetProbe.parentNode.removeChild(insetProbe);

        let zone;
        try {
            const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
            const now = Date.now();
            const year = 365.2425 * 24 * 60 * 60 * 1000;
            zone = zoneEras(
                timeZone,
                now - timezoneYearsEitherSide * year,
                now + timezoneYearsEitherSide * year
            );
        } catch (e) {
            zone = { defaultOffset: -new Date().getTimezoneOffset(), eras: [] };
        }

        app.ports.load_startup_data_from_js.send({
            // Event timeStamps are milliseconds since timeOrigin (the monotonic performance clock),
            // not since the unix epoch. We convert them to a wall-clock Time.Posix by adding
            // timeOrigin. `performance.timeOrigin` is fixed at page load, but the monotonic clock
            // that event timeStamps use pauses/diverges from wall time while the tab is backgrounded
            // or the machine sleeps, so a fixed origin makes touch times drift (off by a second, then
            // by far more after a long sleep). Instead we compute the origin as
            // `Date.now() - performance.now()`, and re-send it whenever the page becomes visible/
            // focused again (see the listeners below) so it re-anchors to the current wall clock.
            timeOrigin: Date.now() - performance.now(),
            loadStartupDataTime: Date.now(),
            userAgent: window.navigator.userAgent,
            scrollbarWidth: scrollbarWidth,
            isPwa: isPwa,
            notificationPermission: ("Notification" in window) ? Notification.permission : "unsupported",
            safeAreaInsetTop: safeAreaInsetTop,
            devicePixelRatio: window.devicePixelRatio || 1,
            timezone: zone,
            randomSeed: Array.from(crypto.getRandomValues(new Uint32Array(32))),
            e2eeKeys: await e2eeStoredKeyIds()
        });
    }

    // How many minutes ahead of UTC `timeZone` is at the instant `ms`. Intl will format a
    // moment into a named zone but won't say what the offset was, so the formatted parts are
    // read back as if they were UTC and the difference is the offset.
    function offsetMinutesAt(timeZone, ms) {
        const dtf = new Intl.DateTimeFormat('en-US', {
            timeZone, hourCycle: 'h23',
            year: 'numeric', month: '2-digit', day: '2-digit',
            hour: '2-digit', minute: '2-digit',
        });
        const p = {};
        for (const { type, value } of dtf.formatToParts(ms)) p[type] = value;
        const local = Date.UTC(+p.year, +p.month - 1, +p.day, +p.hour, +p.minute);
        return Math.round((local - Math.floor(ms / 60000) * 60000) / 60000);
    }

    // Every offset change `timeZone` makes between `fromMs` and `toMs`, in the shape
    // Time.customZone wants: `start` in whole minutes since the epoch, newest era first, and
    // each `start` naming the last minute of the offset before it (the lookup takes an era
    // when its start is strictly less than the minute being asked about).
    //
    // There's no api that lists the transitions, so this samples across the range and bisects
    // wherever two samples disagree. A fortnight between samples is short enough that no zone
    // changes twice within one.
    function zoneEras(timeZone, fromMs, toMs) {
        const step = 14 * 24 * 60 * 60 * 1000;
        const defaultOffset = offsetMinutesAt(timeZone, fromMs);
        let previous = defaultOffset;
        const eras = [];

        for (let sample = fromMs + step; sample < toMs + step; sample += step) {
            const end = Math.min(sample, toMs);
            const offset = offsetMinutesAt(timeZone, end);
            if (offset !== previous) {
                let lastOld = end - step;
                let firstNew = end;
                while (firstNew - lastOld > 60000) {
                    const middle = lastOld + Math.floor((firstNew - lastOld) / 120000) * 60000;
                    if (middle === lastOld) break;
                    if (offsetMinutesAt(timeZone, middle) === previous) lastOld = middle;
                    else firstNew = middle;
                }
                eras.push({ start: Math.floor(lastOld / 60000), offset: offset });
                previous = offset;
            }
        }
        return { defaultOffset: defaultOffset, eras: eras.reverse() };
    }

    const timezoneYearsEitherSide = 10;

    app.ports.load_startup_data_to_js.subscribe((a) => {
        sendStartupData();
    });

    // Re-anchor timeOrigin after the tab was backgrounded or the machine slept, since the monotonic
    // clock behind event timeStamps drifts from wall time during those periods.
    document.addEventListener('visibilitychange', () => {
        if (document.visibilityState === 'visible') sendStartupData();
    });
    window.addEventListener('focus', sendStartupData);
    window.addEventListener('pageshow', sendStartupData);

    app.ports.shift_scroll_by_element_delta_to_js.subscribe((data) => {
        const element = document.getElementById(data.elementId);
        const container = document.getElementById(data.containerId);
        if (!element || !container) return;
        const oldY = element.getBoundingClientRect().top;
        requestAnimationFrame(() => {
            const newY = element.getBoundingClientRect().top;
            container.scrollTop += (newY - oldY);
        });
    });

    app.ports.smooth_scroll_by_to_js.subscribe((data) => {
        const container = document.getElementById(data.containerId);
        if (!container) return;
        const duration = 250;
        const startTime = performance.now();
        const total = data.scrollY;
        let traveled = 0;
        function easeInOutQuart(t) {
            return t < 0.5 ? 8 * t * t * t * t : 1 - Math.pow(-2 * t + 2, 4) / 2;
        }
        function step(now) {
            const t = Math.min((now - startTime) / duration, 1);
            const desired = total * easeInOutQuart(t);
            // Apply the delta on top of the current scrollTop so that any
            // shift caused by content being prepended above (e.g. older
            // messages loading in) is preserved instead of fighting the
            // animation.
            container.scrollTop += desired - traveled;
            traveled = desired;
            if (t < 1) requestAnimationFrame(step);
        }
        requestAnimationFrame(step);
    });

    app.ports.set_cursor_position_to_js.subscribe((data) => {
        requestAnimationFrame(() =>
            {
                const element = document.getElementById(data.htmlId);
                if (element.setSelectionRange) {
                    element.focus();
                    element.setSelectionRange(data.start, data.end);
                    //element.setSelectionRange(0, 5);
                }
            });
    });

    app.ports.encryption_to_js.subscribe(async (dataView) => {
        const message = e2eeReadToJs(dataView);

        if (message === null) {
            console.error("Couldn't read what Elm sent over the encryption port");
            return;
        }

        try {
            if (message.tag === "store-shared-secret") {
                // The raw X25519 output is not a key, it is a number both sides happen to
                // agree on, so it goes through HKDF before anything encrypts with it.
                const hkdfKey = await crypto.subtle.importKey(
                    "raw", message.sharedSecret, "HKDF", false, ["deriveKey"]);

                const aesKey = await crypto.subtle.deriveKey(
                    { name: "HKDF"
                    , hash: "SHA-256"
                    , salt: new Uint8Array(32)
                    , info: new TextEncoder().encode("at-chat dm e2ee v1")
                    },
                    hkdfKey,
                    { name: "AES-GCM", length: 256 },
                    false, // not exportable, which is why it is safe to keep around
                    ["encrypt", "decrypt"]);

                await e2eeWithStore("readwrite", store => store.put(aesKey, message.otherUserId));
                app.ports.encryption_from_js.send(
                    e2eeIdMessage(e2eeFromJsSharedSecretStored, message.otherUserId));

            } else if (message.tag === "encrypt-message") {
                const key = await e2eeWithStore(
                    "readonly", store => store.get(message.otherUserId));

                if (!key) {
                    app.ports.encryption_from_js.send(
                        e2eeIdAndTextMessage(
                            e2eeFromJsMessageEncryptFailed,
                            message.requestId,
                            "No encryption key is stored on this device for that conversation"));
                    return;
                }

                // A fresh IV every message, prepended to the ciphertext so that decrypting
                // only needs the one blob.
                const iv = crypto.getRandomValues(new Uint8Array(12));
                const cipherText = await crypto.subtle.encrypt(
                    { name: "AES-GCM", iv: iv }, key, message.data);

                const combined = new Uint8Array(iv.length + cipherText.byteLength);
                combined.set(iv, 0);
                combined.set(new Uint8Array(cipherText), iv.length);

                app.ports.encryption_from_js.send(
                    e2eeMessageEncryptedMessage(message.requestId, combined));

            } else if (message.tag === "decrypt-message") {
                const key = await e2eeWithStore(
                    "readonly", store => store.get(message.otherUserId));

                if (!key) {
                    app.ports.encryption_from_js.send(
                        e2eeMessageDecryptFailedMessage(message.requestId));
                    return;
                }

                const plainText = await crypto.subtle.decrypt(
                    { name: "AES-GCM", iv: message.data.slice(0, 12) },
                    key,
                    message.data.slice(12));

                app.ports.encryption_from_js.send(
                    e2eeMessageDecryptedMessage(message.requestId, new Uint8Array(plainText)));

            } else if (message.tag === "decrypt-many-messages") {
                const key = await e2eeWithStore(
                    "readonly", store => store.get(message.otherUserId));

                const results = await Promise.all(message.data.map(async (bytes) => {
                    if (!key) { return null; }

                    try {
                        const plainText = await crypto.subtle.decrypt(
                            { name: "AES-GCM", iv: bytes.slice(0, 12) }, key, bytes.slice(12));
                        return new Uint8Array(plainText);
                    } catch (e) {
                        return null;
                    }
                }));

                app.ports.encryption_from_js.send(
                    e2eeManyMessagesDecryptedMessage(message.requestId, results));

            } else if (message.tag === "encrypt-many-messages") {
                const key = await e2eeWithStore(
                    "readonly", store => store.get(message.otherUserId));

                if (!key) {
                    app.ports.encryption_from_js.send(
                        e2eeIdAndTextMessage(
                            e2eeFromJsManyMessagesEncryptFailed,
                            message.requestId,
                            "No encryption key is stored on this device for that conversation"));
                    return;
                }

                const results = await Promise.all(message.data.map(async (bytes) => {
                    const iv = crypto.getRandomValues(new Uint8Array(12));
                    const cipherText = await crypto.subtle.encrypt(
                        { name: "AES-GCM", iv: iv }, key, bytes);

                    const combined = new Uint8Array(iv.length + cipherText.byteLength);
                    combined.set(iv, 0);
                    combined.set(new Uint8Array(cipherText), iv.length);

                    return combined;
                }));

                app.ports.encryption_from_js.send(
                    e2eeManyMessagesEncryptedMessage(message.requestId, results));

            } else if (message.tag === "encrypt-file") {
                // A key of its own for each file. It is exportable because it has to travel
                // to the other person, which it does inside the encrypted message the file is
                // attached to rather than through IndexedDB.
                const fileKey = await crypto.subtle.generateKey(
                    { name: "AES-GCM", length: 256 }, true, ["encrypt", "decrypt"]);

                const iv = crypto.getRandomValues(new Uint8Array(12));
                const cipherText = await crypto.subtle.encrypt(
                    { name: "AES-GCM", iv: iv }, fileKey, message.data);

                const combined = new Uint8Array(iv.length + cipherText.byteLength);
                combined.set(iv, 0);
                combined.set(new Uint8Array(cipherText), iv.length);

                // Looked at before the upload, since the server only ever sees the
                // ciphertext and this is the only chance anything gets to read the file
                // itself. The size goes in the message alongside the key.
                const inspected = await e2eeInspectFile(message.data, message.contentType);

                // The thumbnail is encrypted with the file's own key so that nothing has to
                // carry a second one, under an iv of its own because reusing one with the
                // same key is what breaks aes-gcm.
                let thumbnail = null;

                if (inspected.thumbnail !== null) {
                    const thumbnailIv = crypto.getRandomValues(new Uint8Array(12));
                    const thumbnailCipherText = await crypto.subtle.encrypt(
                        { name: "AES-GCM", iv: thumbnailIv }, fileKey, inspected.thumbnail);

                    thumbnail = new Uint8Array(
                        thumbnailIv.length + thumbnailCipherText.byteLength);
                    thumbnail.set(thumbnailIv, 0);
                    thumbnail.set(new Uint8Array(thumbnailCipherText), thumbnailIv.length);
                }

                app.ports.encryption_from_js.send(
                    e2eeFileEncryptedMessage(
                        message.requestId,
                        new Uint8Array(await crypto.subtle.exportKey("raw", fileKey)),
                        combined,
                        thumbnail,
                        inspected.measured));

            } else if (message.tag === "store-file-keys") {
                for (const entry of message.keys) {
                    // Stored the same way the conversation keys are: as a CryptoKey the
                    // browser won't hand back out, so the raw bytes aren't left on disk for
                    // anything with access to the database to read.
                    const key = await crypto.subtle.importKey(
                        "raw", entry.key, "AES-GCM", false, ["decrypt"]);

                    await fileKeyWithStore(
                        "readwrite", store => store.put(key, entry.fileHash));
                }
            }
        } catch (e) {
            if (message.tag === "store-shared-secret") {
                app.ports.encryption_from_js.send(
                    e2eeIdAndTextMessage(
                        e2eeFromJsSharedSecretFailed, message.otherUserId, e.toString()));
            } else if (message.tag === "encrypt-message") {
                app.ports.encryption_from_js.send(
                    e2eeIdAndTextMessage(
                        e2eeFromJsMessageEncryptFailed, message.requestId, e.toString()));
            } else if (message.tag === "decrypt-message") {
                app.ports.encryption_from_js.send(
                    e2eeMessageDecryptFailedMessage(message.requestId));
            } else if (message.tag === "encrypt-many-messages") {
                app.ports.encryption_from_js.send(
                    e2eeIdAndTextMessage(
                        e2eeFromJsManyMessagesEncryptFailed, message.requestId, e.toString()));
            } else if (message.tag === "encrypt-file") {
                app.ports.encryption_from_js.send(
                    e2eeIdAndTextMessage(
                        e2eeFromJsFileEncryptFailed, message.requestId, e.toString()));
            } else {
                // store-file-keys has no request to answer. A file whose key didn't make it
                // this far shows up as one that can't be decrypted when it is fetched.
                console.error("Encryption port error: " + e.toString());
            }
        }
    });

    app.ports.haptic_feedback.subscribe((a) => {
        try {
            const label = document.createElement("label");
            label.ariaHidden = "true";
            label.style.display = "none";

            const input = document.createElement("input");
            input.type = "checkbox";
            input.setAttribute("switch", "");
            label.appendChild(input);

            document.head.appendChild(label);
            label.click();
            document.head.removeChild(label);
        } catch {
            // do nothing
        }

    });

    window.visualViewport.addEventListener(
        "resize",
        () => {
            app.ports.visual_viewport_resized_from_js.send(window.visualViewport.height);
        });

    app.ports.request_device_pixel_ratio_to_js.subscribe((a) => {
        app.ports.device_pixel_ratio_from_js.send(window.devicePixelRatio || 1);
    });

    app.ports.request_notification_permission.subscribe((a) => {
        const permission = requestNotificationPermission(app);
        if (permission === "granted") {
            // iOS only lets the service worker create notifications, so this throws there. It's
            // only a confirmation that permission went through, so carry on without it.
            try {
                new Notification("Notifications enabled");
            } catch (error) {
                console.log(error);
            }
        }
    })

    app.ports.show_notification.subscribe((a) => {
        if ("Notification" in window) {
            const notification = new Notification(a.title, { body: a.body });
            activeNotifications.push(notification);
        }
    });

    app.ports.copy_to_clipboard_to_js.subscribe(text => copyTextToClipboard(text));

    app.ports.copy_image_to_clipboard_to_js.subscribe(imageUrl => copyImageToClipboard(imageUrl));

    app.ports.text_input_select_all_to_js.subscribe(htmlId => {
        var a = document.getElementById(htmlId);
        if (a) {
            a.select();
        }
    });

    app.ports.save_user_settings_to_js.subscribe(function (data) {
        window.localStorage.setItem("ai-chat-settings", data);
    });

    app.ports.load_user_settings_to_js.subscribe(function (data) {
        let localStorageValue = window.localStorage.getItem("ai-chat-settings");
        if (localStorageValue !== null) {
          app.ports.load_user_settings_from_js.send(localStorageValue);
        }
        else {
          app.ports.load_user_settings_from_js.send("");
        }
    });

    window.addEventListener('focus', () => { app.ports.window_has_focus_from_js.send(true); });
    window.addEventListener('blur', () => { app.ports.window_has_focus_from_js.send(false); });

    function copyImageToClipboard(imageUrl) {
        if (!navigator.clipboard || typeof ClipboardItem === "undefined") {
            // Fall back to copying the link when writing image data isn't supported.
            copyTextToClipboard(imageUrl);
            return;
        }
        fetch(imageUrl)
            .then(function (response) { return response.blob(); })
            .then(function (blob) {
                // The clipboard only accepts a handful of image types (png is the safest).
                // Re-encode anything else to png via a canvas before writing it.
                if (blob.type === "image/png") {
                    return navigator.clipboard.write([new ClipboardItem({ "image/png": blob })]);
                }
                return createImageBitmap(blob).then(function (bitmap) {
                    var canvas = document.createElement("canvas");
                    canvas.width = bitmap.width;
                    canvas.height = bitmap.height;
                    canvas.getContext("2d").drawImage(bitmap, 0, 0);
                    return new Promise(function (resolve) {
                        canvas.toBlob(function (pngBlob) {
                            resolve(navigator.clipboard.write([new ClipboardItem({ "image/png": pngBlob })]));
                        }, "image/png");
                    });
                });
            })
            .catch(function (err) {
                console.error('Error: Could not copy image: ', err);
                copyTextToClipboard(imageUrl);
            });
    }

    function copyTextToClipboard(text) {
        if (!navigator.clipboard) {
            fallbackCopyTextToClipboard(text);
            return;
        }
        navigator.clipboard.writeText(text).then(function () {
        }, function (err) {
            console.error('Error: Could not copy text: ', err);
        });
    }

    function fallbackCopyTextToClipboard(text) {
        var textArea = document.createElement("textarea");
        textArea.value = text;

        // Avoid scrolling to bottom
        textArea.style.top = "0";
        textArea.style.left = "0";
        textArea.style.position = "fixed";

        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();

        try {
            var successful = document.execCommand('copy');
            if (successful !== true) {
                console.log('Error: Copying text command was unsuccessful');
            }
        } catch (err) {
            console.error('Error: Oops, unable to copy', err);
        }

        document.body.removeChild(textArea);
    }
}