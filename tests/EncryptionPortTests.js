// Checks the parts of elm-pkg-js/stuff.js that can be run without a browser: the bytes it
// writes and reads by hand for the encryption port, and the storage it throws away when the
// account is logged out of.
//
// For the port,
// Elm's codec is what defines that format, and nothing type checks the handwritten JS
// against it, so the same byte sequences are pinned on both sides: the ones here, and the
// matching ones in portWireFormatTests in tests/CodecRoundTripTests.elm. Changing the
// format on one side alone fails on the other.
//
// Run with: node tests/EncryptionPortTests.js

const fs = require("fs");
const path = require("path");

// Everything above exports.init is constants and function declarations, so it can be
// evaluated on its own without the browser the rest of the file needs.
function loadPortHelpers() {
    const source = fs.readFileSync(
        path.join(__dirname, "..", "elm-pkg-js", "stuff.js"), "utf8");

    return new Function(
        source.slice(0, source.indexOf("exports.init"))
            + "\n; return { e2eeReadToJs: e2eeReadToJs"
            + ", e2eeFileEncryptedMessage: e2eeFileEncryptedMessage"
            + ", clearBrowserStorage: clearBrowserStorage };")();
}

function toDataView(bytes) {
    return new DataView(new Uint8Array(bytes).buffer);
}

function toArray(dataView) {
    return Array.from(new Uint8Array(dataView.buffer, dataView.byteOffset, dataView.byteLength));
}

// Request id 7, a one byte key of 170 and one byte of ciphertext of 187.
const requestId = 7;

const key = new Uint8Array([170]);

const cipherText = new Uint8Array([187]);

const fileEncryptedBytes = {
    nothingMeasured:
        [1, 0, 9, 64, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 170, 0, 0, 0, 1, 187, 0, 0, 0, 0],
    image:
        [1, 0, 9, 64, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 170, 0, 0, 0, 1, 187, 0, 0, 0, 1,
         0, 0, 0, 0, 64, 132, 0, 0, 0, 0, 0, 0, 0, 0, 64, 126, 0, 0, 0, 0, 0, 0],
    imageWithThumbnail:
        [1, 0, 9, 64, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 170, 0, 0, 0, 1, 187, 0, 1, 0, 0,
         0, 3, 1, 2, 3, 0, 1, 0, 0, 0, 0, 64, 132, 0, 0, 0, 0, 0, 0, 0, 0, 64, 126, 0, 0,
         0, 0, 0, 0],
    videoWithNoDuration:
        [1, 0, 9, 64, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 170, 0, 0, 0, 1, 187, 0, 0, 0, 1,
         0, 1, 0, 0, 64, 158, 0, 0, 0, 0, 0, 0, 0, 0, 64, 144, 224, 0, 0, 0, 0, 0, 0, 0],
    video:
        [1, 0, 9, 64, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 170, 0, 0, 0, 1, 187, 0, 0, 0, 1,
         0, 1, 0, 0, 64, 158, 0, 0, 0, 0, 0, 0, 0, 0, 64, 144, 224, 0, 0, 0, 0, 0, 0, 1,
         64, 163, 136, 0, 0, 0, 0, 0]
};

// Request id 7, content type "image/png", three bytes of file.
const encryptFileRequestBytes =
    [1, 0, 5, 64, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 105, 109, 97, 103, 101, 47, 112, 110,
     103, 0, 0, 0, 3, 1, 2, 3];

// Two keys: "abc" with bytes 7 and 8, then "de" with byte 9.
const storeFileKeysRequestBytes =
    [1, 0, 6, 0, 0, 0, 2, 0, 0, 0, 3, 97, 98, 99, 0, 0, 0, 2, 7, 8, 0, 0, 0, 2, 100, 101,
     0, 0, 0, 1, 9];

