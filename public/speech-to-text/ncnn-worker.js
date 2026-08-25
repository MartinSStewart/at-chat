// sherpa-ncnn, off the main thread.
//
// Serves the two ncnn models in models/: the recogniser is the same WebAssembly
// binary either way, and only the model bundled beside it differs. Which one to
// load comes in on the worker's own query string.
//
// Messages in:  {type: "audio", samples: Float32Array} | {type: "flush"}
// Messages out: {type: "ready"} | {type: "partial", text} | {type: "final", text} | {type: "error", message}

const modelDirectory = "/speech-to-text/models/" + new URLSearchParams(self.location.search).get("model") + "/";

// sherpa-ncnn decides where an utterance ends from trailing silence. These are
// its defaults, kept explicit because they are the knobs worth turning if
// transcripts arrive in the wrong sized pieces.
const RULE1_MIN_TRAILING_SILENCE = 1.2;
const RULE2_MIN_TRAILING_SILENCE = 2.4;
const RULE3_MIN_UTTERANCE_LENGTH = 20;

let recognizer = null;
let stream = null;
let downsampler = null;
let lastPartial = "";

self.onmessage = function (event) {
    const message = event.data;

    if (message.type === "audio") {
        if (!stream) return;
        stream.acceptWaveform(MODEL_SAMPLE_RATE, downsampler.process(message.samples));
        while (recognizer.isReady(stream)) recognizer.decode(stream);

        const text = recognizer.getResult(stream).trim();
        if (recognizer.isEndpoint(stream)) {
            if (text.length > 0) self.postMessage({ type: "final", text: text });
            recognizer.reset(stream);
            lastPartial = "";
        } else if (text !== lastPartial) {
            lastPartial = text;
            self.postMessage({ type: "partial", text: text });
        }
        return;
    }

    if (message.type === "flush") {
        if (!stream) return;
        // A transducer only commits a word once it has seen a little of what
        // comes after it, so the last word of a call needs silence to land.
        stream.acceptWaveform(MODEL_SAMPLE_RATE, new Float32Array(MODEL_SAMPLE_RATE));
        while (recognizer.isReady(stream)) recognizer.decode(stream);

        const text = recognizer.getResult(stream).trim();
        if (text.length > 0) self.postMessage({ type: "final", text: text });
        recognizer.reset(stream);
        lastPartial = "";
        downsampler = new Downsampler();
    }
};

self.Module = {
    locateFile: function (file) {
        return modelDirectory + file;
    },
    onRuntimeInitialized: function () {
        try {
            recognizer = createRecognizer(self.Module, {
                featConfig: { samplingRate: MODEL_SAMPLE_RATE, featureDim: 80 },
                modelConfig: {
                    encoderParam: "./encoder_jit_trace-pnnx.ncnn.param",
                    encoderBin: "./encoder_jit_trace-pnnx.ncnn.bin",
                    decoderParam: "./decoder_jit_trace-pnnx.ncnn.param",
                    decoderBin: "./decoder_jit_trace-pnnx.ncnn.bin",
                    joinerParam: "./joiner_jit_trace-pnnx.ncnn.param",
                    joinerBin: "./joiner_jit_trace-pnnx.ncnn.bin",
                    tokens: "./tokens.txt",
                    useVulkanCompute: 0,
                    numThreads: 1,
                },
                decoderConfig: { decodingMethod: "greedy_search", numActivePaths: 4 },
                enableEndpoint: 1,
                rule1MinTrailingSilence: RULE1_MIN_TRAILING_SILENCE,
                rule2MinTrailingSilence: RULE2_MIN_TRAILING_SILENCE,
                rule3MinUtternceLength: RULE3_MIN_UTTERANCE_LENGTH,
            });
            stream = recognizer.createStream();
            downsampler = new Downsampler();
            self.postMessage({ type: "ready" });
        } catch (e) {
            self.postMessage({ type: "error", message: "recogniser setup failed: " + e });
        }
    },
};

try {
    importScripts("/speech-to-text/downsample.js",
                  modelDirectory + "sherpa-ncnn.js",
                  modelDirectory + "sherpa-ncnn-wasm-main.js");
} catch (e) {
    self.postMessage({ type: "error", message: "could not load the model; run scripts/fetch-speech-to-text-models.py (" + e + ")" });
}
