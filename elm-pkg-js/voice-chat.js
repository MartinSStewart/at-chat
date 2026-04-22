exports.init = async function init(app) {
    const connections = {};
    const pendingSignals = {};

    async function startConnection(peerUserId, shouldOffer) {
        stopConnection(peerUserId);

        let localStream;
        try {
            localStream = await navigator.mediaDevices.getUserMedia({ audio: true, video: false });
        } catch (e) {
            console.error("Voice chat: failed to get microphone", e);
            return;
        }

        const pc = new RTCPeerConnection({
            iceServers: [{ urls: "stun:stun.l.google.com:19302" }]
        });

        localStream.getTracks().forEach(function (track) {
            pc.addTrack(track, localStream);
        });

        const remoteAudio = document.getElementById(peerUserId);

        pc.ontrack = function (event) {
            console.log("Voice chat: ontrack", peerUserId, event.streams);
            if (event.streams && event.streams[0]) {
                remoteAudio.srcObject = event.streams[0];
            } else {
                // Fallback: build a stream from the single track.
                const stream = new MediaStream();
                stream.addTrack(event.track);
                remoteAudio.srcObject = stream;
            }
            const playPromise = remoteAudio.play();
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
                app.ports.voice_chat_from_js.send({
                    peerUserId: peerUserId,
                    signal: JSON.stringify({ type: "ice", candidate: event.candidate })
                });
            }
        };

        const conn = {
            pc: pc,
            localStream: localStream,
            remoteAudio: remoteAudio,
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
                app.ports.voice_chat_from_js.send({
                    peerUserId: peerUserId,
                    signal: JSON.stringify({ type: "offer", sdp: offer })
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
        if (conn.pc) conn.pc.close();
        if (conn.remoteAudio) {
            conn.remoteAudio.srcObject = null;
            if (conn.remoteAudio.parentNode) {
                conn.remoteAudio.parentNode.removeChild(conn.remoteAudio);
            }
        }
        delete connections[peerUserId];
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

    async function handleSignalInternal(conn, peerUserId, signalStr) {
        try {
            const signal = JSON.parse(signalStr);
            if (signal.type === "offer") {
                await conn.pc.setRemoteDescription(signal.sdp);
                conn.remoteDescriptionSet = true;
                await drainQueuedIceCandidates(conn, peerUserId);
                const answer = await conn.pc.createAnswer();
                await conn.pc.setLocalDescription(answer);
                app.ports.voice_chat_from_js.send({
                    peerUserId: peerUserId,
                    signal: JSON.stringify({ type: "answer", sdp: answer })
                });
            } else if (signal.type === "answer") {
                await conn.pc.setRemoteDescription(signal.sdp);
                conn.remoteDescriptionSet = true;
                await drainQueuedIceCandidates(conn, peerUserId);
            } else if (signal.type === "ice") {
                if (conn.remoteDescriptionSet) {
                    await conn.pc.addIceCandidate(signal.candidate);
                } else {
                    conn.queuedIceCandidates.push(signal.candidate);
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

    app.ports.voice_chat_to_js.subscribe(async function (msg) {
        if (msg.kind === "start") {
            await startConnection(msg.peerUserId, msg.shouldOffer);
        } else if (msg.kind === "stop") {
            stopConnection(msg.peerUserId);
            delete pendingSignals[msg.peerUserId];
        } else if (msg.kind === "signal") {
            await handleSignal(msg.peerUserId, msg.signal);
        }
    });
};