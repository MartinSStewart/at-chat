// Speech recognition, off the main thread.
//
// Runs the prebuilt sherpa-ncnn WebAssembly recogniser (a streaming zipformer
// transducer, English only) fetched by scripts/fetch-speech-to-text-model.sh.
// Decoding costs roughly half of real time on one core, so it lives in a worker:
// on the main thread it would compete with the call's video encoding and show up
// as dropped frames.
//
// It is fed the same 48kHz blocks voice-chat.js hands to the audio encoder,
// which is the microphone's own output before opus has been anywhere near it.
// The recogniser wants 16kHz, so blocks are low-pass filtered and decimated here
// rather than by asking the AudioContext for 16kHz, which would degrade the
// audio everyone else hears.
//
// Messages in:  {type: "start"} | {type: "audio", samples: Float32Array} | {type: "flush"}
// Messages out: {type: "ready"} | {type: "partial", text} | {type: "final", text} | {type: "error", message}

const INPUT_SAMPLE_RATE = 48000;
const MODEL_SAMPLE_RATE = 16000;
const DECIMATION = INPUT_SAMPLE_RATE / MODEL_SAMPLE_RATE;

// Half-band-ish low pass ahead of the decimation. Without it every frequency
// above 8kHz folds back down into the speech band as noise the model has never
// heard in training, which costs more accuracy than the filter costs CPU.
const FILTER_CUTOFF_HZ = 7000;
const FILTER_TAPS = 47;

// Sent when the recogniser has decided an utterance ended. sherpa-ncnn decides
// this itself from trailing silence; these are its defaults, kept explicit
// because they are the knobs worth turning if transcripts arrive in the wrong
// sized pieces.
const RULE1_MIN_TRAILING_SILENCE = 1.2;
const RULE2_MIN_TRAILING_SILENCE = 2.4;
const RULE3_MIN_UTTERANCE_LENGTH = 20;

function lowPassCoefficients() {
    const coefficients = new Float32Array(FILTER_TAPS);
    const middle = (FILTER_TAPS - 1) / 2;
    const angular = 2 * Math.PI * (FILTER_CUTOFF_HZ / INPUT_SAMPLE_RATE);
    let total = 0;

    for (let i = 0; i < FILTER_TAPS; i++) {
        const offset = i - middle;
        const sinc = offset === 0 ? angular : Math.sin(angular * offset) / offset;
        // Hamming, which puts the first sidelobe far enough down that the fold
        // back is inaudible against a microphone's own noise floor.
        const window = 0.54 - 0.46 * Math.cos((2 * Math.PI * i) / (FILTER_TAPS - 1));
        coefficients[i] = sinc * window;
        total += coefficients[i];
    }

    for (let i = 0; i < FILTER_TAPS; i++) coefficients[i] /= total;
    return coefficients;
}

// Keeps the filter's tail between blocks. Dropping it would put a discontinuity
// at every 20ms boundary, which the model hears as a click every 20ms.
class Downsampler {
    constructor() {
        this.coefficients = lowPassCoefficients();
        // Input samples the filter has not finished with, carried into the next
        // block so output stays exactly one sample in three across boundaries.
        this.pending = new Float32Array(0);
    }

    process(input) {
        const buffer = new Float32Array(this.pending.length + input.length);
        buffer.set(this.pending, 0);
        buffer.set(input, this.pending.length);

        const count = Math.max(0, Math.ceil((buffer.length - FILTER_TAPS + 1) / DECIMATION));
        const output = new Float32Array(count);
        for (let i = 0; i < count; i++) {
            let sum = 0;
            for (let tap = 0; tap < FILTER_TAPS; tap++) sum += this.coefficients[tap] * buffer[i * DECIMATION + tap];
            output[i] = sum;
        }

        this.pending = buffer.slice(count * DECIMATION);
        return output;
    }
}


let recognizer = null;
let stream = null;
let downsampler = new Downsampler();
let lastPartial = "";

function decodeAvailable() {
    while (recognizer.isReady(stream)) recognizer.decode(stream);
}

function emit() {
    const text = recognizer.getResult(stream).trim();

    if (recognizer.isEndpoint(stream)) {
        if (text.length > 0) self.postMessage({ type: "final", text: text });
        recognizer.reset(stream);
        lastPartial = "";
        return;
    }

    if (text !== lastPartial) {
        lastPartial = text;
        self.postMessage({ type: "partial", text: text });
    }
}

self.onmessage = function (event) {
    const message = event.data;

    if (message.type === "audio") {
        if (!stream) return;
        stream.acceptWaveform(MODEL_SAMPLE_RATE, downsampler.process(message.samples));
        decodeAvailable();
        emit();
        return;
    }

    if (message.type === "flush") {
        if (!stream) return;
        // A transducer only commits a word once it has seen a little of what
        // comes after it, so the last word of a call needs silence to land.
        stream.acceptWaveform(MODEL_SAMPLE_RATE, new Float32Array(MODEL_SAMPLE_RATE));
        decodeAvailable();
        const text = recognizer.getResult(stream).trim();
        if (text.length > 0) self.postMessage({ type: "final", text: text });
        recognizer.reset(stream);
        lastPartial = "";
        downsampler = new Downsampler();
    }
};

self.Module = {
    locateFile: function (file) {
        return file;
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
            self.postMessage({ type: "ready" });
        } catch (e) {
            self.postMessage({ type: "error", message: "recogniser setup failed: " + e });
        }
    },
};

try {
    importScripts("sherpa-ncnn.js", "sherpa-ncnn-wasm-main.js");
} catch (e) {
    self.postMessage({ type: "error", message: "could not load the model; run scripts/fetch-speech-to-text-model.sh (" + e + ")" });
}
