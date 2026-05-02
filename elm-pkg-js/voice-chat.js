exports.init = async function init(app) {
    const connections = {};
    const pendingSignals = {};

    async function startConnection(peerUserId, shouldOffer) {
        // If a connection is already live, leave it alone. Tearing it down here
        // would generate fresh ICE credentials on our side while the peer keeps
        // theirs, which is exactly what produces "Unknown ufrag" errors.
        if (connections[peerUserId]) {
            console.warn("Voice chat: start ignored, connection already exists for", peerUserId);
            return;
        }

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

        const remoteAudio = document.getElementById(peerUserId);

        const conn = {
            pc: pc,
            localStream: localStream,
            remoteAudio: remoteAudio,
            // The peer that doesn't initially offer is the "polite" one and yields
            // when both peers offer simultaneously (perfect negotiation pattern).
            polite: !shouldOffer,
            makingOffer: false,
            ignoreOffer: false,
            remoteDescriptionSet: false,
            queuedIceCandidates: [],
            signalChain: Promise.resolve()
        };
        connections[peerUserId] = conn;

        localStream.getTracks().forEach(function (track) {
            pc.addTrack(track, localStream);
        });

        pc.ontrack = function (event) {
            console.log("Voice chat: ontrack", peerUserId, event.streams);
            if (event.streams && event.streams[0]) {
                remoteAudio.srcObject = event.streams[0];
            } else {
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
                    signal: { tag: "ice", args: [ event.candidate ] }
                });
            }
        };

        // Process any signals that arrived before this connection was created.
        const pending = pendingSignals[peerUserId] || [];
        delete pendingSignals[peerUserId];
        for (let i = 0; i < pending.length; i++) {
            await handleSignalInternal(conn, peerUserId, pending[i]);
        }

        if (shouldOffer && pc.signalingState === "stable") {
            try {
                conn.makingOffer = true;
                const offer = await pc.createOffer();
                // Re-check state: the peer may have raced an offer in while we awaited.
                if (pc.signalingState !== "stable") {
                    return;
                }
                await pc.setLocalDescription(offer);
                app.ports.voice_chat_from_js.send({
                    peerUserId: peerUserId,
                    signal: { tag: "offer", args: [ offer ] }
                });
            } catch (e) {
                console.error("Voice chat: failed to create offer", e);
            } finally {
                conn.makingOffer = false;
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
                if (!conn.ignoreOffer) {
                    // Stale candidates (e.g., ufrag mismatch after a glare/restart)
                    // are non-fatal — log at debug level and move on.
                    console.debug("Voice chat: queued ICE candidate ignored", peerUserId, e.message || e);
                }
            }
        }
    }

    async function handleSignalInternal(conn, peerUserId, signal) {
        const pc = conn.pc;
        try {
            if (signal.tag === "offer") {
                // Perfect negotiation glare handling: if we're already offering or
                // not in a state to accept a remote offer, the impolite peer ignores
                // the incoming offer and the polite peer rolls back to accept it.
                const offerCollision = conn.makingOffer || pc.signalingState !== "stable";
                conn.ignoreOffer = !conn.polite && offerCollision;
                if (conn.ignoreOffer) {
                    console.log("Voice chat: ignoring colliding offer (impolite)", peerUserId);
                    return;
                }
                await pc.setRemoteDescription({ type: "offer", sdp: signal.args[0].sdp });
                conn.remoteDescriptionSet = true;
                await drainQueuedIceCandidates(conn, peerUserId);
                const answer = await pc.createAnswer();
                await pc.setLocalDescription(answer);
                app.ports.voice_chat_from_js.send({
                    peerUserId: peerUserId,
                    signal: { tag: "answer", args: [ answer ] }
                });
            } else if (signal.tag === "answer") {
                if (pc.signalingState !== "have-local-offer") {
                    // We didn't send an offer (or already received the answer for it).
                    // Either way, applying this answer would throw "Cannot set remote
                    // answer in state ...". Skip it.
                    console.log("Voice chat: ignoring answer in state", pc.signalingState, peerUserId);
                    return;
                }
                await pc.setRemoteDescription({ type: "answer", sdp: signal.args[0].sdp });
                conn.remoteDescriptionSet = true;
                await drainQueuedIceCandidates(conn, peerUserId);
            } else if (signal.tag === "ice") {
                if (conn.remoteDescriptionSet) {
                    try {
                        await pc.addIceCandidate(signal.args[0]);
                    } catch (e) {
                        if (!conn.ignoreOffer) {
                            console.debug("Voice chat: ICE candidate ignored", peerUserId, e.message || e);
                        }
                    }
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
