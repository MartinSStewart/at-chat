exports.init = async function init(app) {
    const connections = {};
    const pendingSignals = {};

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
            console.log("devices: ", devices);
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

        console.log("devices: ", devices);
        app.ports.voice_chat_from_js.send( { tag: "got-media-devices" , args: [ devices, defaultDevices ] });

        console.log("Voice chat: startConnection", peerUserId);
        //const remoteAudio = document.getElementById(peerUserId);
        const remoteVideo = document.getElementById(peerUserId);

        pc.ontrack = function (event) {
            console.log("Voice chat: ontrack", peerUserId, event.streams);


            if (event.streams && event.streams[0]) {
                remoteVideo.srcObject = event.streams[0];

            } else {
                // Fallback: build a stream from the single track.
                const stream = new MediaStream();
                stream.addTrack(event.track);
                remoteVideo.srcObject = stream;
            }
            const playPromise = remoteVideo.play();
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
            localStream: localStream,
            remoteAudio: remoteVideo,
            remoteDescriptionSet: false,
            queuedIceCandidates: [],
            signalChain: Promise.resolve()
        };
        connections[peerUserId] = conn;

        const pending = pendingSignals[peerUserId] || [];
        pendingSignals[peerUserId] = [];
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
        const conn = connections[peerUserId];
        if (!conn) return;
        if (conn.localStream) {
            conn.localStream.getTracks().forEach(function (track) { track.stop(); });
        }
        if (conn.pc) {
            conn.pc.ontrack = null;
            conn.pc.onnicecandidate = null;
            conn.pc.oniceconnectionstatechange = null;
            conn.pc.onsignalingstatechange = null;
            conn.pc.onicegatheringstatechange = null;
            conn.pc.onnotificationneeded = null;
            conn.pc.close();
        }
        if (conn.remoteAudio) {
            conn.remoteAudio.srcObject = null;
        }
        delete connections[peerUserId];
        delete pendingSignals[peerUserId];
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
        const conn = connections[peerUserId];
        if (!conn) {
            if (!pendingSignals[peerUserId]) pendingSignals[peerUserId] = [];
            pendingSignals[peerUserId].push(signalStr);
            return;
        }
        // Serialize signal processing per peer so offer/answer/ice never race.
        conn.signalChain = conn.signalChain.then(function () {
            return handleSignalInternal(conn, peerUserId, signalStr);
        });
    }

    function setAudioEnabled(enabled) {
        Object.values(connections).forEach(function (conn) {
            if (conn.localStream) {
                conn.localStream.getAudioTracks().forEach(function (track) {
                    track.enabled = enabled;
                });
            }
        });
    }

    function setVideoEnabled(enabled) {
        Object.values(connections).forEach(function (conn) {
            if (conn.localStream) {
                conn.localStream.getVideoTracks().forEach(function (track) {
                    track.enabled = enabled;
                });
            }
        });
    }

    app.ports.voice_chat_to_js.subscribe(async function (msg) {
        if (msg.kind === "start") {
            await startConnection(msg.peerUserId, msg.shouldOffer, msg.audioInput, msg.videoInput);
            setAudioEnabled(!msg.isMuted);
            setVideoEnabled(!msg.isVideoPaused);
        } else if (msg.kind === "stop") {
            stopConnection(msg.peerUserId);
        } else if (msg.kind === "signal") {
            await handleSignal(msg.peerUserId, msg.signal);
        } else if (msg.kind === "set-muted") {
            setAudioEnabled(!msg.muted);
        } else if (msg.kind === "set-video-paused") {
            setVideoEnabled(!msg.paused);
        } else if (msg.kind === "get-media-devices") {
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
};

