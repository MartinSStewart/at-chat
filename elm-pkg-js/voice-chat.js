exports.init = async function init(app) {
    const connections = new Map();
    const pendingSignals = new Map();
    let localStreamPreview = null;
    // Map from screen-share source id (= stream id) -> { stream, label, track }
    const screenShareStreams = new Map();

    async function startConnection(args) {
        try {

            stopConnection(args.peerUserId);

            const pc = new RTCPeerConnection({
                iceServers: [{ urls: "stun:stun.l.google.com:19302" }]
            });

            // Suppress the negotiationneeded that fires from the initial
            // addTrack calls below — startConnection handles that offer
            // itself. Flipped to false after the initial offer is sent.
            let suppressNegotiation = true;
            pc.onnegotiationneeded = function () {
                if (suppressNegotiation) return;
                if (pc.signalingState !== "stable") return;
                (async function () {
                    try {
                        const offer = await pc.createOffer();
                        if (pc.signalingState !== "stable") return;
                        await pc.setLocalDescription(offer);
                        app.ports.voice_chat_from_js.send(
                            { tag: "got-signal"
                            , args: [ args.peerUserId, { tag: "offer", args: [ offer ] }]
                            });
                    } catch (e) {
                        console.error("Voice chat: renegotiation failed", e);
                    }
                })();
            };

            try {
                let localStream = await getUserMedia(args);
                let devices = await navigator.mediaDevices.enumerateDevices();

                let defaultDevices = [];
                localStream.getTracks().forEach(function (track) {
                    defaultDevices.push(track.getSettings().deviceId);
                    pc.addTrack(track, localStream);
                });

                app.ports.voice_chat_from_js.send( { tag: "got-media-devices" , args: [ devices, defaultDevices ] });
            } catch (e) {
                app.ports.voice_chat_from_js.send( { tag: "got-media-devices-error" , args: [ e.toString() ] });
                return;
            }


    //        let mediaRecorder = new MediaRecorder(localStream);
    //
    //        let startTime = Date.now();
    //        console.log("Start", startTime);
    //
    //        mediaRecorder.addEventListener("dataavailable", async (e) => {
    //            let endTime = Date.now();
    //            const peerIdBytes = new TextEncoder().encode(peerUserId);
    //            const typeBytes = new TextEncoder().encode(e.data.type);
    //            const dataBuffer = await e.data.arrayBuffer();
    //            const result = new ArrayBuffer(1 + peerIdBytes.length + 1 + typeBytes.length + 8 + 8 + dataBuffer.byteLength);
    //            const view = new DataView(result);
    //            const bytes = new Uint8Array(result);
    //
    //            view.setUint8(0, peerIdBytes.length);
    //            bytes.set(peerIdBytes, 1);
    //            let offset = 1 + peerIdBytes.length;
    //            view.setUint8(offset, typeBytes.length);
    //            offset += 1;
    //            bytes.set(typeBytes, offset);
    //            offset += typeBytes.length;
    //
    //            view.setFloat64(offset, startTime);
    //            offset += 8;
    //            view.setFloat64(offset, endTime);
    //            offset += 8;
    //
    //            bytes.set(new Uint8Array(dataBuffer), offset);
    //            app.ports.got_recorded_data.send(new DataView(result));
    //        });
    //        mediaRecorder.start();



            console.log("Voice chat: startConnection", args.peerUserId);

            const videoNode = document.getElementById(args.peerUserId);

            // The first remote stream we see (the peer's combined camera+mic
            // stream) is the "primary". Any additional stream is a screen
            // share and gets its own remote <video> element.
            let primaryStreamId = null;
            const remoteScreenShareStreams = new Map();

            pc.ontrack = function (event) {
                console.log("Voice chat: ontrack", args.peerUserId, event.streams);

                let remoteStream;
                if (event.streams && event.streams[0]) {
                    remoteStream = event.streams[0];
                } else {
                    // Fallback: build a stream from the single track.
                    remoteStream = new MediaStream();
                    remoteStream.addTrack(event.track);
                }

                if (primaryStreamId === null) {
                    primaryStreamId = remoteStream.id;
                }

                if (remoteStream.id === primaryStreamId) {
                    videoNode.srcObject = remoteStream;
                    if (event.track.kind === "audio" && !audioStreams.has(args.peerUserId)) {
                        handleAudioStream(remoteStream, args.peerUserId);
                    }
                    const playPromise = videoNode.play();
                    if (playPromise && typeof playPromise.catch === "function") {
                        playPromise.catch(function (err) {
                            console.error("Voice chat: audio play() rejected", err);
                        });
                    }
                } else {
                    // A remote screen share.
                    const sourceId = remoteStream.id;
                    if (!remoteScreenShareStreams.has(sourceId)) {
                        remoteScreenShareStreams.set(sourceId, remoteStream);
                        app.ports.voice_chat_from_js.send(
                            { tag: "got-remote-screen-share"
                            , args: [ args.peerUserId, sourceId ]
                            });
                        bindStreamWhenReady(
                            remoteScreenShareElementId(args.peerUserId, sourceId),
                            remoteStream,
                            false
                        );
                        function endRemoteShare() {
                            if (!remoteScreenShareStreams.has(sourceId)) return;
                            remoteScreenShareStreams.delete(sourceId);
                            app.ports.voice_chat_from_js.send(
                                { tag: "remote-screen-share-ended"
                                , args: [ args.peerUserId, sourceId ]
                                });
                        }
                        event.track.addEventListener("ended", endRemoteShare);
                        event.track.addEventListener("mute", endRemoteShare);
                        remoteStream.addEventListener("removetrack", function (e) {
                            if (e.track && e.track.id === event.track.id) {
                                endRemoteShare();
                            }
                        });
                    }
                }
            };

            pc.oniceconnectionstatechange = function () {
                console.log("Voice chat: ICE state", args.peerUserId, pc.iceConnectionState);
            };
            pc.onconnectionstatechange = function () {
                console.log("Voice chat: PC state", args.peerUserId, pc.connectionState);
            };

            pc.onicecandidate = function (event) {
                if (event.candidate) {
                    app.ports.voice_chat_from_js.send(
                        { tag: "got-signal"
                        , args: [ args.peerUserId, { tag: "ice", args: [ event.candidate ] }]
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
            connections.set(args.peerUserId, conn);

            // If we are already screen sharing, attach those tracks to the
            // new peer connection too.
            screenShareStreams.forEach(function (entry) {
                try {
                    pc.addTrack(entry.track, entry.stream);
                } catch (e) {
                    console.error("Voice chat: failed to add existing screen share to new peer", e);
                }
            });

            const pending = pendingSignals.get(args.peerUserId) || [];
            pendingSignals.set(args.peerUserId, []);
            for (let i = 0; i < pending.length; i++) {
                await handleSignalInternal(conn, args.peerUserId, pending[i]);
            }

            if (args.shouldOffer) {
                try {
                    const offer = await pc.createOffer();
                    await pc.setLocalDescription(offer);
                    app.ports.voice_chat_from_js.send(
                        { tag: "got-signal"
                        , args: [ args.peerUserId, { tag: "offer", args: [ offer ] }]
                        });
                } catch (e) {
                    console.error("Voice chat: failed to create offer", e);
                }
            }
            suppressNegotiation = false;
        }
        catch (e) {
            app.ports.voice_chat_from_js.send( { tag: "start-connection-error" , args: [ e.toString() ] });
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

        if (localStreamPreview) {
            localStreamPreview.getAudioTracks().forEach((track) => {
                track.enabled = enabled;
            });
        }
    }

    function setVideoInputEnabled(enabled) {
        connections.forEach(function (conn) {
            if (conn.pc) {
                conn.pc.getSenders().forEach((s) => {
                    if (s.track && s.track.kind === "video" && !s.track._isScreenShare) {
                        s.track.enabled = enabled;
                    }
                });
            }
        });

        if (localStreamPreview) {
            localStreamPreview.getVideoTracks().forEach((track) => {
                track.enabled = enabled;
            });
        }
    }

    async function setInput(isAudioInput, deviceId) {
        let config;
        if (isAudioInput) {
            config = { audio: { deviceId: { exact: deviceId } } };
        } else {
            config = { video: { deviceId: { exact: deviceId } } };
        }

        let stream = await navigator.mediaDevices.getUserMedia(config);
        let tracks;
        if (isAudioInput) {
            tracks = stream.getAudioTracks();
        } else {
            tracks = stream.getVideoTracks();
        }
        let track = tracks[0];
        connections.forEach(function (conn) {
            if (conn.pc) {
                const sender = conn.pc.getSenders().find(
                    (s) => s.track && s.track.kind === track.kind && !s.track._isScreenShare
                );
                if (!sender) return;
                let oldTrack = sender.track;
                track.enabled = oldTrack.enabled;
                sender.replaceTrack(track);
                oldTrack.stop();
            }
        });
    }

    app.ports.voice_chat_to_js.subscribe(async function (msg) {
        if (msg.tag === "start") {
            const args = msg.args[0];
            await startConnection(args);
            setAudioInputEnabled(args.audioInputEnabled);
            setVideoInputEnabled(args.videoInputEnabled);
        } else if (msg.tag === "stop") {
            stopConnection(msg.args[0]);
        } else if (msg.tag === "signal") {
            await handleSignal(msg.args[0], msg.args[1]);
        } else if (msg.tag === "set-audio-input-enabled") {
            setAudioInputEnabled(msg.args[0]);
        } else if (msg.tag === "set-input") {
            setInput(msg.args[0], msg.args[1]);
        } else if (msg.tag === "set-video-input-enabled") {
            setVideoInputEnabled(msg.args[0]);
        } else if (msg.tag === "set-volume") {
            const conn = connections.get(msg.args[0]);
            if (conn) {
                conn.videoNode.volume = msg.args[1];
            }
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
        } else if (msg.tag === "start-local-stream") {
            const args = msg.args[0];
            startLocalStream(args);

        } else if (msg.tag === "stop-local-stream") {
            stopLocalStream();
        } else if (msg.tag === "start-screen-share") {
            await startScreenShare();
        } else if (msg.tag === "stop-screen-share") {
            stopScreenShare();
        } else if (msg.tag === "switch-screen-share") {
            switchScreenShare(msg.args[0]);
        }
    });

    async function startScreenShare() {
        if (!navigator.mediaDevices || !navigator.mediaDevices.getDisplayMedia) {
            console.error("Voice chat: getDisplayMedia is not supported in this browser");
            return;
        }
        let stream;
        try {
            stream = await navigator.mediaDevices.getDisplayMedia({ video: true, audio: false });
        } catch (e) {
            // User cancelled or permission denied. Not an error worth surfacing.
            console.log("Voice chat: getDisplayMedia cancelled or failed", e);
            return;
        }

        const videoTrack = stream.getVideoTracks()[0];
        if (!videoTrack) {
            stream.getTracks().forEach(t => t.stop());
            return;
        }
        // Tag so other helpers (setInput, setVideoInputEnabled) can skip it.
        videoTrack._isScreenShare = true;

        const sourceId = stream.id;
        const label = videoTrack.label || "Screen";

        screenShareStreams.set(sourceId, { stream: stream, label: label, track: videoTrack });

        videoTrack.addEventListener("ended", function () {
            handleScreenShareEnded(sourceId);
        });

        // Add the screen-share track as a NEW track on every existing peer
        // connection. The browser will fire onnegotiationneeded which our
        // handler turns into a fresh offer/answer round-trip.
        connections.forEach(function (conn) {
            if (!conn.pc) return;
            try {
                conn.pc.addTrack(videoTrack, stream);
            } catch (e) {
                console.error("Voice chat: failed to addTrack for screen share", e);
            }
        });

        app.ports.voice_chat_from_js.send(
            { tag: "got-screen-share-source"
            , args: [ { sourceId: sourceId, label: label } ]
            });

        bindStreamWhenReady(localScreenShareElementId(sourceId), stream, true);
    }

    function switchScreenShare(sourceId) {
        // With addTrack semantics every share is independent — selecting from
        // the dropdown is just a label/UI hint, the stream is already live.
        // Re-bind the local preview in case the element was re-keyed.
        const entry = screenShareStreams.get(sourceId);
        if (entry) {
            bindStreamWhenReady(localScreenShareElementId(sourceId), entry.stream, true);
        }
    }

    function stopScreenShare() {
        // Snapshot keys first since handleScreenShareEnded mutates the map.
        const sourceIds = Array.from(screenShareStreams.keys());
        sourceIds.forEach(function (sourceId) {
            handleScreenShareEnded(sourceId);
        });
    }

    function handleScreenShareEnded(sourceId) {
        const entry = screenShareStreams.get(sourceId);
        if (!entry) {
            return;
        }

        connections.forEach(function (conn) {
            if (!conn.pc) return;
            const sender = conn.pc.getSenders().find(
                (s) => s.track && s.track.id === entry.track.id
            );
            if (sender) {
                try {
                    conn.pc.removeTrack(sender);
                } catch (e) {
                    console.error("Voice chat: failed to removeTrack", e);
                }
            }
        });

        try { entry.track.stop(); } catch (e) {}
        try { entry.stream.getTracks().forEach((t) => t.stop()); } catch (e) {}
        screenShareStreams.delete(sourceId);

        app.ports.voice_chat_from_js.send(
            { tag: "screen-share-ended"
            , args: [ sourceId ]
            });
    }

    function localScreenShareElementId(sourceId) {
        return "local-screen-share " + sourceId;
    }

    function remoteScreenShareElementId(peerUserId, sourceId) {
        return "screen-share " + peerUserId + " " + sourceId;
    }

    // Bind a MediaStream to a <video> element. Because Elm renders on its own
    // schedule, the element may not exist yet — retry on rAF until it shows
    // up or we give up.
    function bindStreamWhenReady(elementId, stream, muted) {
        let attempts = 0;
        function tick() {
            const el = document.getElementById(elementId);
            if (el) {
                if (muted) el.muted = true;
                el.srcObject = stream;
                const p = el.play();
                if (p && typeof p.catch === "function") {
                    p.catch(function (err) {
                        console.error("Voice chat: screen-share play() rejected", err);
                    });
                }
                return;
            }
            if (attempts++ < 60) {
                requestAnimationFrame(tick);
            } else {
                console.error("Voice chat: gave up waiting for element", elementId);
            }
        }
        tick();
    }

    async function getDevices() {
        let devices = await navigator.mediaDevices.enumerateDevices();
        let hasMic = devices.some(a => a.kind === "audioinput");
        let hasCamera = devices.some(a => a.kind === "videoinput");
        if (!hasMic && !hasCamera) {
            return new MediaStream();
        }
        return await navigator.mediaDevices.getUserMedia({ audio: hasMic, video: hasCamera });
    }

    async function getUserMedia(args) {
        let devices = await navigator.mediaDevices.enumerateDevices();

        let hasMic = devices.some(a => a.kind === "audioinput");
        let hasCamera = devices.some(a => a.kind === "videoinput");
        if (!hasMic && !hasCamera) {
            return new MediaStream();
        }
        let config =
            { audio: args.audioInput ? { deviceId: { exact: args.audioInput } } : hasMic
            , video: args.videoInput ? { deviceId: { exact: args.videoInput } } : hasCamera
            };
        return await navigator.mediaDevices.getUserMedia(config);
    }

    async function stopLocalStream() {
        const videoNode = document.getElementById("local-video");
        if (localStreamPreview) {
            localStreamPreview.getTracks().forEach((s) => s.stop());
        }
        if (videoNode.srcObject) {
            videoNode.srcObject.getTracks().forEach((s) => s.stop());
        }
        videoNode.srcObject = null;
        localStreamPreview = null;
        removeAudioStream("local-video");
    }

    async function startLocalStream(args) {
        stopLocalStream();

        try {
            localStreamPreview = await getUserMedia(args);
            let devices = await navigator.mediaDevices.enumerateDevices();

            let defaultDevices = [];
            localStreamPreview.getTracks().forEach(function (track) {
                defaultDevices.push(track.getSettings().deviceId);
            });

            app.ports.voice_chat_from_js.send( { tag: "got-media-devices" , args: [ devices, defaultDevices ] });


        } catch (e) {
            app.ports.voice_chat_from_js.send( { tag: "got-media-devices-error" , args: [ e.toString() ] });
            return;
        }

        const videoNode = document.getElementById("local-video");
        // iOS Safari ignores HTMLMediaElement.volume (controllable only via
        // hardware buttons), so volume = 0 doesn't silence the local preview
        // and the mic gets echoed back to the speakers. Use muted instead,
        // and only feed the video tracks into the preview element so the
        // mic audio can't leak through srcObject either.
        videoNode.muted = true;
        const previewStream = new MediaStream();
        localStreamPreview.getVideoTracks().forEach(function (track) {
            previewStream.addTrack(track);
        });
        videoNode.srcObject = previewStream;

        setAudioInputEnabled(args.audioInputEnabled);
        setVideoInputEnabled(args.videoInputEnabled);

        videoNode.play();
        handleAudioStream(localStreamPreview, "local-video");
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
                    , args:
                        [ peerUserId === "local-video"
                            ? { tag: "local-video", args: [] }
                            : { tag: "is-connection", args: [ peerUserId ] }
                        , isSpeaking
                        ]
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
                    , args:
                        [ peerUserId === "local-video"
                            ? { tag: "local-video", args: [] }
                            : { tag: "is-connection", args: [ peerUserId ] }
                        , false
                        ]
                    });
            }
        }
    }
};

