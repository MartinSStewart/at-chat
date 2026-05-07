exports.init = async function init(app) {
    const connections = new Map();
    const pendingSignals = new Map();

    async function startConnection(peerUserId, shouldOffer, audioInput, videoInput) {
        stopConnection(peerUserId);

        let localStream;
        let devices;
        try {
            let devices2 = await navigator.mediaDevices.enumerateDevices();
            localStream =
                await navigator.mediaDevices.getUserMedia(
                    { audio: audioInput ? { deviceId: audioInput } : devices2.some(a => a.kind === "audioinput")
                    , video: videoInput ? { deviceId: videoInput } : devices2.some(a => a.kind === "videoinput")
                    });
            devices = await navigator.mediaDevices.enumerateDevices();
        } catch (e) {
            app.ports.voice_chat_from_js.send( { tag: "got-media-devices-error" , args: [ e.toString() ] });
            return;
        }

        const pc = new RTCPeerConnection({
            iceServers: [{ urls: "stun:stun.l.google.com:19302" }]
        });


        let videoTracks = [];
        let defaultDevices = [];

        localStream.getTracks().forEach(function (track) {
            defaultDevices.push(track.getSettings().deviceId);
            pc.addTrack(track, localStream);
        });

        let mediaRecorder = new MediaRecorder(localStream);

        let startTime = Date.now();
        console.log("Start", startTime);

        mediaRecorder.addEventListener("dataavailable", async (e) => {
            let endTime = Date.now();
            const peerIdBytes = new TextEncoder().encode(peerUserId);
            const typeBytes = new TextEncoder().encode(e.data.type);
            const dataBuffer = await e.data.arrayBuffer();
            const result = new ArrayBuffer(1 + peerIdBytes.length + 1 + typeBytes.length + 8 + 8 + dataBuffer.byteLength);
            const view = new DataView(result);
            const bytes = new Uint8Array(result);

            view.setUint8(0, peerIdBytes.length);
            bytes.set(peerIdBytes, 1);
            let offset = 1 + peerIdBytes.length;
            view.setUint8(offset, typeBytes.length);
            offset += 1;
            bytes.set(typeBytes, offset);
            offset += typeBytes.length;

            view.setFloat64(offset, startTime);
            offset += 8;
            view.setFloat64(offset, endTime);
            offset += 8;

            bytes.set(new Uint8Array(dataBuffer), offset);
            app.ports.got_recorded_data.send(new DataView(result));
        });
        mediaRecorder.start();

        app.ports.voice_chat_from_js.send( { tag: "got-media-devices" , args: [ devices, defaultDevices ] });

        console.log("Voice chat: startConnection", peerUserId);

        const videoNode = document.getElementById(peerUserId);

        pc.ontrack = function (event) {
            console.log("Voice chat: ontrack", peerUserId, event.streams);

            let remoteStream;
            if (event.streams && event.streams[0]) {
                remoteStream = event.streams[0];
                videoNode.srcObject = remoteStream;
            } else {
                // Fallback: build a stream from the single track.
                remoteStream = new MediaStream();
                remoteStream.addTrack(event.track);
                videoNode.srcObject = remoteStream;
            }
            if (event.track.kind === "audio" && !audioStreams.has(peerUserId)) {
                handleAudioStream(remoteStream, peerUserId);
            }
            const playPromise = videoNode.play();
            if (playPromise && typeof playPromise.catch === "function") {
                playPromise.catch(function (err) {
                    console.error("Voice chat: audio play() rejected", err);
                });
            }
        };

        pc.oniceconnectionstatechange = function () {
            console.log("Voice chat: ICE state", peerUserId, pc.iceConnectionState);
        };
        pc.onconnectionstatechange = function () {
            console.log("Voice chat: PC state", peerUserId, pc.connectionState);
        };

        pc.onicecandidate = function (event) {
            if (event.candidate) {
                app.ports.voice_chat_from_js.send(
                    { tag: "got-signal"
                    , args: [ peerUserId, { tag: "ice", args: [ event.candidate ] }]
                    });
            }
        };

        const conn = {
            pc: pc,
            videoNode: videoNode,
            remoteDescriptionSet: false,
            queuedIceCandidates: [],
            signalChain: Promise.resolve()
        };
        connections.set(peerUserId, conn);

        const pending = pendingSignals.get(peerUserId) || [];
        pendingSignals.set(peerUserId, []);
        for (let i = 0; i < pending.length; i++) {
            await handleSignalInternal(conn, peerUserId, pending[i]);
        }

        if (shouldOffer) {
            try {
                const offer = await pc.createOffer();
                await pc.setLocalDescription(offer);
                app.ports.voice_chat_from_js.send(
                    { tag: "got-signal"
                    , args: [ peerUserId, { tag: "offer", args: [ offer ] }]
                    });
            } catch (e) {
                console.error("Voice chat: failed to create offer", e);
            }
        }
    }

    function stopConnection(peerUserId) {
        const conn = connections.get(peerUserId);
        if (!conn) return;

        if (conn.pc) {
            conn.pc.getSenders().forEach((s) => s.track.stop());
            conn.pc.ontrack = null;
            conn.pc.onnicecandidate = null;
            conn.pc.oniceconnectionstatechange = null;
            conn.pc.onsignalingstatechange = null;
            conn.pc.onicegatheringstatechange = null;
            conn.pc.onnotificationneeded = null;
            conn.pc.close();
        }
        if (conn.videoNode) {
            conn.videoNode.srcObject = null;
        }
        removeAudioStream(peerUserId);
        connections.delete(peerUserId);
        pendingSignals.delete(peerUserId);
    }

    async function drainQueuedIceCandidates(conn, peerUserId) {
        const queued = conn.queuedIceCandidates;
        conn.queuedIceCandidates = [];
        for (let i = 0; i < queued.length; i++) {
            try {
                await conn.pc.addIceCandidate(queued[i]);
            } catch (e) {
                console.error("Voice chat: failed to add queued ICE candidate", peerUserId, e);
            }
        }
    }

    async function handleSignalInternal(conn, peerUserId, signal) {
        try {
            if (signal.tag === "offer") {
                await conn.pc.setRemoteDescription({ type: "offer", sdp: signal.args[0].sdp });
                conn.remoteDescriptionSet = true;
                await drainQueuedIceCandidates(conn, peerUserId);
                const answer = await conn.pc.createAnswer();
                await conn.pc.setLocalDescription(answer);
                app.ports.voice_chat_from_js.send(
                    { tag: "got-signal"
                    , args: [ peerUserId, { tag: "answer", args: [ answer ] }]
                    });
            } else if (signal.tag === "answer") {
                await conn.pc.setRemoteDescription({ type: "answer", sdp: signal.args[0].sdp });
                conn.remoteDescriptionSet = true;
                await drainQueuedIceCandidates(conn, peerUserId);
            } else if (signal.tag === "ice") {
                if (conn.remoteDescriptionSet) {
                    await conn.pc.addIceCandidate(signal.args[0]);
                } else {
                    conn.queuedIceCandidates.push(signal.args[0]);
                }
            }
        } catch (e) {
            console.error("Voice chat: failed to handle signal", e);
        }
    }

    function handleSignal(peerUserId, signalStr) {
        const conn = connections.get(peerUserId);
        if (!conn) {
            let pending = pendingSignals.get(peerUserId);
            if (!pending) {
                pending = [];
                pendingSignals.set(peerUserId, pending);
            }
            pending.push(signalStr);
            return;
        }
        // Serialize signal processing per peer so offer/answer/ice never race.
        conn.signalChain = conn.signalChain.then(function () {
            return handleSignalInternal(conn, peerUserId, signalStr);
        });
    }

    function setAudioInputEnabled(enabled) {
        connections.forEach(function (conn) {
            if (conn.pc) {
                const sender = conn.pc.getSenders().forEach((s) => {
                    if (s.track.kind === "audio") {
                        s.track.enabled = enabled;
                    }
                });
            }
        });
    }

    async function setAudioInput(deviceId) {
        let stream = await navigator.mediaDevices.getUserMedia({ audio: { deviceId: { exact: deviceId } } });
        let tracks = stream.getAudioTracks();
        console.log("Tracks: ", tracks);
        let track = tracks[0];
        connections.forEach(function (conn) {
            if (conn.pc) {
                const sender = conn.pc.getSenders().find((s) => s.track.kind === track.kind);
                let oldTrack = sender.track;
                track.enabled = oldTrack.enabled;
                sender.replaceTrack(track);
                oldTrack.stop();
            }
        });
    }

    function setVideoInputEnabled(enabled) {
        connections.forEach(function (conn) {
            if (conn.pc) {
                const sender = conn.pc.getSenders().forEach((s) => {
                    if (s.track.kind === "video") {
                        s.track.enabled = enabled;
                    }
                });
            }
        });
    }

    app.ports.voice_chat_to_js.subscribe(async function (msg) {
        if (msg.tag === "start") {
            const args = msg.args[0];
            await startConnection(args.peerUserId, args.shouldOffer, args.audioInput, args.videoInput);
            setAudioInputEnabled(args.audioInputEnabled);
            setVideoInputEnabled(args.videoInputEnabled);
        } else if (msg.tag === "stop") {
            stopConnection(msg.args[0]);
        } else if (msg.tag === "signal") {
            await handleSignal(msg.args[0], msg.args[1]);
        } else if (msg.tag === "set-audio-input-enabled") {
            setAudioInputEnabled(msg.args[0]);
        } else if (msg.tag === "set-audio-input") {
            setAudioInput(msg.args[0]);
        } else if (msg.tag === "set-video-input-enabled") {
            setVideoInputEnabled(msg.args[0]);
        } else if (msg.tag === "get-media-devices") {
            try {
                let stream = await getDevices();
                let devices = await navigator.mediaDevices.enumerateDevices();

                let defaultDevices = [];
                stream.getTracks().forEach(track => {
                    defaultDevices.push(track.getSettings().deviceId);
                    track.stop();
                });

                app.ports.voice_chat_from_js.send( { tag: "got-media-devices", args: [ devices, defaultDevices ] });

            } catch (e) {
                app.ports.voice_chat_from_js.send( { tag: "got-media-devices-error", args: [ e.toString() ] });
            }
        }
    });

    async function getDevices() {
        let devices = await navigator.mediaDevices.enumerateDevices();
        let hasMic = devices.some(a => a.kind === "audioinput");
        let hasCamera = devices.some(a => a.kind === "videoinput");
        return await navigator.mediaDevices.getUserMedia({ audio: hasMic, video: hasCamera });
    }

    // Original code found here: https://www.linkedin.com/pulse/webrtc-active-speaker-detection-nilesh-gawande
    // Global variables to keep track of audio streams and their volume level
    const VOLUME_THRESHOLD = 20; // Adjust this threshold to suit your needs
    const AUDIO_WINDOW_SIZE = 256;
    let audioStreams = new Map();

    // Function to handle incoming audio streams from WebRTC peers
    function handleAudioStream(stream, peerUserId) {
        const audioContext = new AudioContext();
        const mediaStreamSource = audioContext.createMediaStreamSource(stream);

        const analyserNode = audioContext.createAnalyser();
        analyserNode.fftSize = AUDIO_WINDOW_SIZE;
        mediaStreamSource.connect(analyserNode);

        const bufferLength = analyserNode.frequencyBinCount;
        const dataArray = new Uint8Array(bufferLength);

        const entry = {
            stream,
            analyserNode,
            audioContext,
            mediaStreamSource,
            isSpeaking: false,
            stopped: false
        };
        audioStreams.set(peerUserId, entry);

        function processAudio() {
            if (entry.stopped) return;
            analyserNode.getByteFrequencyData(dataArray);
            const averageVolume = dataArray.reduce((acc, val) => acc + val, 0) / bufferLength;
            const isSpeaking = averageVolume > VOLUME_THRESHOLD;
            if (isSpeaking !== entry.isSpeaking) {
                entry.isSpeaking = isSpeaking;
                app.ports.voice_chat_from_js.send(
                    { tag: "is-speaking-changed"
                    , args: [ peerUserId, isSpeaking ]
                    });
            }
            requestAnimationFrame(processAudio);
        }

        processAudio();
    }

    // Function to remove audio stream and stop active speaker detection
    function removeAudioStream(peerUserId) {
        const streamData = audioStreams.get(peerUserId);
        if (streamData) {
            streamData.stopped = true;
            try { streamData.mediaStreamSource.disconnect(); } catch (e) {}
            try { streamData.analyserNode.disconnect(); } catch (e) {}
            try { streamData.audioContext.close(); } catch (e) {}
            audioStreams.delete(peerUserId);
            if (streamData.isSpeaking) {
                app.ports.voice_chat_from_js.send(
                    { tag: "is-speaking-changed"
                    , args: [ peerUserId, false ]
                    });
            }
        }
    }

};

