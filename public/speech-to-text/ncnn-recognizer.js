// sherpa-ncnn, loaded without the emscripten glue.
//
// The build published upstream ships a 77KB generated JavaScript loader beside
// the 1.7MB .wasm. That loader is minified, unreadable and carries a filesystem
// stack, an XHR downloader and a POSIX shim, for a program that only ever opens
// seven files read-only. This file replaces it, because the loader is the half
// of the pair that can be read.
//
// What the recogniser is allowed to do is exactly the import list below, and
// there is nothing in it that reaches the network, the DOM or the page. Whatever
// the .wasm turns out to contain, it can open the files handed to it here, write
// to stdout, and compute. That is the whole boundary, and it is fifteen
// functions long.
//
// The names are single letters because the upstream build is minified. They are
// checked at load rather than trusted, so a build whose exports have shifted
// fails here with a clear message instead of computing something wrong. Which
// build that is stays pinned by revision and sha256 in
// scripts/fetch-speech-to-text-models.py.

const NCNN_EXPORTS = {
    memory: "p",
    callConstructors: "q",
    createRecognizer: "s",
    destroyRecognizer: "t",
    createStream: "u",
    destroyStream: "v",
    acceptWaveform: "w",
    isReady: "x",
    decode: "y",
    getResult: "z",
    destroyResult: "A",
    reset: "B",
    isEndpoint: "D",
    malloc: "F",
    free: "G",
};

// musl's ENOENT, which is what the upstream loader returns for a missing file.
const ENOENT = 2;

const SEEK_SET = 0;
const SEEK_CUR = 1;
const SEEK_END = 2;

// A read-only filesystem over the .data blob, which is a plain concatenation of
// the model files; files.json says which bytes are which. File contents stay in
// JavaScript memory and are copied into the module only as it reads them, so the
// 53MB model does not have to fit in the module's own heap.
class ModelFiles {
    constructor(manifest, data) {
        this.contents = new Map();
        manifest.files.forEach((entry) => {
            this.contents.set(entry.filename, data.subarray(entry.start, entry.end));
        });
        this.open = new Map();
        this.nextDescriptor = 3;
    }

