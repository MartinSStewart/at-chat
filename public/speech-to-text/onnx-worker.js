// sherpa-onnx, off the main thread.
//
// The same job ncnn-worker.js does, against the other recogniser. They are kept
// apart rather than folded together behind an engine flag: the two libraries
// have different setup, different result types and different failure modes, and
// a reader chasing a bad transcript should not have to work out which half of a
// shared function ran.
//
// This build is compiled with SIMD, which is most of why it decodes faster than
// the ncnn one despite running a model of similar size.
//
// Messages in:  {type: "audio", samples: Float32Array} | {type: "flush"}
// Messages out: {type: "ready"} | {type: "partial", text} | {type: "final", text} | {type: "error", message}

const modelDirectory = "/speech-to-text/models/" + new URLSearchParams(self.location.search).get("model") + "/";

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

        const text = recognizer.getResult(stream).text.trim();
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

        const text = recognizer.getResult(stream).text.trim();
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
            // createOnlineRecognizer's own defaults already name the files the
            // package is built with, and the streaming transducer is the model
            // type it defaults to.
            recognizer = createOnlineRecognizer(self.Module);
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
                  modelDirectory + "sherpa-onnx-asr.js",
                  modelDirectory + "sherpa-onnx-wasm-main-asr.js");
} catch (e) {
    self.postMessage({ type: "error", message: "could not load the model; run scripts/fetch-speech-to-text-models.py (" + e + ")" });
}