async function run() {
    const js = loadPortHelpers();
    const failures = [];

    async function check(name, body) {
        try {
            await body();
            console.log("  passed: " + name);
        } catch (error) {
            failures.push(name);
            console.log("  FAILED: " + name + ": " + error.message);
        }
    }

    function expectEqual(actual, expected, what) {
        const actualText = JSON.stringify(actual);
        const expectedText = JSON.stringify(expected);

        if (actualText !== expectedText) {
            throw new Error(what + " was " + actualText + " rather than " + expectedText);
        }
    }

    await check("A file nothing could be measured about", () => {
        expectEqual(
            toArray(js.e2eeFileEncryptedMessage(requestId, key, cipherText, null, null)),
            fileEncryptedBytes.nothingMeasured,
            "the message");
    });

    await check("An image too small to have wanted a thumbnail", () => {
        expectEqual(
            toArray(js.e2eeFileEncryptedMessage(
                requestId, key, cipherText, null, { kind: "image", width: 640, height: 480 })),
            fileEncryptedBytes.image,
            "the message");
    });

    await check("An image the browser made a thumbnail of", () => {
        expectEqual(
            toArray(js.e2eeFileEncryptedMessage(
                requestId,
                key,
                cipherText,
                new Uint8Array([1, 2, 3]),
                { kind: "image", width: 640, height: 480 })),
            fileEncryptedBytes.imageWithThumbnail,
            "the message");
    });

    await check("A video whose length the container didn't say", () => {
        expectEqual(
            toArray(js.e2eeFileEncryptedMessage(
                requestId,
                key,
                cipherText,
                null,
                { kind: "video", width: 1920, height: 1080, durationMs: null })),
            fileEncryptedBytes.videoWithNoDuration,
            "the message");
    });

    await check("A video that was measured", () => {
        expectEqual(
            toArray(js.e2eeFileEncryptedMessage(
                requestId,
                key,
                cipherText,
                null,
                { kind: "video", width: 1920, height: 1080, durationMs: 2500 })),
            fileEncryptedBytes.video,
            "the message");
    });

    await check("A file handed over to be encrypted", () => {
        const parsed = js.e2eeReadToJs(toDataView(encryptFileRequestBytes));

        expectEqual(parsed.tag, "encrypt-file", "the request");
        expectEqual(parsed.requestId, requestId, "the request id");
        expectEqual(parsed.contentType, "image/png", "the content type");
        expectEqual(Array.from(parsed.data), [1, 2, 3], "the file");
    });

    await check("File keys handed over to be stored", () => {
        const parsed = js.e2eeReadToJs(toDataView(storeFileKeysRequestBytes));

        expectEqual(parsed.tag, "store-file-keys", "the request");
        expectEqual(
            parsed.keys.map((entry) => ({ fileHash: entry.fileHash, key: Array.from(entry.key) })),
            [{ fileHash: "abc", key: [7, 8] }, { fileHash: "de", key: [9] }],
            "the keys");
    });

    // What was deleted, and a database whose delete another tab is holding open so the
    // logout isn't left waiting on it.
    function fakeIndexedDb(deleted, listed, blocked) {
        return {
            databases: listed === null ? undefined : () => Promise.resolve(listed),
            deleteDatabase: (name) => {
                deleted.push(name);

                const request = {};

                setTimeout(
                    () => (name === blocked ? request.onblocked() : request.onsuccess()),
                    0);

                return request;
            }
        };
    }

    function fakeCaches(deleted, listed) {
        return {
            keys: () => Promise.resolve(listed),
            delete: (name) => {
                deleted.push(name);
                return Promise.resolve(true);
            }
        };
    }

    await check("Logging out throws away every database and cache", async () => {
        const databases = [];
        const cacheNames = [];

        await js.clearBrowserStorage(
            fakeIndexedDb(databases, [{ name: "at-chat-e2ee" }, { name: "something-else" }], null),
            fakeCaches(cacheNames, ["resource_cache_v1", "frontend_cache_v1"]));

        expectEqual(
            databases.sort(),
            ["at-chat-db", "at-chat-e2ee", "at-chat-file-keys", "something-else"],
            "the databases that were deleted");
        expectEqual(
            cacheNames.sort(),
            ["frontend_cache_v1", "resource_cache_v1"],
            "the caches that were deleted");
    });

    // Not every browser will list its databases, and the keys have to go either way.
    await check("A browser that won't list its databases still loses the keys", async () => {
        const databases = [];

        await js.clearBrowserStorage(
            fakeIndexedDb(databases, null, null), fakeCaches([], []));

        expectEqual(
            databases.sort(),
            ["at-chat-db", "at-chat-e2ee", "at-chat-file-keys"],
            "the databases that were deleted");
    });

    await check("A database another tab is holding open doesn't stall the rest", async () => {
        const cacheNames = [];

        await js.clearBrowserStorage(
            fakeIndexedDb([], [], "at-chat-e2ee"),
            fakeCaches(cacheNames, ["resource_cache_v1"]));

        expectEqual(cacheNames, ["resource_cache_v1"], "the caches that were deleted");
    });

    if (failures.length > 0) {
        console.log("\n" + failures.length + " encryption port test(s) failed");
        process.exit(1);
    }

    console.log("\nAll encryption port tests passed!");
}

run();