    // "./tokens.txt" and "/tokens.txt" are the same file: the recogniser is
    // configured with the former and the package records the latter.
    lookup(path) {
        return this.contents.get("/" + path.replace(/^\.?\//, ""));
    }
}

function decodeCString(memory, pointer) {
    const bytes = new Uint8Array(memory.buffer);
    let end = pointer;
    while (bytes[end] !== 0) end++;
    return new TextDecoder().decode(bytes.subarray(pointer, end));
}

function makeImports(state) {
    // Written into by fd_write and flushed a line at a time: the recogniser
    // prints what it loaded, which is worth keeping visible.
    let pending = "";

    function scatter(iov, count, apply) {
        const view = new DataView(state.memory.buffer);
        let total = 0;
        for (let i = 0; i < count; i++) {
            const pointer = view.getUint32(iov + i * 8, true);
            const length = view.getUint32(iov + i * 8 + 4, true);
            total += apply(pointer, length);
        }
        return total;
    }

    return {
        // __cxa_throw. This build imports no matching catch, so a C++ throw is
        // fatal either way; surfacing it as a JavaScript error at least says so.
        a: function (pointer) {
            throw new Error("sherpa-ncnn threw a C++ exception at " + pointer);
        },

        // exit
        b: function (status) {
            throw new Error("sherpa-ncnn called exit(" + status + ")");
        },

        // abort
        c: function () {
            throw new Error("sherpa-ncnn aborted");
        },

        // fd_write, which only ever gets stdout and stderr here.
        d: function (fd, iov, count, written) {
            const bytes = new Uint8Array(state.memory.buffer);
            const total = scatter(iov, count, function (pointer, length) {
                pending += new TextDecoder().decode(bytes.subarray(pointer, pointer + length));
                return length;
            });

            const lines = pending.split("\n");
            pending = lines.pop();
            lines.forEach(function (line) { if (line) console.log("sherpa-ncnn: " + line); });

            new DataView(state.memory.buffer).setUint32(written, total, true);
            return 0;
        },

        // fd_close
        e: function (fd) {
            state.files.open.delete(fd);
            return 0;
        },

        // __syscall_fcntl64, which nothing here depends on.
        f: function () {
            return 0;
        },

        // __syscall_openat
        g: function (directory, path) {
            const content = state.files.lookup(decodeCString(state.memory, path));
            if (!content) return -ENOENT;

            const descriptor = state.files.nextDescriptor++;
            state.files.open.set(descriptor, { content: content, position: 0 });
            return descriptor;
        },

        // strftime_l. Nothing on the recognition path formats a date, so this
        // reports having written no bytes rather than pulling in a date library.
        h: function () {
            return 0;
        },

        // environ_get
        i: function () {
            return 0;
        },

        // environ_sizes_get, answering with an empty environment.
        j: function (count, size) {
            const view = new DataView(state.memory.buffer);
            view.setUint32(count, 0, true);
            view.setUint32(size, 0, true);
            return 0;
        },

        // emscripten_resize_heap. The upstream loader aborts here too: this
        // build's memory does not grow.
        k: function (requested) {
            throw new Error("sherpa-ncnn ran out of memory (wanted " + requested + " bytes)");
        },

        // fd_seek, whose offset arrives as a pair of 32-bit halves.
        l: function (fd, offsetLow, offsetHigh, whence, result) {
            const file = state.files.open.get(fd);
            if (!file) return ENOENT;

            const offset = offsetHigh * 4294967296 + (offsetLow >>> 0);
            if (whence === SEEK_SET) file.position = offset;
            else if (whence === SEEK_CUR) file.position += offset;
            else if (whence === SEEK_END) file.position = file.content.length + offset;

            const view = new DataView(state.memory.buffer);
            view.setUint32(result, file.position >>> 0, true);
            view.setUint32(result + 4, Math.floor(file.position / 4294967296), true);
            return 0;
        },

        // fd_read
        m: function (fd, iov, count, read) {
            const file = state.files.open.get(fd);
            if (!file) return ENOENT;

            const bytes = new Uint8Array(state.memory.buffer);
            const total = scatter(iov, count, function (pointer, length) {
                const take = Math.min(length, file.content.length - file.position);
                bytes.set(file.content.subarray(file.position, file.position + take), pointer);
                file.position += take;
                return take;
            });

            new DataView(state.memory.buffer).setUint32(read, total, true);
            return 0;
        },

        // __syscall_ioctl, asked only about terminals that do not exist here.
        n: function () {
            return 0;
        },

        // emscripten_memcpy_js
        o: function (destination, source, length) {
            new Uint8Array(state.memory.buffer).copyWithin(destination, source, source + length);
        },
    };
}

// The recogniser's configuration is one flat struct of 32-bit fields. Laying it
// out by hand is what the upstream wrapper does too, and these are its offsets.
const CONFIG_BYTES = 76;

function writeConfig(state, config) {
    const encoded = [
        config.encoderParam, config.encoderBin,
        config.decoderParam, config.decoderBin,
        config.joinerParam, config.joinerBin,
        config.tokens, config.decodingMethod,
    ].map(function (value) { return new TextEncoder().encode(value + "\0"); });

    const text = state.exports.malloc(encoded.reduce(function (sum, b) { return sum + b.length; }, 0));
    const bytes = new Uint8Array(state.memory.buffer);
    const pointers = [];
    let offset = 0;
    encoded.forEach(function (value) {
        bytes.set(value, text + offset);
        pointers.push(text + offset);
        offset += value.length;
    });

    const struct = state.exports.malloc(CONFIG_BYTES);
    const view = new DataView(state.memory.buffer);
    view.setFloat32(struct, config.samplingRate, true);
    view.setInt32(struct + 4, config.featureDim, true);
    for (let i = 0; i < 7; i++) view.setUint32(struct + 8 + i * 4, pointers[i], true);  // the model paths
    view.setInt32(struct + 36, 0, true);                                               // useVulkanCompute
    view.setInt32(struct + 40, config.numThreads, true);
    view.setUint32(struct + 44, pointers[7], true);                                    // decodingMethod
    view.setInt32(struct + 48, config.numActivePaths, true);
    view.setInt32(struct + 52, 1, true);                                               // enableEndpoint
    view.setFloat32(struct + 56, config.rule1MinTrailingSilence, true);
    view.setFloat32(struct + 60, config.rule2MinTrailingSilence, true);
    view.setFloat32(struct + 64, config.rule3MinUtteranceLength, true);
    view.setUint32(struct + 68, 0, true);                                              // hotwords file
    view.setFloat32(struct + 72, 0.5, true);                                           // hotwords score

    return { struct: struct, text: text };
}

async function createNcnnRecognizer(directory, config) {
    const [manifest, data, wasm] = await Promise.all([
        fetch(directory + "files.json").then(function (r) { return r.json(); }),
        fetch(directory + "sherpa-ncnn-wasm-main.data").then(function (r) { return r.arrayBuffer(); }),
        fetch(directory + "sherpa-ncnn-wasm-main.wasm").then(function (r) { return r.arrayBuffer(); }),
    ]);

    const state = { files: new ModelFiles(manifest, new Uint8Array(data)) };
    const instance = (await WebAssembly.instantiate(wasm, { a: makeImports(state) })).instance;

    state.exports = {};
    Object.keys(NCNN_EXPORTS).forEach(function (name) {
        const value = instance.exports[NCNN_EXPORTS[name]];
        if (!value) throw new Error("this sherpa-ncnn build does not export " + name);
        state.exports[name] = value;
    });
    state.memory = state.exports.memory;
    state.exports.callConstructors();

    const written = writeConfig(state, config);
    const recognizer = state.exports.createRecognizer(written.struct);
    state.exports.free(written.struct);
    state.exports.free(written.text);
    if (!recognizer) throw new Error("sherpa-ncnn could not load the model");

    const stream = state.exports.createStream(recognizer);
    const samples = { pointer: 0, capacity: 0 };

    return {
        acceptWaveform: function (sampleRate, block) {
            if (samples.capacity < block.length) {
                if (samples.pointer) state.exports.free(samples.pointer);
                samples.pointer = state.exports.malloc(block.length * 4);
                samples.capacity = block.length;
            }
            new Float32Array(state.memory.buffer, samples.pointer, block.length).set(block);
            state.exports.acceptWaveform(stream, sampleRate, samples.pointer, block.length);
        },

        decodeAvailable: function () {
            while (state.exports.isReady(recognizer, stream) === 1) state.exports.decode(recognizer, stream);
        },

        isEndpoint: function () {
            return state.exports.isEndpoint(recognizer, stream) === 1;
        },

        reset: function () {
            state.exports.reset(recognizer, stream);
        },

        // The result struct opens with a pointer to its own text.
        text: function () {
            const result = state.exports.getResult(recognizer, stream);
            const value = decodeCString(state.memory, new DataView(state.memory.buffer).getUint32(result, true));
            state.exports.destroyResult(result);
            return value;
        },

        free: function () {
            if (samples.pointer) state.exports.free(samples.pointer);
            state.exports.destroyStream(stream);
            state.exports.destroyRecognizer(recognizer);
        },
    };
}
