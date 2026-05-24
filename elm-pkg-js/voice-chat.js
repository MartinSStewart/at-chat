exports.init = async function init(app) {
    // Single SFU connection. Cloudflare Realtime uses one RTCPeerConnection
    // per client; we publish our own tracks and subscribe to other
    // participants' tracks through transceivers on that one PC.
    let sfu = null;
    let localStreamPreview = null;

    // SFU state shape:
    //   pc: RTCPeerConnection
    //   localStream: MediaStream from getUserMedia
    //   audioMid / videoMid: transceiver MIDs we published
    //   pendingExistingPeers: peers from ToJs_StartCall, drained once publish completes
    //   peerSubs: Map<connectionIdKey, {
    //       connectionId,
    //       trackNames: string[],
    //       transceivers: RTCRtpTransceiver[],
    //       videoNode,
    //   }>
    //   pendingPullsByTrack: Map<trackName, connectionIdKey>  // for matching incoming tracks
    //   waitingForPublishAnswer: bool

    // The ConnectionId codec (Call.connectionIdCodec) encodes both fields as
    // strings: roomId = "<dmOtherUserId>" and otherClientId =
    // "<peerUserId> <peerClientId>". (They are NOT arrays.)
    function connectionKey(connectionId) {
        return connectionId.roomId + "|" + connectionId.otherClientId;
    }

    // Must match Call.connectionIdToString, which the <video> element's id is
    // built from: "<dmOtherUserId> <peerUserId> <peerClientId>".
    function peerVideoNodeId(connectionId) {
        return connectionId.roomId + " " + connectionId.otherClientId;
    }

    async function startCall(args) {
        await stopCall();

        let localStream;
        try {
            localStream = await getUserMedia(args);
            const devices = await navigator.mediaDevices.enumerateDevices();
            const defaultDevices = [];
            localStream.getTracks().forEach(function (track) {
                defaultDevices.push(track.getSettings().deviceId);
            });
            app.ports.voice_chat_from_js.send({ tag: "got-media-devices", args: [devices, defaultDevices] });
        } catch (e) {
            app.ports.voice_chat_from_js.send({ tag: "got-media-devices-error", args: [e.toString()] });
            return;
        }

        const pc = new RTCPeerConnection({ bundlePolicy: "max-bundle" });

        const audioTrack = localStream.getAudioTracks()[0];
        const videoTrack = localStream.getVideoTracks()[0];

        // Always create both transceivers (sendonly) so the SFU answer
        // includes m-lines for both, even if the user has no camera.
        const audioTransceiver = pc.addTransceiver(audioTrack || "audio", { direction: "sendonly" });
        // Cap outbound video bitrate. Without a cap the encoder ramps up to
        // fill whatever bandwidth it can, which can saturate a constrained
        // uplink (especially over a VPN, where the tunnel adds overhead) and
        // starve the Lamdera websocket until it drops. ~600 kbps is plenty for
        // the small call tiles and leaves headroom for the TCP signalling.
        const videoTransceiver = pc.addTransceiver(videoTrack || "video", {
            direction: "sendonly",
            sendEncodings: [{ maxBitrate: 600000 }],
        });

        sfu = {
            pc,
            localStream,
            audioTransceiver,
            videoTransceiver,
            audioMid: null,
            videoMid: null,
            pendingExistingPeers: args.existingPeers || [],
            peerSubs: new Map(),
            // Maps a transceiver mid -> peer connectionKey. Populated when we
            // apply a pull offer: the new recvonly transceivers in that offer
            // belong to the peer we're pulling. ontrack then routes each track
            // to the right peer by its transceiver mid (the "first unattached"
            // heuristic mis-routes once there's more than one remote track).
            midToPeer: new Map(),
            waitingForPublishAnswer: true,
            publishConnectedSent: false,
        };

        pc.oniceconnectionstatechange = function () {
            console.log("SFU iceConnectionState:", pc.iceConnectionState);
            maybeSignalPublishConnected();
        };
        pc.onconnectionstatechange = function () {
            console.log("SFU connectionState:", pc.connectionState);
            maybeSignalPublishConnected();
        };

        pc.ontrack = function (event) {
            const mid = event.transceiver ? event.transceiver.mid : null;
            console.log("SFU ontrack", event.track.kind, event.track.id, mid);
            attachTrackToPeer(event, mid != null ? sfu.midToPeer.get(mid) : undefined);
        };

        pc.onicecandidateerror = function (event) {
            console.log("SFU onicecandidateerror", {
                url: event.url,
                errorCode: event.errorCode,
                errorText: event.errorText,
            });
        };

        try {
            const offer = await pc.createOffer();
            await pc.setLocalDescription(offer);
            sfu.audioMid = audioTransceiver.mid;
            sfu.videoMid = videoTransceiver.mid;
            const mids = [audioTransceiver.mid, videoTransceiver.mid].filter((m) => m !== null);
            app.ports.voice_chat_from_js.send({
                tag: "publish-offer",
                args: [offer.sdp, mids],
            });
        } catch (e) {
            console.error("SFU createOffer failed", e);
            app.ports.voice_chat_from_js.send({ tag: "start-connection-error", args: [e.toString()] });
        }
    }

    async function applyPublishAnswer(answerSdp) {
        if (!sfu) return;
        try {
            await sfu.pc.setRemoteDescription({ type: "answer", sdp: answerSdp });
            sfu.waitingForPublishAnswer = false;
            // We do NOT pull peers here. Cloudflare rejects pulls until the
            // publisher's PC is connected and sending packets, so we wait for
            // the connection to come up (maybeSignalPublishConnected) and let
            // the backend drive pulls in both directions via Server_Joined.
            maybeSignalPublishConnected();
        } catch (e) {
            console.error("SFU setRemoteDescription(publish answer) failed", e);
        }
    }

    // Notify Elm once, when our publishing PeerConnection has actually
    // connected to Cloudflare. Only then are our tracks pullable by others
    // (and only then is it safe for us to pull others). The backend gates
    // all track-pull signalling on this.
    function maybeSignalPublishConnected() {
        if (!sfu || sfu.publishConnectedSent || sfu.waitingForPublishAnswer) return;
        const connected =
            sfu.pc.connectionState === "connected" ||
            sfu.pc.iceConnectionState === "connected" ||
            sfu.pc.iceConnectionState === "completed";
        if (connected) {
            sfu.publishConnectedSent = true;
            app.ports.voice_chat_from_js.send({ tag: "publish-connected", args: [] });
        }
    }

    function handlePeerJoined(args) {
        if (!sfu) return;
        // A new peer joined while we're in the call. Pull their tracks.
        app.ports.voice_chat_from_js.send({
            tag: "request-pull-tracks",
            args: [args.connectionId, args.sessionId, args.trackNames],
        });
    }

    async function applyPullOffer(args) {
        if (!sfu) return;
        const key = connectionKey(args.connectionId);

        // Register this peer's video element so ontrack can attach streams.
        if (!sfu.peerSubs.has(key)) {
            sfu.peerSubs.set(key, {
                connectionId: args.connectionId,
                videoNode: document.getElementById(peerVideoNodeId(args.connectionId)),
                stream: new MediaStream(),
            });
        }

        try {
            // The pull offer adds new recvonly transceivers for this peer's
            // tracks. We must record which mids belong to this peer BEFORE
            // applying the offer, because ontrack fires *during*
            // setRemoteDescription — if we waited until after, the mapping
            // wouldn't exist yet and tracks would be dropped ("no peer for
            // transceiver"). The mids are listed as `a=mid:<x>` in the SDP;
            // the ones we don't already know about are this peer's.
            const midsBefore = new Set(
                sfu.pc.getTransceivers().map((t) => t.mid).filter((m) => m != null)
            );
            const offerMids = (args.offerSdp.match(/a=mid:[^\r\n]+/g) || []).map((line) =>
                line.slice("a=mid:".length).trim()
            );
            for (const mid of offerMids) {
                if (!midsBefore.has(mid)) {
                    sfu.midToPeer.set(mid, key);
                }
            }
            await sfu.pc.setRemoteDescription({ type: "offer", sdp: args.offerSdp });
            // Backstop: also tag any newly-created transceivers we missed.
            for (const t of sfu.pc.getTransceivers()) {
                if (t.mid != null && !midsBefore.has(t.mid) && !sfu.midToPeer.has(t.mid)) {
                    sfu.midToPeer.set(t.mid, key);
                }
            }
            const answer = await sfu.pc.createAnswer();
            await sfu.pc.setLocalDescription(answer);
            app.ports.voice_chat_from_js.send({
                tag: "pull-answer",
                args: [args.connectionId, answer.sdp],
            });
        } catch (e) {
            console.error("SFU pull renegotiation failed", e);
        }
    }

    function attachTrackToPeer(event, key) {
        // Route the incoming track to the peer that owns the transceiver it
        // arrived on (recorded in applyPullOffer). Without this the audio and
        // video of different peers get mixed onto the wrong video elements.
        if (!sfu) return;

        const sub = key ? sfu.peerSubs.get(key) : undefined;
        if (!sub) {
            console.warn("SFU ontrack: no peer for transceiver", event.transceiver && event.transceiver.mid);
            return;
        }

        sub.stream.addTrack(event.track);
        // The Elm-rendered <video> may not have existed when we subscribed;
        // re-resolve it here (and keep the stream so it binds once it appears).
        if (!sub.videoNode || !sub.videoNode.isConnected) {
            sub.videoNode = document.getElementById(peerVideoNodeId(sub.connectionId));
        }
        if (sub.videoNode) {
            sub.videoNode.srcObject = sub.stream;
            const playPromise = sub.videoNode.play();
            if (playPromise && typeof playPromise.catch === "function") {
                playPromise.catch(function (err) {
                    console.error("SFU peer video play() rejected", err);
                });
            }
        }
        if (event.track.kind === "audio" && !audioStreams.has(key)) {
            handleAudioStream(sub.stream, key);
        }
    }

    function peerLeft(connectionId) {
        if (!sfu) return;
        const key = connectionKey(connectionId);
        const sub = sfu.peerSubs.get(key);
        if (sub) {
            if (sub.videoNode) {
                sub.videoNode.srcObject = null;
            }
            sub.stream.getTracks().forEach((t) => t.stop());
            sfu.peerSubs.delete(key);
            removeAudioStream(key);
        }
        // Drop any mid->peer mappings for this peer.
        for (const [mid, peerKey] of [...sfu.midToPeer.entries()]) {
            if (peerKey === key) sfu.midToPeer.delete(mid);
        }
    }

    async function stopCall() {
        if (!sfu) return;
        try {
            sfu.pc.getSenders().forEach((s) => {
                if (s.track) s.track.stop();
            });
            sfu.pc.close();
        } catch (e) {
            console.error("SFU stop failed", e);
        }
        for (const [key, sub] of sfu.peerSubs.entries()) {
            if (sub.videoNode) sub.videoNode.srcObject = null;
            sub.stream.getTracks().forEach((t) => t.stop());
            removeAudioStream(key);
        }
        if (sfu.localStream) {
            sfu.localStream.getTracks().forEach((t) => t.stop());
        }
        sfu = null;
    }

    function setAudioInputEnabled(enabled) {
        if (sfu && sfu.localStream) {
            sfu.localStream.getAudioTracks().forEach((t) => {
                t.enabled = enabled;
            });
        }
        if (localStreamPreview) {
            localStreamPreview.getAudioTracks().forEach((t) => {
                t.enabled = enabled;
            });
        }
    }

    function setVideoInputEnabled(enabled) {
        if (sfu && sfu.localStream) {
            sfu.localStream.getVideoTracks().forEach((t) => {
                t.enabled = enabled;
            });
        }
        if (localStreamPreview) {
            localStreamPreview.getVideoTracks().forEach((t) => {
                t.enabled = enabled;
            });
        }
    }

    async function setInput(isAudioInput, deviceId) {
        const config = isAudioInput
            ? { audio: { deviceId: { exact: deviceId } } }
            : { video: { deviceId: { exact: deviceId } } };
        const stream = await navigator.mediaDevices.getUserMedia(config);
        const tracks = isAudioInput ? stream.getAudioTracks() : stream.getVideoTracks();
        const track = tracks[0];
        if (sfu) {
            const transceiver = isAudioInput ? sfu.audioTransceiver : sfu.videoTransceiver;
            const sender = transceiver && transceiver.sender;
            if (sender) {
                const oldTrack = sender.track;
                if (oldTrack) {
                    track.enabled = oldTrack.enabled;
                    oldTrack.stop();
                }
                await sender.replaceTrack(track);
            }
        }
    }

    app.ports.voice_chat_to_js.subscribe(async function (msg) {
        if (msg.tag === "start-call") {
            const args = msg.args[0];
            await startCall(args);
            setAudioInputEnabled(args.audioInputEnabled);
            setVideoInputEnabled(args.videoInputEnabled);
        } else if (msg.tag === "leave-call") {
            await stopCall();
        } else if (msg.tag === "publish-answer") {
            await applyPublishAnswer(msg.args[0].answerSdp);
        } else if (msg.tag === "peer-joined") {
            handlePeerJoined(msg.args[0]);
        } else if (msg.tag === "peer-left") {
            peerLeft(msg.args[0]);
        } else if (msg.tag === "accept-pull-offer") {
            await applyPullOffer(msg.args[0]);
        } else if (msg.tag === "set-audio-input-enabled") {
            setAudioInputEnabled(msg.args[0]);
        } else if (msg.tag === "set-input") {
            await setInput(msg.args[0], msg.args[1]);
        } else if (msg.tag === "set-video-input-enabled") {
            setVideoInputEnabled(msg.args[0]);
        } else if (msg.tag === "set-volume") {
            const sub = sfu && sfu.peerSubs.get(connectionKey(msg.args[0]));
            if (sub && sub.videoNode) {
                sub.videoNode.volume = msg.args[1];
            }
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
        if (localStreamPreview) {
            localStreamPreview.getTracks().forEach((s) => s.stop());
        }
        if (videoNode) {
            if (videoNode.srcObject) {
                videoNode.srcObject.getTracks().forEach((s) => s.stop());
            }
            videoNode.srcObject = null;
        }
        localStreamPreview = null;
        removeAudioStream("local-video");
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

        const videoNode = document.getElementById("local-video");
        // iOS Safari ignores HTMLMediaElement.volume so use muted + only feed
        // the video tracks into the preview element so the mic doesn't echo.
        videoNode.muted = true;
        const previewStream = new MediaStream();
        localStreamPreview.getVideoTracks().forEach((track) => {
            previewStream.addTrack(track);
        });
        videoNode.srcObject = previewStream;

        setAudioInputEnabled(args.audioInputEnabled);
        setVideoInputEnabled(args.videoInputEnabled);

        const playPromise = videoNode.play();
        if (playPromise && typeof playPromise.catch === "function") {
            playPromise.catch((err) => {
                console.error("local-video: play() rejected", err);
            });
        }
        handleAudioStream(localStreamPreview, "local-video");
    }

    // ------------------------------------------------------------------
    // Active speaker detection (unchanged from the P2P implementation).
    // Original technique: https://www.linkedin.com/pulse/webrtc-active-speaker-detection-nilesh-gawande
    // ------------------------------------------------------------------
    const VOLUME_THRESHOLD = 20;
    const AUDIO_WINDOW_SIZE = 256;
    const audioStreams = new Map();

    function handleAudioStream(stream, key) {
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
            stopped: false,
        };
        audioStreams.set(key, entry);

        function processAudio() {
            if (entry.stopped) return;
            analyserNode.getByteFrequencyData(dataArray);
            const averageVolume = dataArray.reduce((acc, val) => acc + val, 0) / bufferLength;
            const isSpeaking = averageVolume > VOLUME_THRESHOLD;
            if (isSpeaking !== entry.isSpeaking) {
                entry.isSpeaking = isSpeaking;
                const speakerArg =
                    key === "local-video"
                        ? { tag: "local-video", args: [] }
                        : { tag: "is-connection", args: [connectionIdFromKey(key)] };
                app.ports.voice_chat_from_js.send({
                    tag: "is-speaking-changed",
                    args: [speakerArg, isSpeaking],
                });
            }
            requestAnimationFrame(processAudio);
        }

        processAudio();
    }

    function connectionIdFromKey(key) {
        // peerSubs key → ConnectionId structure. Best-effort lookup.
        if (!sfu) return null;
        const sub = sfu.peerSubs.get(key);
        return sub ? sub.connectionId : null;
    }

    function removeAudioStream(key) {
        const streamData = audioStreams.get(key);
        if (streamData) {
            streamData.stopped = true;
            try { streamData.mediaStreamSource.disconnect(); } catch (e) {}
            try { streamData.analyserNode.disconnect(); } catch (e) {}
            try { streamData.audioContext.close(); } catch (e) {}
            audioStreams.delete(key);
            if (streamData.isSpeaking) {
                const speakerArg =
                    key === "local-video"
                        ? { tag: "local-video", args: [] }
                        : { tag: "is-connection", args: [connectionIdFromKey(key)] };
                app.ports.voice_chat_from_js.send({
                    tag: "is-speaking-changed",
                    args: [speakerArg, false],
                });
            }
        }
    }
};
