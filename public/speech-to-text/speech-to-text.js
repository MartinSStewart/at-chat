// Main-thread half of the local speech recogniser. Owns the worker in
// stt-worker.js and nothing else, so the only thing a caller has to get right is
// handing it 48kHz mono blocks.
//
//     const stt = createSpeechToText({
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

function createSpeechToText(handlers) {
    const worker = new Worker("/speech-to-text/stt-worker.js");
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
