// Runs in every page before the app does (Playwright's addInitScript), so it can
// wrap the browser APIs voice-chat.js uses without the app knowing. Everything
// it learns goes into window.__stress, which run.js reads and resets.
//
// Nothing here changes what the app sends or receives: the room socket gets an
// extra "message" listener alongside the app's onmessage, and the decoders get
// their output and error callbacks wrapped.
//
// `config` comes from run.js: { fakeMedia, noVideo, toneHz, hue, label }.
(function (config) {
    const stress = {
        label: config.label,
        startedAt: performance.now(),
        // Per sender label ("<userId> <clientId>"): what arrived over the room socket.
        received: {},
        sent: { audio: 0, video: 0, bytes: 0, keyFrames: 0 },
        decoded: { audio: 0, video: 0, audioErrors: 0, videoErrors: 0 },
        maxQueue: { videoEncoder: 0, audioEncoder: 0, videoDecoder: 0, audioDecoder: 0 },
        socketMaxBuffered: 0,
        socketCloses: [],
        // The main thread's lag, sampled with a 100ms timer. A client whose own
        // main thread is pegged can't keep up whatever the server does, so this is
        // what tells "the container is overloaded" apart from "the relay dropped it".
        lagSamples: [],
        errors: [],
    };
    window.__stress = stress;

    stress.reset = function () {
        stress.startedAt = performance.now();
        stress.received = {};
        stress.sent = { audio: 0, video: 0, bytes: 0, keyFrames: 0 };
        stress.decoded = { audio: 0, video: 0, audioErrors: 0, videoErrors: 0 };
        stress.maxQueue = { videoEncoder: 0, audioEncoder: 0, videoDecoder: 0, audioDecoder: 0 };
        stress.socketMaxBuffered = 0;
        stress.lagSamples = [];
        stress.errors = [];
    };

    let lastTick = performance.now();
    setInterval(function () {
        const now = performance.now();
        stress.lagSamples.push(Math.max(0, now - lastTick - 100));
        lastTick = now;
    }, 100);

    window.addEventListener("error", function (e) {
        stress.errors.push(String(e.message));
    });

    // --- the room socket ---

    const textDecoder = new TextDecoder();

    // Same layout as voice-chat.js's packet(): sender length, sender, kind, key
    // frame flag. Only what's needed to tell the streams apart is read.
    function recordReceived(data) {
        if (!(data instanceof ArrayBuffer) || data.byteLength < 3) return;
        const view = new DataView(data);
        const senderLength = view.getUint8(0);
        if (data.byteLength < 1 + senderLength + 2) return;
        const sender = textDecoder.decode(new Uint8Array(data, 1, senderLength));
        const kind = view.getUint8(1 + senderLength) === 0 ? "video" : "audio";
        const keyFrame = view.getUint8(2 + senderLength) === 1;

        let entry = stress.received[sender];
        if (!entry) {
            entry = {
                audio: 0,
                video: 0,
                bytes: 0,
                keyFrames: 0,
                lastAudioAt: null,
                maxAudioGapMs: 0,
                audioGapsOver100ms: 0,
            };
            stress.received[sender] = entry;
        }
        entry[kind] += 1;
        entry.bytes += data.byteLength;
        if (keyFrame && kind === "video") entry.keyFrames += 1;
        if (kind === "audio") {
            const now = performance.now();
            if (entry.lastAudioAt !== null) {
                const gap = now - entry.lastAudioAt;
                if (gap > entry.maxAudioGapMs) entry.maxAudioGapMs = gap;
                if (gap > 100) entry.audioGapsOver100ms += 1;
            }
            entry.lastAudioAt = now;
        }
    }

    function recordSent(data) {
        const bytes = data instanceof ArrayBuffer ? new Uint8Array(data) : data;
        if (!(bytes instanceof Uint8Array) || bytes.byteLength < 3) return;
        const senderLength = bytes[0];
        const kind = bytes[1 + senderLength] === 0 ? "video" : "audio";
        stress.sent[kind] += 1;
        stress.sent.bytes += bytes.byteLength;
        if (kind === "video" && bytes[2 + senderLength] === 1) stress.sent.keyFrames += 1;
    }

    const OriginalWebSocket = window.WebSocket;
    window.WebSocket = function (url, protocols) {
        const socket = protocols === undefined ? new OriginalWebSocket(url) : new OriginalWebSocket(url, protocols);
        if (String(url).indexOf("/file/websocket/") !== -1) {
            stress.roomUrl = String(url);
            socket.addEventListener("message", function (event) {
                recordReceived(event.data);
            });
            socket.addEventListener("close", function (event) {
                stress.socketCloses.push(event.code);
            });
            const send = socket.send.bind(socket);
            socket.send = function (data) {
                recordSent(data);
                send(data);
                if (socket.bufferedAmount > stress.socketMaxBuffered) {
                    stress.socketMaxBuffered = socket.bufferedAmount;
                }
            };
        }
        return socket;
    };
    window.WebSocket.prototype = OriginalWebSocket.prototype;
    ["CONNECTING", "OPEN", "CLOSING", "CLOSED"].forEach(function (name) {
        window.WebSocket[name] = OriginalWebSocket[name];
    });

    // --- codecs ---

    function trackQueue(name, codec, sizeField) {
        const timer = setInterval(function () {
            if (codec.state === "closed") {
                clearInterval(timer);
                return;
            }
            if (codec[sizeField] > stress.maxQueue[name]) stress.maxQueue[name] = codec[sizeField];
        }, 200);
    }

    function wrapDecoder(globalName, kind, queueName) {
        const Original = window[globalName];
        if (typeof Original === "undefined") return;
        window[globalName] = class extends Original {
            constructor(init) {
                super({
                    output: function (output) {
                        stress.decoded[kind] += 1;
                        init.output(output);
                    },
                    error: function (e) {
                        stress.decoded[kind + "Errors"] += 1;
                        init.error(e);
                    },
                });
                trackQueue(queueName, this, "decodeQueueSize");
            }
        };
    }

    function wrapEncoder(globalName, queueName) {
        const Original = window[globalName];
        if (typeof Original === "undefined") return;
        window[globalName] = class extends Original {
            constructor(init) {
                super({
                    output: init.output,
                    error: function (e) {
                        stress.errors.push(globalName + ": " + e);
                        init.error(e);
                    },
                });
                trackQueue(queueName, this, "encodeQueueSize");
            }
        };
    }

    // Every AudioContext the page makes, so a suspended one (no audio leaves a
    // page whose context never started) shows up in the results.
    stress.audioContexts = [];
    const OriginalAudioContext = window.AudioContext;
    window.AudioContext = class extends OriginalAudioContext {
        constructor(options) {
            super(options);
            stress.audioContexts.push(this);
        }
    };
    stress.audioContextStates = function () {
        return stress.audioContexts
            .filter((context) => context.state !== "closed")
            .map((context) => context.state + " " + context.sampleRate + "Hz");
    };

    wrapDecoder("VideoDecoder", "video", "videoDecoder");
    wrapDecoder("AudioDecoder", "audio", "audioDecoder");
    wrapEncoder("VideoEncoder", "videoEncoder");
    wrapEncoder("AudioEncoder", "audioEncoder");

    // --- fake camera and mic ---
    //
    // Playwright's WebKit has no capture devices of any kind, real or fake, so
    // getUserMedia throws OverconstrainedError. This stands in a canvas and a
    // tone, which go through the same video element, AudioWorklet, encoders and
    // socket as a real camera and mic would. Each bot gets its own colour and
    // pitch so they can be told apart by eye and ear when watching the call.

    // Audio only: hiding the camera is what makes voice-chat.js ask for the
    // mic alone, the same as for somebody who has no webcam.
    if (config.noVideo && !config.fakeMedia) {
        const enumerateDevices = MediaDevices.prototype.enumerateDevices;
        Object.defineProperty(MediaDevices.prototype, "enumerateDevices", {
            configurable: true,
            writable: true,
            value: async function () {
                const devices = await enumerateDevices.call(this);
                return devices.filter((device) => device.kind !== "videoinput");
            },
        });
    }

    if (config.fakeMedia) {
        let fakeStream = null;

        function makeFakeStream() {
            const audioContext = new AudioContext({ sampleRate: 48000 });
            const oscillator = audioContext.createOscillator();
            oscillator.frequency.value = config.toneHz;
            const gain = audioContext.createGain();
            gain.gain.value = 0.2;
            const destination = audioContext.createMediaStreamDestination();
            oscillator.connect(gain).connect(destination);
            oscillator.start();
            if (config.noVideo) return destination.stream;

            const canvas = document.createElement("canvas");
            canvas.width = 640;
            canvas.height = 480;
            const context = canvas.getContext("2d");
            let frame = 0;
            setInterval(function () {
                context.fillStyle = "hsl(" + config.hue + ", 70%, " + (35 + (frame % 30)) + "%)";
                context.fillRect(0, 0, 640, 480);
                context.fillStyle = "white";
                context.font = "64px sans-serif";
                context.fillText(config.label, 40, 120);
                context.fillText(String(frame), 40, 220);
                frame += 1;
            }, 33);

            return new MediaStream(
                canvas.captureStream(30).getVideoTracks().concat(destination.stream.getAudioTracks())
            );
        }

        // Defined on the prototype, because WebKit quietly ignores assigning
        // these on navigator.mediaDevices itself.
        function replace(name, value) {
            Object.defineProperty(MediaDevices.prototype, name, { configurable: true, writable: true, value });
        }

        replace("enumerateDevices", async function () {
            return [
                { kind: "audioinput", deviceId: "stress-mic", label: "Stress test tone", groupId: "stress" },
                { kind: "videoinput", deviceId: "stress-camera", label: "Stress test canvas", groupId: "stress" },
            ].filter((device) => !(config.noVideo && device.kind === "videoinput"));
        });
        replace("getUserMedia", async function () {
            if (!fakeStream) fakeStream = makeFakeStream();
            // A fresh MediaStream over clones, because voice-chat.js stops the
            // tracks it was handed when a call ends.
            return new MediaStream(fakeStream.getTracks().map((track) => track.clone()));
        });
    }
});
