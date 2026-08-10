// port webcodecs_test_to_js : Json.Encode.Value -> Cmd msg
//
// Throwaway test rig for the admin page. Encodes the webcam and mic with
// WebCodecs, ships every chunk to the rust server's /file/websocket echo
// endpoint, and decodes whatever comes back. Since the server mirrors the bytes
// straight back, the picture and sound you get are your own, and the latency
// shown is a real network round trip rather than an estimate.

exports.init = async function init(app) {
    let test = null;

    // Same rule as FileStatus.domain: production talks to the deployed server,
    // development talks to the one npm run rust-server starts.
    function websocketUrl() {
        const host = location.hostname === "localhost" || location.hostname === "127.0.0.1"
            ? "ws://localhost:3000"
            : (location.protocol === "https:" ? "wss://" : "ws://") + location.host;
        return host + "/file/websocket";
    }

    // Every chunk is sent as one binary websocket message:
    //   byte 0      kind, 0 = video and 1 = audio
    //   byte 1      1 when this is a key frame
    //   bytes 2-9   the time we sent it, used to measure the round trip
    //   bytes 10-17 the chunk's own timestamp, which the decoder needs back
    //   rest        the encoded frame
    const HEADER_BYTES = 18;
    const VIDEO = 0;
    const AUDIO = 1;

    function packet(kind, chunk, sentAt) {
        const data = new Uint8Array(chunk.byteLength);
        chunk.copyTo(data);

        const message = new Uint8Array(HEADER_BYTES + data.byteLength);
        const header = new DataView(message.buffer);
        header.setUint8(0, kind);
        header.setUint8(1, chunk.type === "key" ? 1 : 0);
        header.setFloat64(2, sentAt);
        header.setFloat64(10, chunk.timestamp);
        message.set(data, HEADER_BYTES);
        return message;
    }

    function unpack(buffer) {
        const header = new DataView(buffer);
        return {
            kind: header.getUint8(0),
            type: header.getUint8(1) === 1 ? "key" : "delta",
            sentAt: header.getFloat64(2),
            timestamp: header.getFloat64(10),
            data: new Uint8Array(buffer, HEADER_BYTES),
        };
    }

    // H.264 in annexb and VP8 both decode without a codec description, which
    // saves having to ship the encoder's metadata over the wire. Safari only has
    // the first, Chrome has both.
    async function pickVideoCodec(width, height) {
        const candidates = [
            { codec: "avc1.42001E", avc: { format: "annexb" } },
            { codec: "vp8" },
        ];
        for (const candidate of candidates) {
            const config = Object.assign({
                width,
                height,
                bitrate: 1_000_000,
                framerate: 30,
            }, candidate);
            try {
                const support = await VideoEncoder.isConfigSupported(config);
                if (support.supported) return config;
            } catch (e) {
                // Unsupported codec strings can throw rather than report false.
            }
        }
        return null;
    }

    function setStatus(lines) {
        const node = document.getElementById("webcodecsTest_status");
        if (node) node.textContent = lines.join("\n");
    }

    async function start() {
        await stop();

        if (typeof VideoEncoder === "undefined" || typeof MediaStreamTrackProcessor === "undefined") {
            setStatus([
                "This browser is missing WebCodecs or MediaStreamTrackProcessor.",
                "Chrome supports both. Safari added them in 18.4.",
            ]);
            return;
        }

        const state = {
            socket: null,
            stream: null,
            encoders: [],
            decoders: [],
            readers: [],
            audioContext: null,
            playheadSeconds: 0,
            stopped: false,
            stats: {
                bytesSent: 0,
                bytesReceived: 0,
                framesSent: 0,
                framesReceived: 0,
                audioSent: 0,
                audioReceived: 0,
                latencies: [],
                since: performance.now(),
                error: null,
            },
        };
        test = state;

        let stream;
        try {
            stream = await navigator.mediaDevices.getUserMedia({
                video: { width: 640, height: 480, frameRate: 30 },
                audio: true,
            });
        } catch (e) {
            setStatus(["Could not open the camera or mic: " + e]);
            test = null;
            return;
        }
        if (state.stopped) {
            stream.getTracks().forEach((track) => track.stop());
            return;
        }
        state.stream = stream;

        const localVideo = document.getElementById("webcodecsTest_localVideo");
        if (localVideo) {
            localVideo.srcObject = stream;
            localVideo.muted = true; // Without this the mic feeds back into the speakers.
            localVideo.play().catch(() => {});
        }

        const socket = new WebSocket(websocketUrl());
        socket.binaryType = "arraybuffer";
        state.socket = socket;

        socket.onerror = function () {
            state.stats.error = "websocket error, is the rust server running?";
        };
        socket.onclose = function (event) {
            if (!state.stopped) state.stats.error = "websocket closed (code " + event.code + ")";
        };

        await new Promise(function (resolve) {
            socket.onopen = resolve;
            socket.onerror = resolve;
        });
        if (state.stopped || socket.readyState !== WebSocket.OPEN) return;

        const canvas = document.getElementById("webcodecsTest_remoteCanvas");
        const context = canvas ? canvas.getContext("2d") : null;

        // --- playback side, fed by whatever the server echoes back ---

        const videoDecoder = new VideoDecoder({
            output: function (frame) {
                if (context) {
                    canvas.width = frame.displayWidth;
                    canvas.height = frame.displayHeight;
                    context.drawImage(frame, 0, 0);
                }
                frame.close();
            },
            error: function (e) {
                state.stats.error = "video decoder: " + e;
            },
        });
        state.decoders.push(videoDecoder);

        const audioContext = new AudioContext();
        state.audioContext = audioContext;

        const audioDecoder = new AudioDecoder({
            output: function (audioData) {
                playAudio(state, audioData);
                audioData.close();
            },
            error: function (e) {
                state.stats.error = "audio decoder: " + e;
            },
        });
        state.decoders.push(audioDecoder);

        let videoDecoderReady = false;

        socket.onmessage = function (event) {
            if (state.stopped) return;
            const message = unpack(event.data);
            state.stats.bytesReceived += event.data.byteLength;
            state.stats.latencies.push(performance.now() - message.sentAt);
            if (state.stats.latencies.length > 120) state.stats.latencies.shift();

            if (message.kind === VIDEO) {
                state.stats.framesReceived += 1;
                // A decoder that starts mid-stream has to wait for a key frame.
                if (!videoDecoderReady && message.type !== "key") return;
                videoDecoderReady = true;
                videoDecoder.decode(new EncodedVideoChunk({
                    type: message.type,
                    timestamp: message.timestamp,
                    data: message.data,
                }));
            } else {
                state.stats.audioReceived += 1;
                audioDecoder.decode(new EncodedAudioChunk({
                    type: message.type,
                    timestamp: message.timestamp,
                    data: message.data,
                }));
            }
        };

        // --- capture side ---

        const videoTrack = stream.getVideoTracks()[0];
        const settings = videoTrack.getSettings();
        const videoConfig = await pickVideoCodec(settings.width || 640, settings.height || 480);
        if (!videoConfig) {
            setStatus(["No supported video codec found (tried H.264 and VP8)."]);
            await stop();
            return;
        }

        videoDecoder.configure({ codec: videoConfig.codec });

        const videoEncoder = new VideoEncoder({
            output: function (chunk) {
                send(state, VIDEO, chunk);
            },
            error: function (e) {
                state.stats.error = "video encoder: " + e;
            },
        });
        videoEncoder.configure(videoConfig);
        state.encoders.push(videoEncoder);

        const audioTrack = stream.getAudioTracks()[0];
        const audioSettings = audioTrack.getSettings();
        const audioConfig = {
            codec: "opus",
            sampleRate: audioSettings.sampleRate || 48000,
            numberOfChannels: audioSettings.channelCount || 1,
            bitrate: 64000,
        };
        audioDecoder.configure({
            codec: audioConfig.codec,
            sampleRate: audioConfig.sampleRate,
            numberOfChannels: audioConfig.numberOfChannels,
        });

        const audioEncoder = new AudioEncoder({
            output: function (chunk) {
                send(state, AUDIO, chunk);
            },
            error: function (e) {
                state.stats.error = "audio encoder: " + e;
            },
        });
        audioEncoder.configure(audioConfig);
        state.encoders.push(audioEncoder);

        // Key frame every 2s so the decoder recovers quickly if it loses sync.
        let frameCount = 0;
        pump(state, videoTrack, function (frame) {
            videoEncoder.encode(frame, { keyFrame: frameCount % 60 === 0 });
            frameCount += 1;
        });
        pump(state, audioTrack, function (audioData) {
            audioEncoder.encode(audioData);
        });

        reportStats(state);
    }

    // Reads frames off a track and hands them to the encoder, closing each one
    // afterwards. WebCodecs frames hold real memory and the pipeline stalls
    // within a second or two if they are not released.
    async function pump(state, track, encode) {
        const reader = new MediaStreamTrackProcessor({ track }).readable.getReader();
        state.readers.push(reader);
        try {
            while (!state.stopped) {
                const { value, done } = await reader.read();
                if (done) break;
                // Encoding is faster than capture, but if the queue does back up
                // it is better to drop than to grow an unbounded backlog.
                if (state.socket && state.socket.readyState === WebSocket.OPEN) {
                    encode(value);
                }
                value.close();
            }
        } catch (e) {
            if (!state.stopped) state.stats.error = "capture: " + e;
        }
    }

    function send(state, kind, chunk) {
        if (state.stopped || !state.socket || state.socket.readyState !== WebSocket.OPEN) return;
        const message = packet(kind, chunk, performance.now());
        state.socket.send(message);
        state.stats.bytesSent += message.byteLength;
        if (kind === VIDEO) state.stats.framesSent += 1;
        else state.stats.audioSent += 1;
    }

    // Queues decoded audio back to back. Each buffer is scheduled after the
    // previous one so the samples play continuously rather than on top of each
    // other; if the playhead falls behind, it resets with a small cushion.
    function playAudio(state, audioData) {
        const context = state.audioContext;
        if (!context) return;

        const channels = audioData.numberOfChannels;
        const buffer = context.createBuffer(channels, audioData.numberOfFrames, audioData.sampleRate);
        for (let channel = 0; channel < channels; channel++) {
            const samples = new Float32Array(audioData.numberOfFrames);
            audioData.copyTo(samples, { planeIndex: channel, format: "f32-planar" });
            buffer.copyToChannel(samples, channel);
        }

        const source = context.createBufferSource();
        source.buffer = buffer;
        source.connect(context.destination);

        if (state.playheadSeconds < context.currentTime) {
            state.playheadSeconds = context.currentTime + 0.05;
        }
        source.start(state.playheadSeconds);
        state.playheadSeconds += buffer.duration;
    }

    function reportStats(state) {
        if (state.stopped) return;

        const stats = state.stats;
        const seconds = (performance.now() - stats.since) / 1000;
        const latencies = stats.latencies.slice().sort(function (a, b) { return a - b; });
        const median = latencies.length ? latencies[Math.floor(latencies.length / 2)] : 0;
        const worst = latencies.length ? latencies[latencies.length - 1] : 0;
        const kbps = (stats.bytesSent * 8) / seconds / 1000;

        setStatus([
            "round trip:  median " + median.toFixed(1) + " ms, worst " + worst.toFixed(1) + " ms",
            "upstream:    " + kbps.toFixed(0) + " kbit/s (" + (stats.bytesSent / 1048576).toFixed(1) + " MB sent)",
            "video:       " + stats.framesSent + " frames sent, " + stats.framesReceived + " back, "
                + (stats.framesSent / seconds).toFixed(1) + " fps",
            "audio:       " + stats.audioSent + " chunks sent, " + stats.audioReceived + " back",
            stats.error ? "error:       " + stats.error : "",
        ]);

        setTimeout(function () { reportStats(state); }, 500);
    }

    async function stop() {
        const state = test;
        test = null;
        if (!state) return;
        state.stopped = true;

        state.readers.forEach(function (reader) { reader.cancel().catch(function () {}); });
        state.encoders.concat(state.decoders).forEach(function (codec) {
            if (codec.state !== "closed") codec.close();
        });
        if (state.stream) state.stream.getTracks().forEach(function (track) { track.stop(); });
        if (state.socket) state.socket.close();
        if (state.audioContext) state.audioContext.close().catch(function () {});

        const localVideo = document.getElementById("webcodecsTest_localVideo");
        if (localVideo) localVideo.srcObject = null;
    }

    app.ports.webcodecs_test_to_js.subscribe(function (isRunning) {
        if (isRunning) {
            start().catch(function (e) { setStatus(["Failed to start: " + e]); });
        } else {
            stop();
            setStatus(["Stopped."]);
        }
    });
};
