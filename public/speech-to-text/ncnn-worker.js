// sherpa-ncnn, off the main thread.
//
// Serves the two ncnn models in models/: the recogniser is the same WebAssembly
// binary either way, and only the model bundled beside it differs. Which one to
// load comes in on the worker's own query string.
//
// ncnn-recognizer.js loads that binary directly, so the only JavaScript in here
// is the two files this worker imports.
//
// Messages in:  {type: "audio", samples: Float32Array} | {type: "flush"}
// Messages out: {type: "ready"} | {type: "partial", text} | {type: "final", text} | {type: "error", message}

importScripts("/speech-to-text/downsample.js", "/speech-to-text/ncnn-recognizer.js");

const modelDirectory = "/speech-to-text/models/" + new URLSearchParams(self.location.search).get("model") + "/";

// sherpa-ncnn decides where an utterance ends from trailing silence. These are
// its defaults, kept explicit because they are the knobs worth turning if
// transcripts arrive in the wrong sized pieces.
const RECOGNIZER_CONFIG = {
    samplingRate: MODEL_SAMPLE_RATE,
    featureDim: 80,
    encoderParam: "./encoder_jit_trace-pnnx.ncnn.param",
    encoderBin: "./encoder_jit_trace-pnnx.ncnn.bin",
    decoderParam: "./decoder_jit_trace-pnnx.ncnn.param",
    decoderBin: "./decoder_jit_trace-pnnx.ncnn.bin",
    joinerParam: "./joiner_jit_trace-pnnx.ncnn.param",
    joinerBin: "./joiner_jit_trace-pnnx.ncnn.bin",
    tokens: "./tokens.txt",
    numThreads: 1,
    decodingMethod: "greedy_search",
    numActivePaths: 4,
    rule1MinTrailingSilence: 1.2,
    rule2MinTrailingSilence: 2.4,
    rule3MinUtteranceLength: 20,
};

let recognizer = null;
let downsampler = null;
let lastPartial = "";

self.onmessage = function (event) {
    const message = event.data;
    if (!recognizer) return;

    if (message.type === "audio") {
        recognizer.acceptWaveform(MODEL_SAMPLE_RATE, downsampler.process(message.samples));
        recognizer.decodeAvailable();

        const text = recognizer.text().trim();
        if (recognizer.isEndpoint()) {
            if (text.length > 0) self.postMessage({ type: "final", text: text });
            recognizer.reset();
            lastPartial = "";
        } else if (text !== lastPartial) {
            lastPartial = text;
            self.postMessage({ type: "partial", text: text });
        }
        return;
    }

    if (message.type === "flush") {
        // A transducer only commits a word once it has seen a little of what
        // comes after it, so the last word of a call needs silence to land.
        recognizer.acceptWaveform(MODEL_SAMPLE_RATE, new Float32Array(MODEL_SAMPLE_RATE));
        recognizer.decodeAvailable();

        const text = recognizer.text().trim();
        if (text.length > 0) self.postMessage({ type: "final", text: text });
        recognizer.reset();
        lastPartial = "";
        downsampler = new Downsampler();
    }
};

createNcnnRecognizer(modelDirectory, RECOGNIZER_CONFIG).then(function (created) {
    recognizer = created;
    downsampler = new Downsampler();
    self.postMessage({ type: "ready" });
}, function (e) {
    self.postMessage({ type: "error", message: "could not load the model; run scripts/fetch-speech-to-text-models.py (" + e + ")" });
});
