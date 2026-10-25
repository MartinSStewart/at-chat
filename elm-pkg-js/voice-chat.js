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

exports.init = async function init(app) {
    // The call we are in, or null. Shape:
    //   socket, stream, captureVideo, audioContext
    //   selfId          "<userId> <clientId>", the label on everything we send
    //   roomId          the Call.CallId string, for building peer node ids
    //   peers           Map<senderKey, peer>, see addPeer
    //   camera          the camera's outgoing video, see outgoingVideo
    //   screen          the screen being shared, see startScreenShare
    let call = null;
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
                videoElement.requestVideoFrameCallback(onFrame);
                return;
            }

            if (state.camera.startTime === null) state.camera.startTime = now;

            try {
                const frame = new VideoFrame(videoElement, {
                    timestamp: Math.round((now - state.camera.startTime) * 1000),
                });
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
            if (!readyToSend(state)) return;
            const samples = event.data;
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
            if (!readyToSend(state)) return;
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
        const state = call;
        call = null;
        if (!state) return;
        state.stopped = true;

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
