// port voice_chat_to_js : Json.Encode.Value -> Cmd msg
// port voice_chat_from_js : (Json.Decode.Value -> msg) -> Sub msg
//
// Voice and video chat over the rust server's room WebSocket, in place of the
// WebRTC peer connections this used to open against Cloudflare Realtime. Media
// is encoded with WebCodecs, sent as binary messages, and relayed to everyone
// else in the room; there is no SFU, no signalling and no ICE.
//
// The techniques here are the ones proven out by webcodecs-test.js against the
// echo endpoint: frames come off the camera with requestVideoFrameCallback and
// off the mic with an AudioWorklet, rather than with MediaStreamTrackProcessor,
// which reads better but Firefox has never implemented. Everything used works in
// Chrome 94+, Firefox 132+ and Safari 26+.
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
    //   encoders        video and audio encoders, closed on stop
    let call = null;
    let localStreamPreview = null;

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
    //   next byte     kind, 0 = video and 1 = audio
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

    const CODECS = ["avc1.42001E", "vp8"];
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
    async function pickVideoCodec(width, height) {
        const candidates = [
            { codec: CODECS[0], avc: { format: "annexb" } },
            { codec: CODECS[1] },
        ];
        for (let index = 0; index < candidates.length; index++) {
            const config = Object.assign({
                width,
                height,
                bitrate: 1_000_000,
                framerate: 30,
            }, candidates[index]);
            try {
                const support = await VideoEncoder.isConfigSupported(config);
                if (support.supported) return { config, index };
            } catch (e) {
                // Unsupported codec strings can throw rather than report false.
            }
        }
        return null;
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
            // Which of CODECS our video encoder settled on, stamped onto
            // everything we send. Stays 0 when there is no camera, where it is
            // never read because no video is sent.
            videoCodec: 0,
            videoInputEnabled: args.videoInputEnabled,
            forceKeyFrame: false,
            videoEncoder: null,
            audioEncoder: null,
            // The encoder config, kept so the encoder can be set up again at a
            // different size, and the size it was last set up for.
            videoConfig: null,
            videoSize: null,
            videoStartTime: null,
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
        const videoConfig = await pickVideoCodec(settings.width || 640, settings.height || 480);
        if (state.stopped) return;

        if (videoTrack && !videoConfig) {
            fail("No supported video codec found (tried H.264 and VP8).");
        } else if (videoTrack) {
            state.videoConfig = videoConfig.config;
            state.videoCodec = videoConfig.index;

            // A decoder can do nothing with delta frames until it has seen a
            // key frame, so one goes out every 2s to bound how long recovering
            // from a loss takes, and immediately when somebody joins rather than
            // making them wait out the interval staring at nothing.
            let frameCount = 0;
            pumpVideo(state, function (frame) {
                const encoder = videoEncoderFor(state, frame.displayWidth, frame.displayHeight);
                if (!encoder) return;
                const forced = state.forceKeyFrame;
                state.forceKeyFrame = false;
                encoder.encode(frame, { keyFrame: forced || frameCount % 60 === 0 });
                frameCount += 1;
            });
        }

        if (state.stream.getAudioTracks().length > 0) {
            // Mono, because that is what voice chat needs and it keeps the
            // AudioData the worklet produces to a single plane.
            const audioEncoder = new AudioEncoder({
                output: function (chunk) {
                    send(state, AUDIO, chunk);
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
    function videoEncoderFor(state, width, height) {
        if (width === 0 || height === 0) return null;

        const wrongSize =
            state.videoSize && (state.videoSize.width !== width || state.videoSize.height !== height);

        if (state.videoEncoder && (state.videoEncoder.state === "closed" || wrongSize)) {
            if (state.videoEncoder.state !== "closed") state.videoEncoder.close();
            state.videoEncoder = null;
        }

        if (!state.videoEncoder) {
            state.videoEncoder = new VideoEncoder({
                output: function (chunk) {
                    send(state, VIDEO, chunk);
                },
                error: function (e) {
                    fail("video encoder: " + e);
                },
            });
            state.videoEncoder.configure(
                Object.assign({}, state.videoConfig, { width, height })
            );
            state.videoSize = { width, height };
            // A new encoder starts a new stream, which no decoder can join
            // partway through.
            state.forceKeyFrame = true;
        }

        return state.videoEncoder;
    }

    function readyToSend(state) {
        return !state.stopped && state.socket && state.socket.readyState === WebSocket.OPEN;
    }

    function send(state, kind, chunk) {
        if (!readyToSend(state)) return;
        state.socket.send(packet(state.senderBytes, kind, state.videoCodec, chunk));
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

            if (state.videoStartTime === null) state.videoStartTime = now;

            try {
                const frame = new VideoFrame(videoElement, {
                    timestamp: Math.round((now - state.videoStartTime) * 1000),
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

    // --- receiving peers ---

    function receive(state, buffer) {
        const message = unpack(buffer);
        // Our own messages never come back: the room relays to everyone else.
        if (!message || message.sender === state.selfId) return;

        const peer = state.peers.get(message.sender) || addPeer(state, message.sender);
        if (!peer) return;

        if (message.kind === VIDEO) {
            if (peer.videoCodec !== message.codec) {
                configurePeerVideo(state, peer, message.codec);
            }
            if (!peer.videoDecoder) return;
            // A decoder that starts mid-stream has to wait for a key frame.
            if (!peer.videoReady && message.type !== "key") return;
            peer.videoReady = true;
            try {
                peer.videoDecoder.decode(new EncodedVideoChunk({
                    type: message.type,
                    timestamp: message.timestamp,
                    data: message.data,
                }));
            } catch (e) {
                // The decoder died between the error callback firing and now.
                dropPeerVideo(peer);
            }
        } else {
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

        const peer = {
            senderKey,
            canvas: null,
            gain,
            playheadSeconds: 0,
            videoReady: false,
            videoCodec: null,
            videoDecoder: null,
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

    // A decoder that errors is closed for good, so recovering from one means
    // building another. That makes this the one path for both the first chunk a
    // peer sends and every rebuild after, and it remembers which codec it was
    // last asked for so an unsupported one is not retried on every frame.
    function configurePeerVideo(state, peer, codec) {
        dropPeerVideo(peer);
        peer.videoCodec = codec;

        const name = CODECS[codec];
        if (!name) return;

        try {
            const decoder = new VideoDecoder({
                output: function (frame) {
                    drawFrame(state, peer, frame);
                    frame.close();
                },
                // Asking for the codec again is what rebuilds this decoder, so
                // forgetting it is what lets the next chunk do that.
                error: function () {
                    dropPeerVideo(peer);
                },
            });
            decoder.configure({ codec: name });
            peer.videoDecoder = decoder;
        } catch (e) {
            // This browser cannot decode what the peer encoded with. Their audio
            // still works, so the call carries on without their picture.
        }
    }

    function dropPeerVideo(peer) {
        if (peer.videoDecoder && peer.videoDecoder.state !== "closed") {
            peer.videoDecoder.close();
        }
        peer.videoDecoder = null;
        peer.videoCodec = null;
        peer.videoReady = false;
    }

    // Clearing rather than painting black leaves the canvas transparent, and the
    // background it sits on is already black, so it looks the same as a camera
    // that is on but seeing nothing.
    function clearCanvas(canvas) {
        if (!canvas) return;
        const context = canvas.getContext("2d");
        if (context) context.clearRect(0, 0, canvas.width, canvas.height);
    }

    function drawFrame(state, peer, frame) {
        // Elm renders the peer's canvas only once it knows the peer is in the
        // call, which can be after their first frame arrives, so it is looked up
        // again until it appears.
        if (!peer.canvas || !peer.canvas.isConnected) {
            peer.canvas = document.getElementById(peerNodeId(state.roomId, peer.senderKey));
        }
        if (!peer.canvas) return;

        const context = peer.canvas.getContext("2d");
        if (!context) return;
        if (peer.canvas.width !== frame.displayWidth || peer.canvas.height !== frame.displayHeight) {
            peer.canvas.width = frame.displayWidth;
            peer.canvas.height = frame.displayHeight;
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
        [peer.videoDecoder, peer.audioDecoder].forEach(function (decoder) {
            if (decoder && decoder.state !== "closed") decoder.close();
        });
        try { peer.gain.disconnect(); } catch (e) {}
        clearCanvas(peer.canvas);
        state.peers.delete(senderKey);
    }

    async function stopCall() {
        const state = call;
        call = null;
        if (!state) return;
        state.stopped = true;

        for (const senderKey of [...state.peers.keys()]) {
            removePeer(state, senderKey);
        }
        state.audioNodes.forEach(function (node) {
            try { node.disconnect(); } catch (e) {}
        });
        [state.videoEncoder, state.audioEncoder].forEach(function (encoder) {
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
            if (enabled && !call.videoInputEnabled) call.forceKeyFrame = true;
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

    app.ports.voice_chat_to_js.subscribe(async function (msg) {
        if (msg.tag === "start-call") {
            await startCall(msg.args[0]);
        } else if (msg.tag === "leave-call") {
            await stopCall();
        } else if (msg.tag === "peer-joined") {
            // Their decoder has nothing to show until a key frame reaches it.
            // Building their side of the connection waits for their first chunk,
            // which is the only moment we know what codec they are sending.
            if (call) call.forceKeyFrame = true;
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
                    (peer && peer.canvas) || document.getElementById(peerNodeId(call.roomId, senderKey))
                );
            }
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
