// port voice_chat_to_js : Json.Encode.Value -> Cmd msg
// port voice_chat_from_js : (Json.Decode.Value -> msg) -> Sub msg
//
// Voice and video chat over the rust server's room WebSocket, in place of the
// WebRTC peer connections this used to open against Cloudflare Realtime. Media
// is encoded with WebCodecs, sent as binary messages, and relayed to everyone
// else in the room; there is no SFU, no signalling and no ICE.
//
// Frames come off the camera with requestVideoFrameCallback and off the mic
// with an AudioWorklet, rather than with MediaStreamTrackProcessor, which reads
// better but Firefox has never implemented. Everything used works in Chrome 94+,
// Firefox 132+ and Safari 26+.
//
// The room only relays bytes, so the sender's name travels inside each message
// and is not checked by anyone. A DM room holds one other person, who the
// backend already vouched for when it let them in, so the worst this allows is
// somebody labelling their own media as their own other tab. If rooms ever hold
// more than two people, the server should tag messages with the sender it
// authenticated instead of trusting this field.

const AUDIO_SAMPLE_RATE = 48000;
const AUDIO_BLOCK_FRAMES = 960; // 20ms, which is the frame size opus wants.

// Loud enough to count as speaking, as a mean sample amplitude between 0 and 1.
// One number for our own mic and for everyone else, which is only possible
// because both are measured the same way; see "who is speaking" below.
const SPEAKING_THRESHOLD = 0.02;

// A shared screen is mostly text, which needs more pixels than a face does and
// rarely moves, so it trades frame rate for resolution.
const SCREEN_MAX_WIDTH = 1920;
const SCREEN_MAX_HEIGHT = 1080;
const SCREEN_FRAME_RATE = 15;
const SCREEN_BITRATE = 2_500_000;

// A screen that isn't changing produces few or no frames, so its key frames go
// by the clock instead of by counting frames the way the camera's do, and a
// frame is taken off the screen by hand whenever it has gone quiet this long.
const SCREEN_KEY_FRAME_INTERVAL_MS = 2000;
const SCREEN_IDLE_FRAME_MS = 1000;

// Firefox never ends the track when the window being shared is closed: it stays
// live and just stops producing frames. An open window keeps producing them in
// Firefox even when nothing in it changes, so going quiet this long means it's
// gone. Chrome does end the track, and sends nothing for a still screen, so the
// same rule would end its shares for no reason.
const SCREEN_GONE_MS = 5000;

// Must match Call.localScreenShareNodeId.
const LOCAL_SCREEN_NODE_ID = "local-screen-share";

// A peer that has sent nothing for this long is treated as silent. Without it a
// peer that stops sending mid-word stays outlined as speaking forever.
const SPEAKING_TIMEOUT_MS = 400;

// Batches the mic into 20ms blocks on the audio thread. Doing it here rather
// than on the main thread keeps this to one message per block instead of one
// per 128 samples.
const captureWorklet = `
class CaptureProcessor extends AudioWorkletProcessor {
    constructor() {
        super();
        this.block = new Float32Array(${AUDIO_BLOCK_FRAMES});
        this.filled = 0;
    }

    process(inputs) {
        const channel = inputs[0] && inputs[0][0];
        if (!channel) return true;

        let offset = 0;
        while (offset < channel.length) {
            const take = Math.min(channel.length - offset, this.block.length - this.filled);
            this.block.set(channel.subarray(offset, offset + take), this.filled);
            this.filled += take;
            offset += take;
            if (this.filled === this.block.length) {
                this.port.postMessage(this.block.slice());
                this.filled = 0;
            }
        }
        return true;
    }
}
registerProcessor("capture-processor", CaptureProcessor);
`;

// --- recording file formats ---
//
// A recording is kept as plain files that video editors open directly: H.264 in
// fragmented MP4 for the camera and a shared screen, and 16 bit PCM WAV for the
// mic. Fragmented MP4 is the one MP4 layout that can be written front to back
// without going back to fix up an index, so a tab that closes mid-recording
// leaves a file that plays up to its last fragment.

const RECORDING_TIMESCALE = 90000;
const RECORDING_KEY_FRAME_INTERVAL_MS = 2000;

function concatBytes(parts) {
    let length = 0;
    parts.forEach(function (part) { length += part.byteLength; });
    const out = new Uint8Array(length);
    let offset = 0;
    parts.forEach(function (part) {
        out.set(part, offset);
        offset += part.byteLength;
    });
    return out;
}

function uint(byteCount, value) {
    const out = new Uint8Array(byteCount);
    const view = new DataView(out.buffer);
    if (byteCount === 1) view.setUint8(0, value);
    else if (byteCount === 2) view.setUint16(0, value);
    else if (byteCount === 4) view.setUint32(0, value);
    else view.setBigUint64(0, BigInt(Math.round(value)));
    return out;
}

function ascii(text) {
    const out = new Uint8Array(text.length);
    for (let i = 0; i < text.length; i++) out[i] = text.charCodeAt(i);
    return out;
}

function mp4Box(type, parts) {
    const payload = concatBytes(parts);
    return concatBytes([uint(4, payload.byteLength + 8), ascii(type), payload]);
}

function mp4FullBox(type, version, flags, parts) {
    return mp4Box(type, [uint(1, version), uint(1, flags >> 16), uint(2, flags & 0xffff)].concat(parts));
}

const MP4_MATRIX = [0x00010000, 0, 0, 0, 0x00010000, 0, 0, 0, 0x40000000].map(function (n) { return uint(4, n); });

// What the encoder hands back as `description` is already the avcC box's body
// for H.264. VP9 has no description, so its vpcC is written out from the codec
// string the encoder was set up with: vp09.<profile>.<level>.<bitDepth>.
function mp4SampleEntry(codec, width, height, description) {
    const visual = [
        new Uint8Array(6),
        uint(2, 1),
        new Uint8Array(16),
        uint(2, width),
        uint(2, height),
        uint(4, 0x00480000),
        uint(4, 0x00480000),
        uint(4, 0),
        uint(2, 1),
        new Uint8Array(32),
        uint(2, 0x0018),
        uint(2, 0xffff),
    ];
    if (codec.startsWith("avc1")) {
        return mp4Box("avc1", visual.concat([mp4Box("avcC", [description])]));
    }
    const fields = codec.split(".");
    const bitDepth = parseInt(fields[3] || "8", 10);
    const vpcC = mp4FullBox("vpcC", 1, 0, [
        uint(1, parseInt(fields[1] || "0", 10)),
        uint(1, parseInt(fields[2] || "10", 10)),
        // bit depth, 4:2:0 chroma with colocated samples, limited range
        uint(1, (bitDepth << 4) | (1 << 1)),
        uint(1, 1),
        uint(1, 1),
        uint(1, 1),
        uint(2, 0),
    ]);
    return mp4Box("vp09", visual.concat([vpcC]));
}

function mp4InitSegment(codec, width, height, description) {
    const ftyp = mp4Box("ftyp", [ascii("isom"), uint(4, 0x200), ascii("isom"), ascii("iso6"), ascii("iso2"), ascii("mp41")]);
    const mvhd = mp4FullBox("mvhd", 0, 0, [
        uint(4, 0),
        uint(4, 0),
        uint(4, 1000),
        uint(4, 0),
        uint(4, 0x00010000),
        uint(2, 0x0100),
        new Uint8Array(10),
    ].concat(MP4_MATRIX, [new Uint8Array(24), uint(4, 2)]));
    const tkhd = mp4FullBox("tkhd", 0, 3, [
        uint(4, 0),
        uint(4, 0),
        uint(4, 1),
        uint(4, 0),
        uint(4, 0),
        new Uint8Array(8),
        uint(2, 0),
        uint(2, 0),
        uint(2, 0),
        uint(2, 0),
    ].concat(MP4_MATRIX, [uint(4, width * 0x10000), uint(4, height * 0x10000)]));
    const mdhd = mp4FullBox("mdhd", 0, 0, [
        uint(4, 0),
        uint(4, 0),
        uint(4, RECORDING_TIMESCALE),
        uint(4, 0),
        // "und"
        uint(2, 0x55c4),
        uint(2, 0),
    ]);
    const hdlr = mp4FullBox("hdlr", 0, 0, [uint(4, 0), ascii("vide"), new Uint8Array(12), ascii("VideoHandler\0")]);
    const stbl = mp4Box("stbl", [
        mp4FullBox("stsd", 0, 0, [uint(4, 1), mp4SampleEntry(codec, width, height, description)]),
        mp4FullBox("stts", 0, 0, [uint(4, 0)]),
        mp4FullBox("stsc", 0, 0, [uint(4, 0)]),
        mp4FullBox("stsz", 0, 0, [uint(4, 0), uint(4, 0)]),
        mp4FullBox("stco", 0, 0, [uint(4, 0)]),
    ]);
    const minf = mp4Box("minf", [
        mp4FullBox("vmhd", 0, 1, [new Uint8Array(8)]),
        mp4Box("dinf", [mp4FullBox("dref", 0, 0, [uint(4, 1), mp4FullBox("url ", 0, 1, [])])]),
        stbl,
    ]);
    const trak = mp4Box("trak", [tkhd, mp4Box("mdia", [mdhd, hdlr, minf])]);
    const mvex = mp4Box("mvex", [mp4FullBox("trex", 0, 0, [uint(4, 1), uint(4, 1), uint(4, 0), uint(4, 0), uint(4, 0)])]);
    return concatBytes([ftyp, mp4Box("moov", [mvhd, trak, mvex])]);
}

// One moof and mdat holding `samples`, each { data, time, duration, key } with
// times in RECORDING_TIMESCALE units from the start of the file.
function mp4Fragment(sequenceNumber, samples) {
    const trunEntries = [];
    samples.forEach(function (sample) {
        trunEntries.push(uint(4, sample.duration));
        trunEntries.push(uint(4, sample.data.byteLength));
        // A key frame depends on nothing; anything else depends on what came
        // before and can't be seeked to.
        trunEntries.push(uint(4, sample.key ? 0x02000000 : 0x01010000));
    });

    function build(dataOffset) {
        const trun = mp4FullBox("trun", 0, 0x000701, [uint(4, samples.length), uint(4, dataOffset)].concat(trunEntries));
        const traf = mp4Box("traf", [
            // default-base-is-moof, so data offsets count from the moof
            mp4FullBox("tfhd", 0, 0x020000, [uint(4, 1)]),
            mp4FullBox("tfdt", 1, 0, [uint(8, samples[0].time)]),
            trun,
        ]);
        return mp4Box("moof", [mp4FullBox("mfhd", 0, 0, [uint(4, sequenceNumber)]), traf]);
    }

    const moofSize = build(0).byteLength;
    const media = concatBytes(samples.map(function (sample) { return sample.data; }));
    return concatBytes([build(moofSize + 8), uint(4, media.byteLength + 8), ascii("mdat"), media]);
}

// Builds an avcC box body out of the SPS and PPS NAL units in front of an H.264
// key frame, which is in the 4 byte length prefixed form WebCodecs uses for
// format "avc". Null when the frame doesn't carry both.
function avcDecoderConfigFromKeyFrame(data) {
    const view = new DataView(data.buffer, data.byteOffset, data.byteLength);
    const spsList = [];
    const ppsList = [];
    let offset = 0;
    while (offset + 4 <= data.byteLength) {
        const length = view.getUint32(offset);
        const start = offset + 4;
        if (length === 0 || start + length > data.byteLength) break;
        const nal = data.subarray(start, start + length);
        const type = nal[0] & 0x1f;
        if (type === 7) spsList.push(nal);
        else if (type === 8) ppsList.push(nal);
        offset = start + length;
    }
    if (spsList.length === 0 || ppsList.length === 0) return null;
    const sps = spsList[0];
    const parts = [Uint8Array.of(1, sps[1], sps[2], sps[3], 0xff, 0xe0 | spsList.length)];
    spsList.forEach(function (nal) { parts.push(uint(2, nal.byteLength), nal); });
    parts.push(Uint8Array.of(ppsList.length));
    ppsList.forEach(function (nal) { parts.push(uint(2, nal.byteLength), nal); });
    return concatBytes(parts);
}

