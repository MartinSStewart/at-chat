// Main-thread half of the local speech recogniser. Owns one worker and nothing
// else, so the only thing a caller has to get right is handing it 48kHz mono
// blocks.
//
//     const stt = createSpeechToText({
//         model: "zipformer-20m-en",
//         onReady: function () { ... },
//         onPartial: function (text) { ... },   // the utterance so far, revised as it goes
//         onFinal: function (text) { ... },     // an utterance the recogniser has closed
//         onError: function (message) { ... },
//     });
//     stt.feed(float32BlockAt48kHz);
//     stt.flush();   // end of speech; emits the last utterance
//     stt.stop();
//
// In a call the blocks come straight off the capture worklet in voice-chat.js,
// which is the microphone before the opus encoder sees it. Nothing leaves the
// browser: the recogniser and the model are both local.

// Every model here streams, which is what keeps the delay between speaking and
// seeing text short. Whisper and Moonshine are deliberately absent: both decode
// a finished segment rather than a running one, so text can only appear once you
// stop talking, and both are larger than any of these once converted.
//
// `download` is what the browser fetches on first use and caches afterwards:
// the recogniser binary plus the model bundled with it.
const MODELS = {
    "zipformer-small-zh-en": {
        engine: "ncnn",
        label: "Zipformer small, English and Chinese",
        download: 55,
    },
    "zipformer-20m-en": {
        engine: "onnx",
        label: "Zipformer 20M, English (int8)",
        download: 58,
    },
    "zipformer-en": {
        engine: "ncnn",
        label: "Zipformer, English",
        download: 143,
    },
};

function createSpeechToText(handlers) {
    const model = MODELS[handlers.model];
    if (!model) throw new Error("unknown speech-to-text model: " + handlers.model);

    const worker = new Worker("/speech-to-text/" + model.engine + "-worker.js?model=" + handlers.model);
    let ready = false;

    worker.onmessage = function (event) {
        const message = event.data;
        if (message.type === "ready") {
            ready = true;
            if (handlers.onReady) handlers.onReady();
        } else if (message.type === "partial") {
            if (handlers.onPartial) handlers.onPartial(message.text);
        } else if (message.type === "final") {
            if (handlers.onFinal) handlers.onFinal(message.text);
        } else if (message.type === "error") {
            if (handlers.onError) handlers.onError(message.message);
        }
    };

    worker.onerror = function (event) {
        if (handlers.onError) handlers.onError(event.message || "speech-to-text worker failed");
    };

    return {
        // Audio recorded while the model is still loading is dropped rather than
        // queued: the first seconds of a call are worth less than the delay that
        // catching up on them would add to everything after.
        feed: function (samples) {
            if (!ready) return;
            const copy = new Float32Array(samples);
            worker.postMessage({ type: "audio", samples: copy }, [copy.buffer]);
        },

        flush: function () {
            if (ready) worker.postMessage({ type: "flush" });
        },

        stop: function () {
            ready = false;
            worker.terminate();
        },
    };
}
