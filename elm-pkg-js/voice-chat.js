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

        const remoteAudio = new Audio();
        remoteAudio.autoplay = true;

        pc.ontrack = function (event) {
            remoteAudio.srcObject = event.streams[0];
        };

        pc.onicecandidate = function (event) {
            if (event.candidate) {
                app.ports.voice_chat_from_js.send({
                    peerUserId: peerUserId,
                    signal: JSON.stringify({ type: "ice", candidate: event.candidate })
                });
            }
        };

        const conn = { pc: pc, localStream: localStream, remoteAudio: remoteAudio };
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
        if (conn.remoteAudio) conn.remoteAudio.srcObject = null;
        delete connections[peerUserId];
    }

    async function handleSignalInternal(conn, peerUserId, signalStr) {
        try {
            const signal = JSON.parse(signalStr);
            if (signal.type === "offer") {
                await conn.pc.setRemoteDescription(signal.sdp);
                const answer = await conn.pc.createAnswer();
                await conn.pc.setLocalDescription(answer);
                app.ports.voice_chat_from_js.send({
                    peerUserId: peerUserId,
                    signal: JSON.stringify({ type: "answer", sdp: answer })
                });
            } else if (signal.type === "answer") {
                await conn.pc.setRemoteDescription(signal.sdp);
            } else if (signal.type === "ice") {
                await conn.pc.addIceCandidate(signal.candidate);
            }
        } catch (e) {
            console.error("Voice chat: failed to handle signal", e);
        }
    }

    async function handleSignal(peerUserId, signalStr) {
        const conn = connections[peerUserId];
        if (!conn) {
            if (!pendingSignals[peerUserId]) pendingSignals[peerUserId] = [];
            pendingSignals[peerUserId].push(signalStr);
            return;
        }
        await handleSignalInternal(conn, peerUserId, signalStr);
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