function wavHeader(sampleRate, dataBytes) {
    return concatBytes([
        ascii("RIFF"),
        littleEndian(4, 36 + dataBytes),
        ascii("WAVE"),
        ascii("fmt "),
        littleEndian(4, 16),
        // PCM, mono
        littleEndian(2, 1),
        littleEndian(2, 1),
        littleEndian(4, sampleRate),
        littleEndian(4, sampleRate * 2),
        littleEndian(2, 2),
        littleEndian(2, 16),
        ascii("data"),
        littleEndian(4, dataBytes),
    ]);
}

function littleEndian(byteCount, value) {
    const out = new Uint8Array(byteCount);
    const view = new DataView(out.buffer);
    if (byteCount === 2) view.setUint16(0, value, true);
    else view.setUint32(0, value, true);
    return out;
}

function pcm16(samples) {
    const out = new Uint8Array(samples.length * 2);
    const view = new DataView(out.buffer);
    for (let i = 0; i < samples.length; i++) {
        const clamped = Math.max(-1, Math.min(1, samples[i]));
        view.setInt16(i * 2, clamped < 0 ? clamped * 0x8000 : clamped * 0x7fff, true);
    }
    return out;
}

// Writes go through a worker because createSyncAccessHandle only exists in
// workers, and it is the only way of writing to the origin private file system
// that lands on disk as it goes. createWritable() keeps everything in a swap
// file until close(), which a crash or a closed tab never gets to.
//
// Each recording is a directory under "recordings", named by the recording's
// id, holding its files and an index.json listing them:
//   { files: [{ name, kind, startedAt, endedAt, uploaded }] }
// with times in milliseconds by the server's clock. A file whose endedAt is
// null was still being written when the page went away, and is repaired the
// next time at-chat opens. Once the server has all of a file, it's deleted here
// and its entry gets `uploaded: true`.
//
// The tab writing a recording holds a Web Lock named after it, which is
// released when the tab closes for any reason, so another tab never repairs a
// file that is still being recorded. Uploading has a lock of its own, so two
// tabs don't upload the same file.
const recordingFileWorker = `
${concatBytes.toString()}
${ascii.toString()}
${littleEndian.toString()}
${wavHeader.toString()}

const WAV_HEADER_BYTES = 44;
const AUDIO_BYTES_PER_SECOND = ${AUDIO_SAMPLE_RATE * 2};
const TIMESCALE = ${RECORDING_TIMESCALE};
const SAMPLE_RATE = ${AUDIO_SAMPLE_RATE};

const UPLOAD_PIECE_BYTES = 16 * 1024 * 1024;

let root = null;
const files = new Map();
const queue = [];
let busy = false;
let uploadUrl = null;
let uploadFinishedUrl = null;
let uploading = false;
let uploadAgain = false;

onmessage = function (event) {
    if (event.data.type === "pause-uploads") {
        uploadUrl = null;
    } else {
        queue.push(event.data);
        pump();
    }
};

async function pump() {
    if (busy) return;
    busy = true;
    while (queue.length > 0) {
        const message = queue.shift();
        try {
            await handle(message);
        } catch (e) {
            postMessage({ type: "error", name: e.name, message: String(e) });
        }
    }
    busy = false;
}

async function recordingsDirectory() {
    if (!root) root = await navigator.storage.getDirectory();
    return root.getDirectoryHandle("recordings", { create: true });
}

async function readIndex(directory) {
    try {
        const file = await (await directory.getFileHandle("index.json")).getFile();
        const index = JSON.parse(await file.text());
        if (index && Array.isArray(index.files)) return index;
    } catch (e) {
        // Missing or cut off partway through being written.
    }
    return { files: [] };
}

async function writeIndex(directory, index) {
    const access = await (await directory.getFileHandle("index.json", { create: true })).createSyncAccessHandle();
    const bytes = new TextEncoder().encode(JSON.stringify(index));
    access.truncate(0);
    access.write(bytes, { at: 0 });
    access.flush();
    access.close();
}

// Uploads change the index while recording does too, so changes wait their turn
// rather than one overwriting the other.
let indexChanges = Promise.resolve();

function changeIndex(directory, change) {
    const next = indexChanges.then(async function () {
        const index = await readIndex(directory);
        if (change(index) !== false) await writeIndex(directory, index);
        return index;
    });
    indexChanges = next.catch(function () {});
    return next;
}

async function handle(message) {
    if (message.type === "open") {
        const directory = await (await recordingsDirectory()).getDirectoryHandle(message.directory, { create: true });
        const access = await (await directory.getFileHandle(message.entry.name, { create: true })).createSyncAccessHandle();
        files.set(message.file, { access, size: access.getSize() });
        await changeIndex(directory, function (index) {
            index.files = index.files.filter(function (entry) { return entry.name !== message.entry.name; });
            index.files.push(message.entry);
        });
        return;
    }
    if (message.type === "ended") {
        const directory = await (await recordingsDirectory()).getDirectoryHandle(message.directory, { create: true });
        await changeIndex(directory, function (index) {
            index.files.forEach(function (entry) {
                if (entry.name === message.name) entry.endedAt = message.endedAt;
            });
        });
        return;
    }
    if (message.type === "release") {
        postMessage({ type: "released", directory: message.directory });
        return;
    }
    if (message.type === "recover") {
        await recoverAll();
        return;
    }
    // Queued like the rest, so files closed just before are seen as finished.
    if (message.type === "upload") {
        uploadUrl = message.url;
        uploadFinishedUrl = message.finishedUrl;
        uploadAll();
        return;
    }
    const file = files.get(message.file);
    if (!file) return;
    if (message.type === "append") {
        file.access.write(message.bytes, { at: file.size });
        file.size += message.bytes.byteLength;
    } else if (message.type === "write-at") {
        file.access.write(message.bytes, { at: message.at });
    } else if (message.type === "flush") {
        file.access.flush();
    } else if (message.type === "close") {
        file.access.flush();
        file.access.close();
        files.delete(message.file);
    }
}

async function recoverAll() {
    const recordings = await recordingsDirectory();
    const recovered = [];
    for await (const [name, directory] of recordings.entries()) {
        if (directory.kind !== "directory") continue;
        await navigator.locks.request("at-chat-recording " + name, { ifAvailable: true }, async function (lock) {
            // Held by a tab that is still recording into it.
            if (!lock) return;
            const index = await readIndex(directory);
            const endedAt = new Map();
            for (const entry of index.files) {
                if (entry.endedAt !== null) continue;
                const duration = await repair(directory, entry);
                if (duration === null) continue;
                endedAt.set(entry.name, entry.startedAt + Math.round(duration * 1000));
                recovered.push(entry.name);
            }
            if (endedAt.size > 0) {
                await changeIndex(directory, function (index2) {
                    index2.files.forEach(function (entry) {
                        if (endedAt.has(entry.name)) entry.endedAt = endedAt.get(entry.name);
                    });
                });
            }
        });
    }
    postMessage({ type: "recovered", files: recovered });
}

// Goes through every recording until each finished file is on the server, or
// until uploads are paused for a call. Asked to start while already going, it
// goes round once more so files finished in the meantime aren't left out.
async function uploadAll() {
    if (uploading) {
        uploadAgain = true;
        return;
    }
    uploading = true;
    try {
        do {
            uploadAgain = false;
            const recordings = await recordingsDirectory();
            for await (const [name, directory] of recordings.entries()) {
                if (directory.kind !== "directory" || uploadUrl === null) continue;
                await navigator.locks.request("at-chat-recording-upload " + name, { ifAvailable: true }, async function (lock) {
                    if (lock) await uploadRecording(recordings, name, directory);
                });
            }
        } while (uploadAgain && uploadUrl !== null);
    } catch (e) {
        postMessage({ type: "error", name: e.name, message: String(e) });
    } finally {
        uploading = false;
    }
}

async function uploadRecording(recordings, recordingId, directory) {
    const index = await readIndex(directory);
    for (const entry of index.files) {
        if (uploadUrl === null) return;
        if (entry.endedAt === null || entry.uploaded === true) continue;
        const done = await uploadFile(recordingId, directory, entry);
        if (!done) continue;
        await changeIndex(directory, function (index2) {
            index2.files.forEach(function (entry2) {
                if (entry2.name === entry.name) entry2.uploaded = true;
            });
        });
        await directory.removeEntry(entry.name).catch(function () {});
        postMessage({ type: "uploaded", recordingId, name: entry.name });
    }
    // Once everything is up, the server is told so it can add this device's part
    // to the recording's zip, and then the recording's directory goes too, unless
    // it's still being recorded into.
    const index2 = await readIndex(directory);
    if (index2.files.every(function (entry) { return entry.uploaded === true; })) {
        await navigator.locks.request("at-chat-recording " + recordingId, { ifAvailable: true }, async function (lock) {
            if (lock && await tellUploadFinished(recordingId)) {
                await recordings.removeEntry(recordingId, { recursive: true }).catch(function () {});
            }
        });
    }
}

// Returns false when it's worth trying again the next time uploads start. A
// recording the server won't take anything more for is as finished as it gets.
async function tellUploadFinished(recordingId) {
    if (uploadFinishedUrl === null) return false;
    try {
        const response = await fetch(uploadFinishedUrl + "?" + new URLSearchParams({ recordingId }).toString(), {
            method: "POST",
            credentials: "include",
        });
        return response.ok || (response.status >= 400 && response.status < 500);
    } catch (e) {
        return false;
    }
}

// Sends the file a piece at a time from wherever the server says it got up to.
// Returns true once the server has all of it, and false when it won't take the
// file or keeps failing, which is tried again the next time uploads start.
async function uploadFile(recordingId, directory, entry) {
    let file;
    try {
        file = await (await directory.getFileHandle(entry.name)).getFile();
    } catch (e) {
        return false;
    }
    if (file.size === 0) return true;
    let offset = 0;
    let failures = 0;
    // The first piece is empty, so that a file partly uploaded before only
    // costs a round trip to find out where it got to.
    let askedWhereFrom = false;
    while (uploadUrl !== null) {
        const end = askedWhereFrom ? Math.min(offset + UPLOAD_PIECE_BYTES, file.size) : offset;
        askedWhereFrom = true;
        const query = new URLSearchParams({
            recordingId,
            name: entry.name,
            startedAt: String(entry.startedAt),
            endedAt: String(entry.endedAt),
            size: String(file.size),
            offset: String(offset),
        });
        let response = null;
        try {
            response = await fetch(uploadUrl + "?" + query.toString(), {
                method: "POST",
                body: file.slice(offset, end),
                credentials: "include",
            });
        } catch (e) {
            // Offline, or the connection dropped partway.
        }
        if (response && (response.ok || response.status === 409)) {
            const serverHas = Number(await response.text());
            if (!Number.isFinite(serverHas) || serverHas > file.size) return false;
            if (response.ok && serverHas === file.size) return true;
            offset = serverHas;
            failures = 0;
        } else if (response && response.status >= 400 && response.status < 500) {
            return false;
        } else {
            failures += 1;
            if (failures > 6) return false;
            await new Promise(function (resolve) {
                setTimeout(resolve, 1000 * 2 ** failures);
            });
        }
    }
    return false;
}

// Cuts a file back to what was completely written, and returns how many
// seconds long it is, or null when it can't be opened.
async function repair(directory, entry) {
    let access;
    try {
        access = await (await directory.getFileHandle(entry.name)).createSyncAccessHandle();
    } catch (e) {
        return null;
    }
    try {
        return entry.name.endsWith(".wav") ? repairWav(access) : repairMp4(access);
    } finally {
        access.flush();
        access.close();
    }
}

function repairWav(access) {
    const size = access.getSize();
    if (size < WAV_HEADER_BYTES) {
        access.truncate(0);
        access.write(wavHeader(SAMPLE_RATE, 0), { at: 0 });
        return 0;
    }
    // Samples are two bytes, so half of one is a write that was cut off.
    const dataBytes = (size - WAV_HEADER_BYTES) - ((size - WAV_HEADER_BYTES) % 2);
    access.truncate(WAV_HEADER_BYTES + dataBytes);
    access.write(wavHeader(SAMPLE_RATE, dataBytes), { at: 0 });
    return dataBytes / AUDIO_BYTES_PER_SECOND;
}

function readBytes(access, at, length) {
    const bytes = new Uint8Array(length);
    const read = access.read(bytes, { at });
    return read === length ? bytes : null;
}

// Walks the top level boxes and keeps everything up to the last fragment that
// was written in full, a moof followed by its whole mdat. The duration comes
// from the last fragment's start time plus the length of its samples.
function repairMp4(access) {
    const size = access.getSize();
    let offset = 0;
    let keep = 0;
    let lastMoof = null;
    let duration = 0;
    while (offset + 8 <= size) {
        const header = readBytes(access, offset, 8);
        if (!header) break;
        const view = new DataView(header.buffer);
        const boxSize = view.getUint32(0);
        const type = String.fromCharCode(header[4], header[5], header[6], header[7]);
        if (boxSize < 8 || offset + boxSize > size) break;
        if (type === "moof") {
            lastMoof = readBytes(access, offset, boxSize);
        } else if (type === "mdat") {
            if (lastMoof) {
                const fragmentEnd = moofEndTime(lastMoof);
                if (fragmentEnd !== null) duration = fragmentEnd / TIMESCALE;
            }
            lastMoof = null;
            keep = offset + boxSize;
        } else if (type === "ftyp" || type === "moov") {
            keep = offset + boxSize;
        }
        offset += boxSize;
    }
    access.truncate(keep);
    return duration;
}

// tfdt's start time plus every sample duration in trun, for the boxes this
// recorder writes.
function moofEndTime(moof) {
    const view = new DataView(moof.buffer, moof.byteOffset, moof.byteLength);
    let start = null;
    let total = 0;
    function walk(from, to) {
        let at = from;
        while (at + 8 <= to) {
            const boxSize = view.getUint32(at);
            const type = String.fromCharCode(moof[at + 4], moof[at + 5], moof[at + 6], moof[at + 7]);
            if (boxSize < 8 || at + boxSize > to) return;
            if (type === "traf") {
                walk(at + 8, at + boxSize);
            } else if (type === "tfdt") {
                start = moof[at + 8] === 1 ? Number(view.getBigUint64(at + 12)) : view.getUint32(at + 12);
            } else if (type === "trun") {
                const flags = view.getUint32(at + 8) & 0xffffff;
                const count = view.getUint32(at + 12);
                let entry = at + 16;
                if (flags & 0x1) entry += 4;
                if (flags & 0x4) entry += 4;
                const entrySize = ((flags & 0x100) ? 4 : 0) + ((flags & 0x200) ? 4 : 0) + ((flags & 0x400) ? 4 : 0) + ((flags & 0x800) ? 4 : 0);
                if (flags & 0x100) {
                    for (let i = 0; i < count; i++) total += view.getUint32(entry + i * entrySize);
                }
            }
            at += boxSize;
        }
    }
    walk(8, moof.byteLength);
    return start === null ? null : start + total;
}
`;

exports.init = async function init(app) {
    // The call we are in, or null. Shape:
    //   socket, stream, captureVideo, audioContext
    //   selfId          "<userId> <clientId>", the label on everything we send
    //   roomId          the Call.CallId string, for building peer node ids
    //   peers           Map<senderKey, peer>, see addPeer
    //   camera          the camera's outgoing video, see outgoingVideo
    //   screen          the screen being shared, see startScreenShare
    let call = null;
    // Set as soon as a call is starting, before `call` is.
    let inCall = false;
    let localStreamPreview = null;
    const screenFramesStopWhenGone = /Firefox\//.test(navigator.userAgent);

    // Must match Call.connectionIdToString, which the peer's <canvas> id is
    // built from: "<dmOtherUserId> <peerUserId> <peerClientId>". `senderKey` is
    // already "<peerUserId> <peerClientId>", the Call.otherUserIdToString half.
    function peerNodeId(roomId, senderKey) {
        return roomId + " " + senderKey;
    }

    // Rebuilds the ConnectionId record Call.connectionIdCodec decodes, so Elm
    // can be told which peer started or stopped speaking.
    function connectionId(roomId, senderKey) {
        return { roomId: roomId, otherClientId: senderKey };
    }

    // Every chunk is one binary message:
    //   byte 0        length of the sender label in bytes
    //   bytes 1..n    the sender label, "<userId> <clientId>"
    //   next byte     kind, 0 = camera, 1 = audio and 2 = shared screen
    //   next byte     1 when this is a key frame
    //   next byte     which video codec encoded it, ignored for audio
    //   next 8 bytes  the chunk's own timestamp, which the decoder needs back
    //   rest          the encoded frame
    //
    // The codec byte is what lets two browsers that chose differently still
    // understand each other. Nothing else announces it, and a decoder set up for
    // the wrong one produces no picture and no error worth acting on.
    const VIDEO = 0;
    const AUDIO = 1;
    const SCREEN = 2;
    // vp8 goes first because on Linux Mint OS Xfce avc1 will be reported as supported and then fail when used.
    // The last one is H.264 at level 4.0, the lowest that fits a 1080p screen.
    const CODECS = ["vp8", "avc1.42001E", "avc1.420028"];
    const CAMERA_CODECS = [0, 1];
    const SCREEN_CODECS = [0, 2];
    const HEADER_AFTER_SENDER = 11;

    const textEncoder = new TextEncoder();
    const textDecoder = new TextDecoder();

    function packet(senderBytes, kind, codec, chunk) {
        const data = new Uint8Array(chunk.byteLength);
        chunk.copyTo(data);

        const headerBytes = 1 + senderBytes.byteLength + HEADER_AFTER_SENDER;
        const message = new Uint8Array(headerBytes + data.byteLength);
        const header = new DataView(message.buffer);
        header.setUint8(0, senderBytes.byteLength);
        message.set(senderBytes, 1);
        header.setUint8(1 + senderBytes.byteLength, kind);
        header.setUint8(2 + senderBytes.byteLength, chunk.type === "key" ? 1 : 0);
        header.setUint8(3 + senderBytes.byteLength, codec);
        header.setFloat64(4 + senderBytes.byteLength, chunk.timestamp);
        message.set(data, headerBytes);
        return message;
    }

    function unpack(buffer) {
        const header = new DataView(buffer);
        const senderLength = header.getUint8(0);
        // A message too short to hold its own header is not one of ours.
        if (buffer.byteLength < 1 + senderLength + HEADER_AFTER_SENDER) return null;
        return {
            sender: textDecoder.decode(new Uint8Array(buffer, 1, senderLength)),
            kind: header.getUint8(1 + senderLength),
            type: header.getUint8(2 + senderLength) === 1 ? "key" : "delta",
            codec: header.getUint8(3 + senderLength),
            timestamp: header.getFloat64(4 + senderLength),
            data: new Uint8Array(buffer, 1 + senderLength + HEADER_AFTER_SENDER),
        };
    }

    // H.264 in annexb and VP8 both decode without a codec description, which
    // saves having to ship the encoder's metadata over the wire. Safari only has
    // the first, Chrome has both.
    async function pickVideoCodec(codecIndices, baseConfig) {
        for (const index of codecIndices) {
            const config = Object.assign({}, baseConfig, { codec: CODECS[index] });
            if (CODECS[index].startsWith("avc1")) config.avc = { format: "annexb" };
            try {
                const support = await VideoEncoder.isConfigSupported(config);
                if (support.supported) return { config, index };
            } catch (e) {
                // Unsupported codec strings can throw rather than report false.
            }
        }
        return null;
    }

    // Everything about one video stream we send, which the camera and a shared
    // screen each have one of:
    //   kind            VIDEO or SCREEN, stamped onto every chunk
    //   codec           which of CODECS the encoder settled on, likewise
    //   config          the encoder config, kept so the encoder can be set up
    //                   again at a different size
    //   encoder, size   the live encoder and the size it was set up for
    //   startTime       the frame clock's zero, see pumpVideo
    //   forceKeyFrame   set when the next frame has to be a key frame
    function outgoingVideo(kind, picked) {
        return {
            kind,
            codec: picked.index,
            config: picked.config,
            encoder: null,
            size: null,
            startTime: null,
            forceKeyFrame: false,
        };
    }

    function fail(message) {
        app.ports.voice_chat_from_js.send({ tag: "start-connection-error", args: [String(message)] });
    }

    // --- the call ---

    async function startCall(args) {
        await stopCall();
        inCall = true;
        if (recordingWorker) recordingWorker.postMessage({ type: "pause-uploads" });

        if (typeof VideoEncoder === "undefined" || typeof AudioEncoder === "undefined") {
            fail("This browser is missing WebCodecs. Needs Chrome 94+, Firefox 132+ or Safari 26+.");
            return;
        }

        let stream;
        try {
            stream = await getUserMedia(args);
            const devices = await navigator.mediaDevices.enumerateDevices();
            const defaultDevices = [];
            stream.getTracks().forEach(function (track) {
                defaultDevices.push(track.getSettings().deviceId);
            });
            app.ports.voice_chat_from_js.send({ tag: "got-media-devices", args: [devices, defaultDevices] });
        } catch (e) {
            app.ports.voice_chat_from_js.send({ tag: "got-media-devices-error", args: [e.toString()] });
            return;
        }

        // Pinned to opus's sample rate so the encoder never has to resample, and
        // shared with playback so every peer mixes into the same context.
        const audioContext = new AudioContext({ sampleRate: AUDIO_SAMPLE_RATE });
        audioContext.resume().catch(function () {});

        const state = {
            socket: null,
            stream,
            // Capture reads frames off a video element, and the one Elm renders
            // is only in the page while the call is on screen. Collapsing the
            // sidebar would otherwise stop the camera feeding the encoder, so
            // capture gets an element of its own that never enters the document.
            captureVideo: document.createElement("video"),
            audioContext,
            selfId: args.selfId,
            senderBytes: textEncoder.encode(args.selfId),
            roomId: args.roomId,
            peers: new Map(),
            videoInputEnabled: args.videoInputEnabled,
            // Stays null when there is no camera.
            camera: null,
            screen: null,
            // True while the browser's screen picker is open, so a second press
            // doesn't open another.
            screenRequested: false,
            audioEncoder: null,
            audioNodes: [],
            framesCaptured: 0,
            stopped: false,
        };
        call = state;

        state.captureVideo.muted = true;
        state.captureVideo.playsInline = true;
        state.captureVideo.srcObject = stream;
        try {
            await state.captureVideo.play();
        } catch (e) {
            // Autoplay of a muted element is allowed everywhere this runs, so a
            // rejection here means the tracks are gone rather than blocked.
            fail("could not start capture: " + e);
            await stopCall();
            return;
        }
        if (state.stopped) return;

        await stopLocalStream();
        localStreamPreview = stream;
        showLocalPreview(stream);
        startLocalSpeaking(stream);

        const socket = new WebSocket(args.websocketUrl);
        socket.binaryType = "arraybuffer";
        state.socket = socket;

        await new Promise(function (resolve) {
            socket.onopen = resolve;
            socket.onerror = resolve;
            socket.onclose = resolve;
        });
        if (state.stopped) return;
        if (socket.readyState !== WebSocket.OPEN) {
            // The rust server answers the handshake with 403 when the backend
            // says this session does not belong in the room, which arrives here
            // as a socket that closed instead of opening.
            fail("could not join the call");
            await stopCall();
            return;
        }

        socket.onclose = function (event) {
            if (!state.stopped) fail("call connection closed (code " + event.code + ")");
        };
        socket.onerror = function () {
            if (!state.stopped) fail("call connection error");
        };
        socket.onmessage = function (event) {
            if (!state.stopped) receive(state, event.data);
        };

        await startEncoding(state, args);
    }

    async function startEncoding(state, args) {
        const videoTrack = state.stream.getVideoTracks()[0];
        const settings = videoTrack ? videoTrack.getSettings() : {};
        const videoConfig = await pickVideoCodec(CAMERA_CODECS, {
            width: settings.width || 640,
            height: settings.height || 480,
            bitrate: 1_000_000,
            framerate: 30,
        });
        if (state.stopped) return;

        if (videoTrack && !videoConfig) {
            fail("No supported video codec found (tried H.264 and VP8).");
        } else if (videoTrack) {
            const camera = outgoingVideo(VIDEO, videoConfig);
            state.camera = camera;

            // A decoder can do nothing with delta frames until it has seen a
            // key frame, so one goes out every 2s to bound how long recovering
            // from a loss takes, and immediately when somebody joins rather than
            // making them wait out the interval staring at nothing.
            let frameCount = 0;
            pumpVideo(state, function (frame) {
                const encoder = videoEncoderFor(state, camera, frame.displayWidth, frame.displayHeight);
                if (!encoder) return;
                const forced = camera.forceKeyFrame;
                camera.forceKeyFrame = false;
                encoder.encode(frame, { keyFrame: forced || frameCount % 60 === 0 });
                frameCount += 1;
            });
        }

        if (state.stream.getAudioTracks().length > 0) {
            // Mono, because that is what voice chat needs and it keeps the
            // AudioData the worklet produces to a single plane.
            const audioEncoder = new AudioEncoder({
                output: function (chunk) {
                    send(state, AUDIO, 0, chunk);
                },
                error: function (e) {
                    fail("audio encoder: " + e);
                },
            });
            audioEncoder.configure({
                codec: "opus",
                sampleRate: AUDIO_SAMPLE_RATE,
                numberOfChannels: 1,
                bitrate: 64000,
            });
            state.audioEncoder = audioEncoder;

            await pumpAudio(state, function (audioData) {
                if (audioEncoder.state !== "configured") return;
                audioEncoder.encode(audioData);
            });
        }

        setAudioInputEnabled(args.audioInputEnabled);
        setVideoInputEnabled(args.videoInputEnabled);
    }

    // A WebCodecs encoder that errors is closed for good, so the one thing that
    // must not happen is assuming the encoder from a moment ago is still usable:
    // every frame after would throw, which is what turned one bad frame into a
    // permanent loss of video.
    //
    // A frame that is not the size the encoder was configured for gets a fresh
    // encoder rather than another configure() call on the live one. Configuring
    // twice is allowed by the spec, but Firefox's H.264 encoder answers it with
    // NotSupportedError, and building a new encoder is supported everywhere.
    function videoEncoderFor(state, outgoing, width, height) {
        if (width === 0 || height === 0) return null;

        const wrongSize =
            outgoing.size && (outgoing.size.width !== width || outgoing.size.height !== height);

        if (outgoing.encoder && (outgoing.encoder.state === "closed" || wrongSize)) {
            if (outgoing.encoder.state !== "closed") outgoing.encoder.close();
            outgoing.encoder = null;
        }

        if (!outgoing.encoder) {
            outgoing.encoder = new VideoEncoder({
                output: function (chunk) {
                    send(state, outgoing.kind, outgoing.codec, chunk);
                },
                error: function (e) {
                    fail("video encoder: " + e);
                },
            });
            outgoing.encoder.configure(
                Object.assign({}, outgoing.config, { width, height })
            );
            outgoing.size = { width, height };
            // A new encoder starts a new stream, which no decoder can join
            // partway through.
            outgoing.forceKeyFrame = true;
        }

        return outgoing.encoder;
    }

    function readyToSend(state) {
        return !state.stopped && state.socket && state.socket.readyState === WebSocket.OPEN;
    }

    function send(state, kind, codec, chunk) {
        if (!readyToSend(state)) return;
        state.socket.send(packet(state.senderBytes, kind, codec, chunk));
    }

    // Takes each new camera frame off the capture element. The frame has to be
    // closed again immediately: WebCodecs frames hold real memory and the
    // pipeline stalls within a second or two if they pile up.
    function pumpVideo(state, encode) {
        const videoElement = state.captureVideo;
        if (typeof videoElement.requestVideoFrameCallback !== "function") {
            fail("requestVideoFrameCallback is missing, needs Firefox 132+");
            return;
        }

        // An encoder will only accept timestamps that increase, so the frame
        // clock is the monotonic one rVFC hands us rather than the element's
        // media time. Media time stops while the camera track is disabled and
        // need not resume where it left off, and it is in different units, so
        // mixing the two could hand the encoder a timestamp millions of times
        // too large followed by one that went backwards.
        function onFrame(now) {
            if (state.stopped) return;

            // With the camera off there is nothing worth sending, and a disabled
            // track does not necessarily keep producing frames the size the
            // encoder was set up for. The callback below stays registered, so
            // capture picks up again on the first frame after it comes back.
            if (!state.videoInputEnabled) {
                recordCameraOff();
                videoElement.requestVideoFrameCallback(onFrame);
                return;
            }

            if (state.camera.startTime === null) state.camera.startTime = now;

            try {
                const frame = new VideoFrame(videoElement, {
                    timestamp: Math.round((now - state.camera.startTime) * 1000),
                });
                recordCameraFrame(frame, now);
                if (readyToSend(state)) encode(frame);
                frame.close();
            } catch (e) {
                fail("capture: " + e);
            }

            videoElement.requestVideoFrameCallback(onFrame);
        }

        videoElement.requestVideoFrameCallback(onFrame);
    }

    // Rebuilds AudioData from the raw samples the worklet batches up, since
    // there is no portable way to get it off the track directly.
    async function pumpAudio(state, encode) {
        const context = state.audioContext;
        const moduleUrl = URL.createObjectURL(new Blob([captureWorklet], { type: "application/javascript" }));
        try {
            await context.audioWorklet.addModule(moduleUrl);
        } finally {
            URL.revokeObjectURL(moduleUrl);
        }
        if (state.stopped) return;

        const source = context.createMediaStreamSource(state.stream);
        const capture = new AudioWorkletNode(context, "capture-processor", {
            channelCount: 1,
            channelCountMode: "explicit",
        });

        capture.port.onmessage = function (event) {
            const samples = event.data;
            if (!state.stopped) {
                const micOn = state.stream.getAudioTracks().some(function (track) {
                    return track.enabled && track.readyState === "live";
                });
                if (micOn) recordAudio(samples);
                else recordAudioOff();
            }
            if (!readyToSend(state)) return;
            const audioData = new AudioData({
                format: "f32-planar",
                sampleRate: AUDIO_SAMPLE_RATE,
                numberOfFrames: samples.length,
                numberOfChannels: 1,
                timestamp: Math.round((state.framesCaptured / AUDIO_SAMPLE_RATE) * 1e6),
                data: samples,
            });
            state.framesCaptured += samples.length;
            encode(audioData);
            audioData.close();
        };

        // The worklet only runs while its output goes somewhere, so it feeds a
        // silent gain node. Routing it to the speakers directly would play the
        // mic back on top of the decoded audio.
        const silence = context.createGain();
        silence.gain.value = 0;
        source.connect(capture);
        capture.connect(silence);
        silence.connect(context.destination);
        state.audioNodes = [source, capture, silence];
    }

    // --- sharing our screen ---

    async function startScreenShare() {
        const state = call;
        if (!state || state.screen || state.screenRequested) return;

        if (!navigator.mediaDevices || typeof navigator.mediaDevices.getDisplayMedia !== "function") {
            fail("This browser can't share its screen.");
            screenShareStopped();
            return;
        }

        state.screenRequested = true;
        let stream;
        try {
            stream = await navigator.mediaDevices.getDisplayMedia({
                video: {
                    width: { max: SCREEN_MAX_WIDTH },
                    height: { max: SCREEN_MAX_HEIGHT },
                    frameRate: { max: SCREEN_FRAME_RATE },
                },
                audio: false,
            });
        } catch (e) {
            state.screenRequested = false;
            // Closing the picker without choosing anything also lands here,
            // and isn't worth an error box.
            if (e.name !== "NotAllowedError" && e.name !== "AbortError") fail("screen share: " + e);
            screenShareStopped();
            return;
        }
        state.screenRequested = false;

        const track = stream.getVideoTracks()[0];
        if (state.stopped || !track) {
            stream.getTracks().forEach(function (t) { t.stop(); });
            screenShareStopped();
            return;
        }
        // Tells the encoder to keep text sharp rather than motion smooth.
        if ("contentHint" in track) track.contentHint = "detail";

        const settings = track.getSettings();
        const picked = await pickVideoCodec(SCREEN_CODECS, {
            width: settings.width || SCREEN_MAX_WIDTH,
            height: settings.height || SCREEN_MAX_HEIGHT,
            bitrate: SCREEN_BITRATE,
            framerate: SCREEN_FRAME_RATE,
        });
        if (state.stopped || !picked) {
            if (!picked) fail("No supported video codec found for screen sharing.");
            stream.getTracks().forEach(function (t) { t.stop(); });
            screenShareStopped();
            return;
        }

        const screen = {
            stream,
            // Same reason as the camera's capture element: it has to keep
            // producing frames whatever Elm is drawing.
            captureVideo: document.createElement("video"),
            outgoing: outgoingVideo(SCREEN, picked),
            lastKeyFrameTime: null,
            lastFrameTime: null,
            // Frames the browser actually produced, as opposed to ones the
            // idle timer took by hand.
            browserFrames: 0,
            lastBrowserFrameTime: performance.now(),
            trackEvents: [],
            lastTimestamp: -1,
            idleTimer: null,
            stopped: false,
        };
        screen.captureVideo.muted = true;
        screen.captureVideo.playsInline = true;
        screen.captureVideo.srcObject = stream;
        try {
            await screen.captureVideo.play();
        } catch (e) {
            fail("could not start screen capture: " + e);
            stream.getTracks().forEach(function (t) { t.stop(); });
            screenShareStopped();
            return;
        }
        if (state.stopped) {
            stream.getTracks().forEach(function (t) { t.stop(); });
            screenShareStopped();
            return;
        }

        state.screen = screen;
        // The browser shows its own "stop sharing" control, which ends the
        // track without asking us.
        track.addEventListener("ended", function () {
            if (state.screen === screen) stopScreenShare(state);
        });
        ["ended", "mute", "unmute"].forEach(function (name) {
            track.addEventListener(name, function () {
                screen.trackEvents.push(name + " at " + (performance.now() / 1000).toFixed(1) + "s");
            });
        });
        app.ports.voice_chat_from_js.send({ tag: "screen-share-started", args: [] });
        pumpScreen(state, screen);
    }

    function pumpScreen(state, screen) {
        const videoElement = screen.captureVideo;
        const outgoing = screen.outgoing;

        function encodeFrame(now) {
            showScreenPreview(screen.stream);
            if (state.stopped || (!readyToSend(state) && !recorder)) return;
            if (outgoing.startTime === null) outgoing.startTime = now;
            screen.lastFrameTime = now;

            // The idle timer's clock and rVFC's are close but not the same, and
            // an encoder rejects a timestamp that doesn't increase.
            const timestamp = Math.max(
                screen.lastTimestamp + 1,
                Math.round((now - outgoing.startTime) * 1000)
            );

            let frame;
            try {
                frame = new VideoFrame(videoElement, { timestamp });
            } catch (e) {
                fail("screen capture: " + e);
                return;
            }
            recordScreenFrame(frame, now);
            if (!readyToSend(state)) {
                frame.close();
                return;
            }
            const encoder = videoEncoderFor(state, outgoing, frame.displayWidth, frame.displayHeight);
            // Encoding a 1080p screen in software can fall behind, and frames
            // that queue up only add delay, so they are dropped instead.
            if (encoder && encoder.encodeQueueSize <= 2) {
                const keyFrame =
                    outgoing.forceKeyFrame ||
                    screen.lastKeyFrameTime === null ||
                    now - screen.lastKeyFrameTime >= SCREEN_KEY_FRAME_INTERVAL_MS;
                outgoing.forceKeyFrame = false;
                if (keyFrame) screen.lastKeyFrameTime = now;
                screen.lastTimestamp = timestamp;
                encoder.encode(frame, { keyFrame });
            }
            frame.close();
        }

        function onFrame(now) {
            if (screen.stopped) return;
            screen.browserFrames += 1;
            screen.lastBrowserFrameTime = now;
            encodeFrame(now);
            videoElement.requestVideoFrameCallback(onFrame);
        }

        videoElement.requestVideoFrameCallback(onFrame);
        screen.idleTimer = setInterval(function () {
            if (screen.stopped) return;
            // In case the browser ended the track without an "ended" event.
            if (screen.stream.getVideoTracks().every(function (t) { return t.readyState === "ended"; })) {
                if (state.screen === screen) stopScreenShare(state);
                return;
            }
            const now = performance.now();
            if (screenFramesStopWhenGone) {
                // Frames come through rVFC, which doesn't run while the page
                // isn't drawn, so that time doesn't count.
                if (document.hidden) {
                    screen.lastBrowserFrameTime = now;
                } else if (now - screen.lastBrowserFrameTime >= SCREEN_GONE_MS) {
                    if (state.screen === screen) stopScreenShare(state);
                    return;
                }
            }
            if (screen.lastFrameTime === null || now - screen.lastFrameTime >= SCREEN_IDLE_FRAME_MS) {
                encodeFrame(now);
            }
        }, SCREEN_IDLE_FRAME_MS);
    }

    // Elm only draws the preview while the call is on screen, and draws a new
    // element when it comes back, so this is checked again on every frame.
    function showScreenPreview(stream) {
        const videoNode = document.getElementById(LOCAL_SCREEN_NODE_ID);
        if (!videoNode || videoNode.srcObject === stream) return;
        videoNode.muted = true;
        videoNode.srcObject = stream;
        videoNode.play().catch(function () {});
    }

    function stopScreenShare(state) {
        const screen = state.screen;
        if (!screen) return;
        state.screen = null;
        screen.stopped = true;
        clearInterval(screen.idleTimer);
        if (screen.outgoing.encoder && screen.outgoing.encoder.state !== "closed") {
            screen.outgoing.encoder.close();
        }
        screen.captureVideo.srcObject = null;
        const preview = document.getElementById(LOCAL_SCREEN_NODE_ID);
        if (preview && preview.srcObject === screen.stream) preview.srcObject = null;
        screen.stream.getTracks().forEach(function (track) { track.stop(); });
        recordScreenStopped();
        screenShareStopped();
    }

    function screenShareStopped() {
        app.ports.voice_chat_from_js.send({ tag: "screen-share-stopped", args: [] });
    }

    // --- receiving peers ---

    function receive(state, buffer) {
        const message = unpack(buffer);
        // Our own messages never come back: the room relays to everyone else.
        if (!message || message.sender === state.selfId) return;

        const peer = state.peers.get(message.sender) || addPeer(state, message.sender);
        if (!peer) return;

        if (message.kind === VIDEO || message.kind === SCREEN) {
            const video = message.kind === VIDEO ? peer.camera : peer.screen;
            if (video.codec !== message.codec) {
                configurePeerVideo(video, message.codec);
            }
            if (!video.decoder) return;
            // A decoder that starts mid-stream has to wait for a key frame.
            if (!video.ready && message.type !== "key") return;
            video.ready = true;
            try {
                video.decoder.decode(new EncodedVideoChunk({
                    type: message.type,
                    timestamp: message.timestamp,
                    data: message.data,
                }));
            } catch (e) {
                // The decoder died between the error callback firing and now.
                dropPeerVideo(video);
            }
        } else if (message.kind === AUDIO) {
            try {
                peer.audioDecoder.decode(new EncodedAudioChunk({
                    type: message.type,
                    timestamp: message.timestamp,
                    data: message.data,
                }));
            } catch (e) {
                // Same, for audio. Nothing to rebuild from, so this peer is
                // silent until they leave and rejoin.
            }
        }
    }

    function addPeer(state, senderKey) {
        const context = state.audioContext;

        // Volume rides on a gain node per peer, because a canvas has no volume
        // of its own the way the <video> elements this replaced did.
        const gain = context.createGain();
        gain.gain.value = 1;
        gain.connect(context.destination);

        const nodeId = peerNodeId(state.roomId, senderKey);
        const peer = {
            senderKey,
            camera: peerVideo(nodeId),
            // Must match Call.screenShareNodeId.
            screen: peerVideo(nodeId + " screen"),
            gain,
            playheadSeconds: 0,
            audioDecoder: null,
            // What updateSpeaking works on: who this loudness belongs to, and
            // whether Elm has been told they are speaking.
            speaker: { tag: "is-connection", args: [connectionId(state.roomId, senderKey)] },
            isSpeaking: false,
            speakingTimeout: null,
        };

        peer.audioDecoder = new AudioDecoder({
            output: function (audioData) {
                playAudio(state, peer, audioData);
                audioData.close();
            },
            error: function () {},
        });
        peer.audioDecoder.configure({
            codec: "opus",
            sampleRate: AUDIO_SAMPLE_RATE,
            numberOfChannels: 1,
        });

        state.peers.set(senderKey, peer);
        return peer;
    }

    // One video stream a peer sends us, their camera or their screen, and the
    // <canvas> Elm renders for it.
    function peerVideo(nodeId) {
        return { nodeId, canvas: null, ready: false, codec: null, decoder: null };
    }

    // A decoder that errors is closed for good, so recovering from one means
    // building another. That makes this the one path for both the first chunk a
    // peer sends and every rebuild after, and it remembers which codec it was
    // last asked for so an unsupported one is not retried on every frame.
    function configurePeerVideo(video, codec) {
        dropPeerVideo(video);
        video.codec = codec;

        const name = CODECS[codec];
        if (!name) return;

        try {
            const decoder = new VideoDecoder({
                output: function (frame) {
                    drawFrame(video, frame);
                    frame.close();
                },
                // Asking for the codec again is what rebuilds this decoder, so
                // forgetting it is what lets the next chunk do that.
                error: function () {
                    dropPeerVideo(video);
                },
            });
            decoder.configure({ codec: name });
            video.decoder = decoder;
        } catch (e) {
            // This browser cannot decode what the peer encoded with. Their audio
            // still works, so the call carries on without their picture.
        }
    }

    function dropPeerVideo(video) {
        if (video.decoder && video.decoder.state !== "closed") {
            video.decoder.close();
        }
        video.decoder = null;
        video.codec = null;
        video.ready = false;
    }

    // Clearing rather than painting black leaves the canvas transparent, and the
    // background it sits on is already black, so it looks the same as a camera
    // that is on but seeing nothing.
    function clearCanvas(canvas) {
        if (!canvas) return;
        const context = canvas.getContext("2d");
        if (context) context.clearRect(0, 0, canvas.width, canvas.height);
    }

    function drawFrame(video, frame) {
        // Elm renders the peer's canvas only once it knows the peer is in the
        // call, or sharing their screen, which can be after their first frame
        // arrives, so it is looked up again until it appears.
        if (!video.canvas || !video.canvas.isConnected) {
            video.canvas = document.getElementById(video.nodeId);
        }
        if (!video.canvas) return;

        const context = video.canvas.getContext("2d");
        if (!context) return;
        if (video.canvas.width !== frame.displayWidth || video.canvas.height !== frame.displayHeight) {
            video.canvas.width = frame.displayWidth;
            video.canvas.height = frame.displayHeight;
        }
        context.drawImage(frame, 0, 0);
    }

    // Queues decoded audio back to back. Each buffer is scheduled after the
    // previous one so the samples play continuously rather than on top of each
    // other; if the playhead falls behind, it resets with a small cushion.
    function playAudio(state, peer, audioData) {
        const context = state.audioContext;

        const channels = audioData.numberOfChannels;
        const buffer = context.createBuffer(channels, audioData.numberOfFrames, audioData.sampleRate);
        let loudest = 0;
        for (let channel = 0; channel < channels; channel++) {
            const samples = new Float32Array(audioData.numberOfFrames);
            audioData.copyTo(samples, { planeIndex: channel, format: "f32-planar" });
            buffer.copyToChannel(samples, channel);
            loudest = Math.max(loudest, meanAmplitude(samples));
        }

        const source = context.createBufferSource();
        source.buffer = buffer;
        source.connect(peer.gain);

        if (peer.playheadSeconds < context.currentTime) {
            peer.playheadSeconds = context.currentTime + 0.05;
        }
        source.start(peer.playheadSeconds);
        peer.playheadSeconds += buffer.duration;

        updateSpeaking(peer, loudest);
    }

    function peerLeft(connectionId2) {
        if (!call) return;
        removePeer(call, connectionId2.otherClientId);
    }

    function removePeer(state, senderKey) {
        const peer = state.peers.get(senderKey);
        if (!peer) return;
        updateSpeaking(peer, 0);
        dropPeerVideo(peer.camera);
        dropPeerVideo(peer.screen);
        if (peer.audioDecoder.state !== "closed") peer.audioDecoder.close();
        try { peer.gain.disconnect(); } catch (e) {}
        clearCanvas(peer.camera.canvas);
        clearCanvas(peer.screen.canvas);
        state.peers.delete(senderKey);
    }

    async function stopCall() {
        inCall = false;
        const state = call;
        call = null;
        if (!state) return;
        state.stopped = true;
        stopRecording().then(startRecordingUploads);

        stopScreenShare(state);
        for (const senderKey of [...state.peers.keys()]) {
            removePeer(state, senderKey);
        }
        state.audioNodes.forEach(function (node) {
            try { node.disconnect(); } catch (e) {}
        });
        [state.camera && state.camera.encoder, state.audioEncoder].forEach(function (encoder) {
            if (encoder && encoder.state !== "closed") encoder.close();
        });
        if (state.socket) state.socket.close();
        state.captureVideo.srcObject = null;
        // The preview shares these tracks, so it has to let go of them too.
        if (localStreamPreview === state.stream) {
            await stopLocalStream();
        }
        state.stream.getTracks().forEach(function (track) { track.stop(); });
        if (state.audioContext) state.audioContext.close().catch(function () {});
    }

    // --- local preview and devices ---

    function showLocalPreview(stream) {
        const videoNode = document.getElementById("local-video");
        if (!videoNode) return;
        // iOS Safari ignores HTMLMediaElement.volume so use muted + only feed
        // the video tracks into the preview element so the mic doesn't echo.
        videoNode.muted = true;
        const previewStream = new MediaStream();
        stream.getVideoTracks().forEach(function (track) {
            previewStream.addTrack(track);
        });
        videoNode.srcObject = previewStream;

        const playPromise = videoNode.play();
        if (playPromise && typeof playPromise.catch === "function") {
            playPromise.catch(function (err) {
                console.error("local-video: play() rejected", err);
            });
        }
    }

    function setAudioInputEnabled(enabled) {
        if (call) {
            call.stream.getAudioTracks().forEach(function (t) { t.enabled = enabled; });
        }
        if (localStreamPreview) {
            localStreamPreview.getAudioTracks().forEach(function (t) { t.enabled = enabled; });
        }
    }

    function setVideoInputEnabled(enabled) {
        if (call) {
            call.stream.getVideoTracks().forEach(function (t) { t.enabled = enabled; });
            // Nobody has had a frame from us while the camera was off, so what
            // they need first when it returns is a key frame.
            if (enabled && !call.videoInputEnabled && call.camera) call.camera.forceKeyFrame = true;
            call.videoInputEnabled = enabled;
        }
        if (localStreamPreview) {
            localStreamPreview.getVideoTracks().forEach(function (t) { t.enabled = enabled; });
        }
    }

    // Swapping a device swaps the track inside the stream the encoders read
    // from, so capture carries on against the new one without restarting.
    // Swaps one device's track inside the stream everything else already reads
    // from, so capture, the preview and the call carry on against the new one
    // without any of them being torn down.
    async function setInput(isAudioInput, deviceId) {
        const live = call ? call.stream : localStreamPreview;
        if (!live) return;

        const config = isAudioInput
            ? { audio: { deviceId: { exact: deviceId } } }
            : { video: { deviceId: { exact: deviceId } } };
        const stream = await navigator.mediaDevices.getUserMedia(config);
        const track = (isAudioInput ? stream.getAudioTracks() : stream.getVideoTracks())[0];
        if (!track) return;

        const replaced = isAudioInput ? live.getAudioTracks() : live.getVideoTracks();
        replaced.forEach(function (oldTrack) {
            // Muted stays muted across a device change.
            track.enabled = oldTrack.enabled;
            live.removeTrack(oldTrack);
            oldTrack.stop();
        });
        live.addTrack(track);

        if (isAudioInput) {
            // Both of these read the mic through a source node bound to the
            // track that just went away, so both need building again.
            rebindCapture(live);
            startLocalSpeaking(live);
        } else {
            // requestVideoFrameCallback follows the element and the element
            // follows the stream, so capture picks the new track up on its own.
            if (call) {
                call.captureVideo.srcObject = live;
                call.captureVideo.play().catch(function () {});
            }
            showLocalPreview(live);
        }
    }

    // Points the capture worklet at the stream's current mic track. The worklet
    // and its silent sink are kept; only the source in front of them changes.
    function rebindCapture(stream) {
        if (!call || call.audioNodes.length !== 3) return;
        const [oldSource, capture] = call.audioNodes;
        try { oldSource.disconnect(); } catch (e) {}
        const source = call.audioContext.createMediaStreamSource(stream);
        source.connect(capture);
        call.audioNodes[0] = source;
    }

    async function getDevices() {
        const devices = await navigator.mediaDevices.enumerateDevices();
        const hasMic = devices.some((a) => a.kind === "audioinput");
        const hasCamera = devices.some((a) => a.kind === "videoinput");
        if (!hasMic && !hasCamera) {
            return new MediaStream();
        }
        return await navigator.mediaDevices.getUserMedia({ audio: hasMic, video: hasCamera });
    }

    async function getUserMedia(args) {
        const devices = await navigator.mediaDevices.enumerateDevices();
        const hasMic = devices.some((a) => a.kind === "audioinput");
        const hasCamera = devices.some((a) => a.kind === "videoinput");
        if (!hasMic && !hasCamera) {
            return new MediaStream();
        }
        const config = {
            audio: args.audioInput ? { deviceId: { exact: args.audioInput } } : hasMic,
            video: args.videoInput ? { deviceId: { exact: args.videoInput } } : hasCamera,
        };
        return await navigator.mediaDevices.getUserMedia(config);
    }

    async function stopLocalStream() {
        const videoNode = document.getElementById("local-video");
        // While a call is running the preview shares the call's tracks, and
        // stopping them here would end the call's capture as well.
        if (localStreamPreview && (!call || call.stream !== localStreamPreview)) {
            localStreamPreview.getTracks().forEach((s) => s.stop());
        }
        if (videoNode) {
            videoNode.srcObject = null;
        }
        localStreamPreview = null;
        stopLocalSpeaking();
    }

    async function startLocalStream(args) {
        await stopLocalStream();

        try {
            localStreamPreview = await getUserMedia(args);
            const devices = await navigator.mediaDevices.enumerateDevices();

            const defaultDevices = [];
            localStreamPreview.getTracks().forEach((track) => {
                defaultDevices.push(track.getSettings().deviceId);
            });

            app.ports.voice_chat_from_js.send({ tag: "got-media-devices", args: [devices, defaultDevices] });
        } catch (e) {
            app.ports.voice_chat_from_js.send({ tag: "got-media-devices-error", args: [e.toString()] });
            return;
        }

        showLocalPreview(localStreamPreview);
        setAudioInputEnabled(args.audioInputEnabled);
        setVideoInputEnabled(args.videoInputEnabled);
        startLocalSpeaking(localStreamPreview);
    }

    // --- recording ---
    //
    // While the call is being recorded, everything this device captures is also
    // encoded a second time at a higher quality and saved, separately from what
    // goes out over the call. Each person keeps their own camera, mic and screen,
    // and they're lined up afterwards by the times in their file names.
    //
    // A camera file ends when the camera is turned off or changes size, a screen
    // file when the share stops or the shared window is resized, since one MP4
    // track can't change size partway, and a mic file when the mic is muted. The
    // next frame starts a new file.
    //
    // Shape of `recorder`:
    //   id           the recording's id, the directory its files go in
    //   userName     for the file names
    //   clockOffset  milliseconds to add to this device's clock to get the
    //                server's, or null until it has been measured
    //   camera       the camera's open file, see recordingVideoFile
    //   screen       likewise for a shared screen
    //   audio        the mic's open file, see recordAudio
    //   files        every file started, for the debug panel
    //   storageTimer checks there's still room, see checkRecordingStorage
    let recorder = null;
    let recordingWorker = null;
    let nextRecordingFile = 1;
    // Resolving one of these lets go of that recording's Web Lock.
    const recordingLockReleases = new Map();
    // Codecs an encoder has failed with on this device. Linux in particular can
    // report H.264 as supported and then fail on the first frame.
    const failedRecordingCodecs = new Set();
    // Settles once every recording that was stopped has its files closed.
    let recordingStopped = Promise.resolve();

    // H.264 High, Main and Baseline at level 5.1, which covers up to 4K, then
    // VP9 for browsers without an H.264 encoder.
    const RECORDING_CODECS = ["avc1.640033", "avc1.4d0033", "avc1.420033", "vp09.00.51.08"];

    // Below this much free space a warning is shown, and below the second the
    // recording on this device stops rather than failing partway through a write.
    const RECORDING_STORAGE_WARNING_BYTES = 2_000_000_000;
    const RECORDING_STORAGE_STOP_BYTES = 200_000_000;
    const RECORDING_STORAGE_CHECK_MS = 60_000;

    function startRecording(args) {
        if (recorder && recorder.id === args.recordingId) return;
        stopRecording();
        const starting = {
            id: args.recordingId,
            userName: args.userName,
            clockOffset: null,
            camera: null,
            screen: null,
            audio: null,
            files: [],
            storageWarningShown: false,
            storageTimer: null,
        };
        recorder = starting;

        if (navigator.locks) {
            navigator.locks.request("at-chat-recording " + starting.id, function () {
                return new Promise(function (resolve) {
                    recordingLockReleases.set(starting.id, resolve);
                });
            });
        }
        // Without this the browser may clear the origin's storage to make room
        // for something else, recording included.
        if (navigator.storage && navigator.storage.persist) navigator.storage.persist().catch(function () {});

        measureClockOffset(fileServer() + "/file/time").then(function (offset) {
            starting.clockOffset = offset;
        });
        checkRecordingStorage(starting);
        starting.storageTimer = setInterval(function () {
            checkRecordingStorage(starting);
        }, RECORDING_STORAGE_CHECK_MS);
    }

    function stopRecording() {
        const stopping = recorder;
        recorder = null;
        if (!stopping) return recordingStopped;
        clearInterval(stopping.storageTimer);
        recordingStopped = Promise.all([
            recordingStopped,
            stopping.camera ? closeRecordingVideoFile(stopping.camera) : null,
            stopping.screen ? closeRecordingVideoFile(stopping.screen) : null,
            stopping.audio ? closeRecordingAudioFile(stopping.audio) : null,
        ]).then(function () {
            // Queued behind the closes, so the lock is only let go of once the
            // files are finished.
            postToRecordingWorker({ type: "release", directory: stopping.id });
        });
        return recordingStopped;
    }

    // The files from everyone in a call are lined up by their start times, and
    // each device's clock can be off by seconds, so times are kept by the rust
    // server's clock. Of a few round trips, the quickest says the most about
    // when the server read its clock.
    async function measureClockOffset(timeUrl) {
        let best = null;
        for (let i = 0; i < 3; i++) {
            try {
                const sent = Date.now();
                const response = await fetch(timeUrl, { cache: "no-store" });
                const serverTime = Number(await response.text());
                const received = Date.now();
                if (!Number.isFinite(serverTime)) continue;
                const roundTrip = received - sent;
                if (best === null || roundTrip < best.roundTrip) {
                    best = { roundTrip, offset: serverTime - (sent + roundTrip / 2) };
                }
            } catch (e) {
                // Recorded by this device's clock instead, which is still close.
            }
        }
        return best === null ? 0 : Math.round(best.offset);
    }

    async function checkRecordingStorage(owner) {
        if (!navigator.storage || !navigator.storage.estimate) return;
        let estimate;
        try {
            estimate = await navigator.storage.estimate();
        } catch (e) {
            return;
        }
        if (recorder !== owner) return;
        const free = estimate.quota - estimate.usage;
        if (free < RECORDING_STORAGE_STOP_BYTES) {
            fail("Recording stopped on this device because it's out of storage space.");
            stopRecording();
        } else if (free < RECORDING_STORAGE_WARNING_BYTES && !owner.storageWarningShown) {
            owner.storageWarningShown = true;
            fail(
                "This device is running low on storage space for the recording (" +
                    (free / 1e9).toFixed(1) +
                    " GB left). It will stop recording when it runs out."
            );
        }
    }

    // Matches FileStatus.domain.
    function fileServer() {
        return location.origin.startsWith("http://localhost:") ? "http://localhost:3000" : location.origin;
    }

    // Uploads wait until this device isn't in a call, so they don't take
    // bandwidth the call needs.
    function startRecordingUploads() {
        if (inCall) return;
        postToRecordingWorker({
            type: "upload",
            url: fileServer() + "/file/recording-upload",
            finishedUrl: fileServer() + "/file/recording-upload-finished",
        });
    }

    function postToRecordingWorker(message, transfer) {
        if (!recordingWorker) {
            const url = URL.createObjectURL(new Blob([recordingFileWorker], { type: "application/javascript" }));
            recordingWorker = new Worker(url);
            URL.revokeObjectURL(url);
            recordingWorker.onmessage = function (event) {
                const data = event.data;
                if (data.type === "error") {
                    if (data.name === "QuotaExceededError") {
                        fail("Recording stopped on this device because it's out of storage space.");
                        stopRecording();
                    } else {
                        fail("recording: " + data.message);
                    }
                } else if (data.type === "released") {
                    const release = recordingLockReleases.get(data.directory);
                    recordingLockReleases.delete(data.directory);
                    if (release) release();
                } else if (data.type === "recovered") {
                    if (data.files.length > 0) console.log("Repaired recording files left unfinished last time:", data.files);
                    startRecordingUploads();
                }
            };
        }
        recordingWorker.postMessage(message, transfer || []);
    }

    function appendToRecordingFile(file, bytes) {
        file.bytes += bytes.byteLength;
        postToRecordingWorker({ type: "append", file: file.handle, bytes }, [bytes.buffer]);
    }

    function twoDigits(n) {
        return String(n).padStart(2, "0");
    }

    // VIDEO_Martin_2026-10-25_20-31-07.250.mp4, in local time, since that's
    // what the person editing it will think of the call as having started at.
    function recordingFileName(kind, userName, time, extension) {
        const date = new Date(time);
        const safeName = userName.replace(/[\\/:*?"<>|\u0000-\u001f]/g, "_").trim() || "unknown";
        return (
            kind + "_" + safeName + "_" +
            date.getFullYear() + "-" + twoDigits(date.getMonth() + 1) + "-" + twoDigits(date.getDate()) + "_" +
            twoDigits(date.getHours()) + "-" + twoDigits(date.getMinutes()) + "-" + twoDigits(date.getSeconds()) +
            "." + String(date.getMilliseconds()).padStart(3, "0") + "." + extension
        );
    }

    // The file isn't created until its first frame is ready to be written, so
    // its name and start time are the time of that frame.
    function openRecordingFile(owner, kind, extension) {
        const file = {
            owner,
            handle: nextRecordingFile,
            kind,
            extension,
            name: null,
            startedAt: null,
            bytes: 0,
        };
        nextRecordingFile += 1;
        owner.files.push(file);
        return file;
    }

    // `localTime` is when the first frame was captured, by this device's clock.
    function ensureRecordingFileOpen(file, localTime) {
        if (file.name !== null) return;
        file.startedAt = Math.round(localTime + (file.owner.clockOffset || 0));
        file.name = recordingFileName(file.kind, file.owner.userName, file.startedAt, file.extension);
        postToRecordingWorker({
            type: "open",
            file: file.handle,
            directory: file.owner.id,
            entry: { name: file.name, kind: file.kind, startedAt: file.startedAt, endedAt: null },
        });
    }

    function finishRecordingFile(file, localEndTime) {
        if (file.name === null) return;
        postToRecordingWorker({ type: "close", file: file.handle });
        postToRecordingWorker({
            type: "ended",
            directory: file.owner.id,
            name: file.name,
            endedAt: Math.round(localEndTime + (file.owner.clockOffset || 0)),
        });
    }

    async function pickRecordingCodec(width, height, framerate, bitrate) {
        for (const codec of RECORDING_CODECS) {
            if (failedRecordingCodecs.has(codec)) continue;
            const config = { codec, width, height, framerate, bitrate, latencyMode: "quality" };
            if (codec.startsWith("avc1")) config.avc = { format: "avc" };
            try {
                const support = await VideoEncoder.isConfigSupported(config);
                if (support.supported) return config;
            } catch (e) {
                // Unsupported codec strings can throw rather than report false.
            }
        }
        return null;
    }

    // One MP4 file being written:
    //   file        see openRecordingFile
    //   encoder     null until a codec has been picked, which is async
    //   pending     encoded frames waiting for the next key frame, which is
    //               where a fragment ends
    function recordingVideoFile(owner, kind, width, height, framerate, bitrate) {
        const video = {
            owner,
            file: openRecordingFile(owner, kind, "mp4"),
            width,
            height,
            framerate,
            codec: null,
            description: null,
            encoder: null,
            failed: false,
            closed: false,
            startNow: null,
            lastTimestamp: -1,
            lastKeyFrameNow: null,
            wroteInit: false,
            pending: [],
            sequenceNumber: 1,
            endTime: 0,
            frames: 0,
        };
        pickRecordingCodec(width, height, framerate, bitrate).then(function (config) {
            if (video.closed) return;
            if (!config) {
                video.failed = true;
                fail("No video codec this browser can record with.");
                return;
            }
            video.codec = config.codec;
            video.encoder = new VideoEncoder({
                output: function (chunk, metadata) {
                    recordingVideoChunk(video, chunk, metadata);
                },
                error: function (e) {
                    console.error("recording encoder", config.codec, e);
                    failedRecordingCodecs.add(config.codec);
                    video.failed = true;
                },
            });
            video.encoder.configure(config);
        });
        return video;
    }

    function recordingVideoFrame(video, frame, now) {
        if (video.owner.clockOffset === null) return;
        if (!video.encoder || video.failed || video.closed || video.encoder.state !== "configured") return;
        // Recording is meant to be the best copy, but a software encoder that
        // can't keep up only builds a backlog, so frames are dropped instead.
        if (video.encoder.encodeQueueSize > 4) return;
        if (video.startNow === null) video.startNow = now;
        const timestamp = Math.max(video.lastTimestamp + 1, Math.round((now - video.startNow) * 1000));
        const keyFrame =
            video.lastKeyFrameNow === null || now - video.lastKeyFrameNow >= RECORDING_KEY_FRAME_INTERVAL_MS;
        if (keyFrame) video.lastKeyFrameNow = now;
        video.lastTimestamp = timestamp;
        const copy = new VideoFrame(frame, { timestamp });
        video.encoder.encode(copy, { keyFrame });
        copy.close();
    }

    function recordingVideoChunk(video, chunk, metadata) {
        if (metadata && metadata.decoderConfig && metadata.decoderConfig.description) {
            const description = metadata.decoderConfig.description;
            video.description = new Uint8Array(
                ArrayBuffer.isView(description) ? description.buffer.slice(description.byteOffset, description.byteOffset + description.byteLength) : description.slice(0)
            );
        }
        const time = Math.round((chunk.timestamp * RECORDING_TIMESCALE) / 1e6);
        const key = chunk.type === "key";
        const data = new Uint8Array(chunk.byteLength);
        chunk.copyTo(data);
        if (!video.wroteInit) {
            if (!key) return;
            if (video.codec.startsWith("avc1")) {
                // Firefox's description has the wrong lengths in it, which
                // leaves players unable to find the SPS. It does repeat the SPS
                // and PPS in front of every key frame, so those are used when
                // they're there.
                video.description = avcDecoderConfigFromKeyFrame(data) || video.description;
                if (!video.description) return;
            }
            ensureRecordingFileOpen(video.file, performance.timeOrigin + video.startNow);
            appendToRecordingFile(video.file, mp4InitSegment(video.codec, video.width, video.height, video.description));
            video.wroteInit = true;
        }
        if (key && video.pending.length > 0) writeRecordingFragment(video, time);
        video.pending.push({ data, time, key });
        video.frames += 1;
    }

    function writeRecordingFragment(video, endTime) {
        const samples = video.pending;
        video.pending = [];
        samples.forEach(function (sample, index) {
            const next = index + 1 < samples.length ? samples[index + 1].time : endTime;
            sample.duration = Math.max(1, next - sample.time);
        });
        appendToRecordingFile(video.file, mp4Fragment(video.sequenceNumber, samples));
        video.endTime = endTime;
        video.sequenceNumber += 1;
        postToRecordingWorker({ type: "flush", file: video.file.handle });
    }

    async function closeRecordingVideoFile(video) {
        if (video.closed) return;
        video.closed = true;
        if (video.encoder && video.encoder.state === "configured") {
            try {
                await video.encoder.flush();
            } catch (e) {
                // Whatever was encoded before it failed is still worth keeping.
            }
        }
        if (video.encoder && video.encoder.state !== "closed") video.encoder.close();
        if (video.pending.length > 0) {
            const last = video.pending[video.pending.length - 1];
            writeRecordingFragment(video, last.time + Math.round(RECORDING_TIMESCALE / video.framerate));
        }
        if (video.startNow !== null) {
            finishRecordingFile(
                video.file,
                performance.timeOrigin + video.startNow + (video.endTime * 1000) / RECORDING_TIMESCALE
            );
        }
    }

    function recordingBitrate(width, height, framerate, bitsPerPixel) {
        return Math.round(Math.min(12_000_000, Math.max(2_000_000, width * height * framerate * bitsPerPixel)));
    }

    function recordCameraFrame(frame, now) {
        if (!recorder) return;
        const width = frame.displayWidth;
        const height = frame.displayHeight;
        let video = recorder.camera;
        if (video && (video.failed || video.width !== width || video.height !== height)) {
            closeRecordingVideoFile(video);
            video = null;
        }
        if (!video) {
            video = recordingVideoFile(recorder, "VIDEO", width, height, 30, recordingBitrate(width, height, 30, 0.12));
            recorder.camera = video;
        }
        recordingVideoFrame(video, frame, now);
    }

    function recordCameraOff() {
        if (!recorder || !recorder.camera) return;
        closeRecordingVideoFile(recorder.camera);
        recorder.camera = null;
    }

    function recordScreenFrame(frame, now) {
        if (!recorder) return;
        const width = frame.displayWidth;
        const height = frame.displayHeight;
        let video = recorder.screen;
        if (video && (video.failed || video.width !== width || video.height !== height)) {
            closeRecordingVideoFile(video);
            video = null;
        }
        if (!video) {
            video = recordingVideoFile(
                recorder,
                "SCREEN",
                width,
                height,
                SCREEN_FRAME_RATE,
                recordingBitrate(width, height, SCREEN_FRAME_RATE, 0.15)
            );
            recorder.screen = video;
        }
        recordingVideoFrame(video, frame, now);
    }

    function recordScreenStopped() {
        if (!recorder || !recorder.screen) return;
        closeRecordingVideoFile(recorder.screen);
        recorder.screen = null;
    }

    // The header's sizes are rewritten every few seconds, so a file cut short
    // by a crash is at most that much shorter than what's actually in it.
    const WAV_HEADER_INTERVAL_MS = 5000;

    function recordAudio(samples) {
        if (!recorder || recorder.clockOffset === null) return;
        let audio = recorder.audio;
        if (!audio) {
            // The block arriving now is the last 20ms of sound.
            const startLocal = Date.now() - (samples.length / AUDIO_SAMPLE_RATE) * 1000;
            audio = { file: openRecordingFile(recorder, "AUDIO", "wav"), startLocal, dataBytes: 0, lastHeaderTime: performance.now() };
            ensureRecordingFileOpen(audio.file, startLocal);
            appendToRecordingFile(audio.file, wavHeader(AUDIO_SAMPLE_RATE, 0));
            recorder.audio = audio;
        }
        const bytes = pcm16(samples);
        audio.dataBytes += bytes.byteLength;
        appendToRecordingFile(audio.file, bytes);
        const now = performance.now();
        if (now - audio.lastHeaderTime >= WAV_HEADER_INTERVAL_MS) {
            audio.lastHeaderTime = now;
            writeWavHeader(audio);
            postToRecordingWorker({ type: "flush", file: audio.file.handle });
        }
    }

    function writeWavHeader(audio) {
        postToRecordingWorker({ type: "write-at", file: audio.file.handle, at: 0, bytes: wavHeader(AUDIO_SAMPLE_RATE, audio.dataBytes) });
    }

    function recordAudioOff() {
        if (!recorder || !recorder.audio) return;
        closeRecordingAudioFile(recorder.audio);
        recorder.audio = null;
    }

    function closeRecordingAudioFile(audio) {
        writeWavHeader(audio);
        finishRecordingFile(audio.file, audio.startLocal + (audio.dataBytes / (AUDIO_SAMPLE_RATE * 2)) * 1000);
    }

    // --- debug data ---
    //
    // Everything the call is built out of, flattened into labelled strings for
    // the panel Elm draws. Nothing here is read back by the app, so it is only
    // ever as detailed as it takes to explain what a call is doing; a field
    // added below needs no matching change on the Elm side.
    const SOCKET_STATES = ["connecting", "open", "closing", "closed"];

    function row(label, value) {
        return { label: label, value: String(value) };
    }

    function codecName(index) {
        if (index === null || index === undefined) return "none";
        return CODECS[index] || "unknown (" + index + ")";
    }

    function encoderRow(label, encoder) {
        if (!encoder) return row(label, "none");
        return row(label, encoder.state + " queue=" + encoder.encodeQueueSize);
    }

    function decoderRow(label, decoder) {
        if (!decoder) return row(label, "none");
        return row(label, decoder.state + " queue=" + decoder.decodeQueueSize);
    }

    function audioContextValue(audioContext) {
        if (!audioContext) return "none";
        return (
            audioContext.state +
            " " + audioContext.sampleRate + "Hz" +
            " clock=" + audioContext.currentTime.toFixed(2) + "s"
        );
    }

    function trackRow(track, index) {
        const settings = typeof track.getSettings === "function" ? track.getSettings() : {};
        return row(
            track.kind + " track " + index,
            (track.label || "(unnamed)") +
                " enabled=" + track.enabled +
                " muted=" + track.muted +
                " " + track.readyState +
                (settings.width ? " " + settings.width + "x" + settings.height : "") +
                (settings.frameRate ? " " + Math.round(settings.frameRate) + "fps" : "") +
                (settings.sampleRate ? " " + settings.sampleRate + "Hz" : "")
        );
    }

    function streamSection(title, stream) {
        if (!stream) return { title: title, rows: [row("stream", "none")] };
        const tracks = stream.getTracks();
        if (tracks.length === 0) return { title: title, rows: [row("tracks", "none")] };
        return { title: title, rows: tracks.map(trackRow) };
    }

    function outgoingSection(title, outgoing) {
        if (!outgoing) return { title: title, rows: [row("encoding", false)] };
        return {
            title: title,
            rows: [
                row("codec", codecName(outgoing.codec)),
                row("force key frame", outgoing.forceKeyFrame),
                encoderRow("encoder", outgoing.encoder),
                row("encoder size", outgoing.size ? outgoing.size.width + "x" + outgoing.size.height : "none"),
                row("clock start", outgoing.startTime === null ? "no frames yet" : outgoing.startTime.toFixed(0) + "ms"),
            ],
        };
    }

    function canvasValue(canvas) {
        if (!canvas) return "not found yet";
        return canvas.width + "x" + canvas.height + " inDocument=" + canvas.isConnected;
    }

    function debugSections() {
        const sections = [
            {
                title: "Browser",
                rows: [
                    row("VideoEncoder", typeof VideoEncoder !== "undefined"),
                    row("AudioEncoder", typeof AudioEncoder !== "undefined"),
                    row(
                        "requestVideoFrameCallback",
                        typeof HTMLVideoElement !== "undefined" &&
                            typeof HTMLVideoElement.prototype.requestVideoFrameCallback === "function"
                    ),
                ],
            },
        ];

        if (!call) {
            sections.push({ title: "Call", rows: [row("in a call", false)] });
        } else {
            const state = call;
            sections.push({
                title: "Call",
                rows: [
                    row("in a call", true),
                    row("roomId", state.roomId),
                    row("selfId", state.selfId),
                    row("stopped", state.stopped),
                    row(
                        "socket",
                        state.socket
                            ? SOCKET_STATES[state.socket.readyState] + " buffered=" + state.socket.bufferedAmount
                            : "none"
                    ),
                    row("peers", state.peers.size),
                    row("video input enabled", state.videoInputEnabled),
                    encoderRow("audio encoder", state.audioEncoder),
                    row("audio frames captured", state.framesCaptured),
                    row("audio nodes", state.audioNodes.length),
                    row("audio context", audioContextValue(state.audioContext)),
                    row(
                        "capture video",
                        state.captureVideo.videoWidth + "x" + state.captureVideo.videoHeight +
                            " readyState=" + state.captureVideo.readyState +
                            " paused=" + state.captureVideo.paused
                    ),
                    row("preview shares call stream", localStreamPreview === state.stream),
                ],
            });

            sections.push(outgoingSection("Camera", state.camera));
            sections.push(streamSection("Call stream", state.stream));
            if (state.screen) {
                sections.push(outgoingSection("Screen share", state.screen.outgoing));
                sections.push({
                    title: "Screen share capture",
                    rows: [
                        row("frames from the browser", state.screen.browserFrames),
                        row(
                            "last one",
                            ((performance.now() - state.screen.lastBrowserFrameTime) / 1000).toFixed(1) + "s ago"
                        ),
                        row("track events", state.screen.trackEvents.join(", ") || "none"),
                        row("now", (performance.now() / 1000).toFixed(1) + "s"),
                        row(
                            "capture video",
                            state.screen.captureVideo.videoWidth + "x" + state.screen.captureVideo.videoHeight +
                                " readyState=" + state.screen.captureVideo.readyState +
                                " paused=" + state.screen.captureVideo.paused +
                                " ended=" + state.screen.captureVideo.ended
                        ),
                    ],
                });
                sections.push(streamSection("Screen share stream", state.screen.stream));
            } else {
                sections.push({
                    title: "Screen share",
                    rows: [row("sharing", false), row("picker open", state.screenRequested)],
                });
            }

            state.peers.forEach(function (peer, senderKey) {
                sections.push({
                    title: "Peer " + senderKey,
                    rows: [
                        row("video codec", codecName(peer.camera.codec)),
                        decoderRow("video decoder", peer.camera.decoder),
                        row("seen a key frame", peer.camera.ready),
                        row("canvas", canvasValue(peer.camera.canvas)),
                        row("screen codec", codecName(peer.screen.codec)),
                        decoderRow("screen decoder", peer.screen.decoder),
                        row("screen seen a key frame", peer.screen.ready),
                        row("screen canvas", canvasValue(peer.screen.canvas)),
                        decoderRow("audio decoder", peer.audioDecoder),
                        row("volume", peer.gain.gain.value),
                        row(
                            "audio queued",
                            Math.max(0, peer.playheadSeconds - state.audioContext.currentTime).toFixed(2) + "s"
                        ),
                        row("speaking", peer.isSpeaking),
                    ],
                });
            });
        }

        sections.push(streamSection("Preview stream", localStreamPreview));

        sections.push({
            title: "Recording",
            rows: recorder
                ? [
                      row("recording", recorder.id),
                      row("camera codec", recorder.camera ? recorder.camera.codec + " " + recorder.camera.frames + " frames" : "none"),
                      row("screen codec", recorder.screen ? recorder.screen.codec + " " + recorder.screen.frames + " frames" : "none"),
                  ].concat(
                      recorder.files.map(function (file) {
                          return row(file.name || file.kind + " (not started)", (file.bytes / 1e6).toFixed(1) + " MB");
                      })
                  )
                : [row("recording", false)],
        });

        sections.push({
            title: "Local mic level",
            rows: localSpeaking
                ? [
                      row("speaking", localSpeaking.isSpeaking),
                      row("audio context", audioContextValue(localSpeaking.audioContext)),
                  ]
                : [row("measuring", false)],
        });

        return sections;
    }

    // Files a recording was still writing when the page last closed are cut
    // back to what was completely written and marked as finished.
    if (navigator.storage && navigator.storage.getDirectory && navigator.locks) {
        navigator.storage
            .getDirectory()
            .then(function (root) {
                return root.getDirectoryHandle("recordings");
            })
            .then(function () {
                postToRecordingWorker({ type: "recover" });
            })
            .catch(function () {
                // Nothing has been recorded on this device.
            });
    }

    app.ports.voice_chat_to_js.subscribe(async function (msg) {
        if (msg.tag === "start-call") {
            await startCall(msg.args[0]);
        } else if (msg.tag === "leave-call") {
            await stopCall();
        } else if (msg.tag === "peer-joined") {
            // Their decoder has nothing to show until a key frame reaches it.
            // Building their side of the connection waits for their first chunk,
            // which is the only moment we know what codec they are sending.
            if (call && call.camera) call.camera.forceKeyFrame = true;
            if (call && call.screen) call.screen.outgoing.forceKeyFrame = true;
        } else if (msg.tag === "peer-left") {
            peerLeft(msg.args[0]);
        } else if (msg.tag === "set-audio-input-enabled") {
            setAudioInputEnabled(msg.args[0]);
        } else if (msg.tag === "set-input") {
            await setInput(msg.args[0], msg.args[1]);
        } else if (msg.tag === "set-video-input-enabled") {
            setVideoInputEnabled(msg.args[0]);
        } else if (msg.tag === "set-peer-video-input-enabled") {
            // Nothing arrives from a peer whose camera is off, so without this
            // their canvas would keep showing the last frame that did. Their
            // first frame back is a key frame, so nothing has to be restored
            // when it comes on again.
            if (!msg.args[1] && call) {
                const senderKey = msg.args[0].otherClientId;
                const peer = call.peers.get(senderKey);
                clearCanvas(
                    (peer && peer.camera.canvas) || document.getElementById(peerNodeId(call.roomId, senderKey))
                );
            }
        } else if (msg.tag === "start-screen-share") {
            await startScreenShare();
        } else if (msg.tag === "stop-screen-share") {
            if (call) stopScreenShare(call);
        } else if (msg.tag === "set-volume") {
            const peer = call && call.peers.get(msg.args[0].otherClientId);
            if (peer) peer.gain.gain.value = msg.args[1];
        } else if (msg.tag === "get-media-devices") {
            try {
                const stream = await getDevices();
                const devices = await navigator.mediaDevices.enumerateDevices();
                const defaultDevices = [];
                stream.getTracks().forEach((track) => {
                    defaultDevices.push(track.getSettings().deviceId);
                    track.stop();
                });
                app.ports.voice_chat_from_js.send({ tag: "got-media-devices", args: [devices, defaultDevices] });
            } catch (e) {
                app.ports.voice_chat_from_js.send({ tag: "got-media-devices-error", args: [e.toString()] });
            }
        } else if (msg.tag === "start-local-stream") {
            await startLocalStream(msg.args[0]);
        } else if (msg.tag === "stop-local-stream") {
            await stopLocalStream();
        } else if (msg.tag === "start-recording") {
            startRecording(msg.args[0]);
        } else if (msg.tag === "stop-recording") {
            stopRecording();
        } else if (msg.tag === "debug-data-request") {
            app.ports.voice_chat_from_js.send({ tag: "debug-data", args: [debugSections()] });
        }
    });

    // --- who is speaking ---
    //
    // One rule, applied to our own mic and to every peer: loud enough, recently
    // enough. Peers are measured from their decoded samples in playAudio; our
    // own mic never leaves the browser as encoded audio, so it is measured here
    // off an AnalyserNode instead.
    //
    // Original technique: https://www.linkedin.com/pulse/webrtc-active-speaker-detection-nilesh-gawande
    const AUDIO_WINDOW_SIZE = 256;

    let localSpeaking = null;

    // `entry` is anything carrying `speaker`, `isSpeaking` and
    // `speakingTimeout`: who this loudness belongs to, as the
    // Call.LocalOrConnection Elm expects, and what Elm was last told about them.
    function updateSpeaking(entry, loudness) {
        clearTimeout(entry.speakingTimeout);

        const isSpeaking = loudness > SPEAKING_THRESHOLD;
        if (isSpeaking) {
            // Silence is also nothing arriving at all, which no measurement will
            // ever report, so falling quiet is driven by this timer.
            entry.speakingTimeout = setTimeout(function () {
                updateSpeaking(entry, 0);
            }, SPEAKING_TIMEOUT_MS);
        }

        if (isSpeaking === entry.isSpeaking) return;
        entry.isSpeaking = isSpeaking;
        app.ports.voice_chat_from_js.send({
            tag: "is-speaking-changed",
            args: [entry.speaker, isSpeaking],
        });
    }

    function meanAmplitude(samples) {
        let total = 0;
        for (let i = 0; i < samples.length; i++) {
            total += Math.abs(samples[i]);
        }
        return samples.length === 0 ? 0 : total / samples.length;
    }

    function startLocalSpeaking(stream) {
        stopLocalSpeaking();
        if (stream.getAudioTracks().length === 0) return;

        const audioContext = new AudioContext();
        const source = audioContext.createMediaStreamSource(stream);
        const analyser = audioContext.createAnalyser();
        analyser.fftSize = AUDIO_WINDOW_SIZE;
        source.connect(analyser);

        // The time domain rather than the frequency spectrum, so these samples
        // are on the same -1..1 scale as a peer's decoded audio and can be
        // judged by the same threshold. Reading the spectrum is what left the
        // two sides with thresholds that could not be compared to each other.
        const samples = new Float32Array(analyser.fftSize);
        const entry = {
            audioContext,
            source,
            analyser,
            stopped: false,
            speaker: { tag: "local-video", args: [] },
            isSpeaking: false,
            speakingTimeout: null,
        };
        localSpeaking = entry;

        function measure() {
            if (entry.stopped) return;
            analyser.getFloatTimeDomainData(samples);
            updateSpeaking(entry, meanAmplitude(samples));
            requestAnimationFrame(measure);
        }

        measure();
    }

    function stopLocalSpeaking() {
        const entry = localSpeaking;
        localSpeaking = null;
        if (!entry) return;

        entry.stopped = true;
        updateSpeaking(entry, 0);
        try { entry.source.disconnect(); } catch (e) {}
        try { entry.analyser.disconnect(); } catch (e) {}
        try { entry.audioContext.close(); } catch (e) {}
    }
};
