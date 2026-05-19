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

    function connectionKey(connectionId) {
        // ConnectionId codec produces { roomId, otherClientId: [userId, clientId] }
        const [userId, clientId] = connectionId.otherClientId;
        return userId + "|" + clientId;
    }

    function peerVideoNodeId(connectionId) {
        const [userId, clientId] = connectionId.otherClientId;
        return userId + " " + clientId;
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
        const videoTransceiver = pc.addTransceiver(videoTrack || "video", { direction: "sendonly" });

        sfu = {
            pc,
            localStream,
            audioTransceiver,
            videoTransceiver,
            audioMid: null,
            videoMid: null,
            pendingExistingPeers: args.existingPeers || [],
            peerSubs: new Map(),
            waitingForPublishAnswer: true,
        };

        pc.oniceconnectionstatechange = function () {
            console.log("SFU iceConnectionState:", pc.iceConnectionState);
        };
        pc.onconnectionstatechange = function () {
            console.log("SFU connectionState:", pc.connectionState);
        };

        pc.ontrack = function (event) {
            console.log("SFU ontrack", event.track.kind, event.track.id, event.transceiver && event.transceiver.mid);
            attachTrackToPeer(event);
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

            // Now drain pending pulls for existing peers.
            for (const peer of sfu.pendingExistingPeers) {
                app.ports.voice_chat_from_js.send({
                    tag: "request-pull-tracks",
                    args: [peer.connectionId, peer.sessionId, peer.trackNames],
                });
            }
            sfu.pendingExistingPeers = [];
        } catch (e) {
            console.error("SFU setRemoteDescription(publish answer) failed", e);
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
                trackNames: [],
                videoNode: document.getElementById(peerVideoNodeId(args.connectionId)),
                stream: new MediaStream(),
            });
        }

        try {
            await sfu.pc.setRemoteDescription({ type: "offer", sdp: args.offerSdp });
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

    function attachTrackToPeer(event) {
        // The new transceiver carries one peer's audio or video. We rely on
        // ontrack's event.streams or event.track to attach to *some* peer.
        // Cloudflare returns one transceiver per pulled track. We don't get
        // peer identity directly from ontrack; the simplest approach is to
        // attach the first not-yet-attached track of each kind to the most
        // recently subscribed peer that's missing that kind. This is
        // imperfect for >1 simultaneous subscribes but works for typical
        // 1:1 calls.
        if (!sfu) return;

        // Find a peer subscription that doesn't yet have this track kind.
        let target = null;
        for (const sub of sfu.peerSubs.values()) {
            const has =
                event.track.kind === "audio"
                    ? sub.stream.getAudioTracks().length > 0
                    : sub.stream.getVideoTracks().length > 0;
            if (!has) {
                target = sub;
                break;
            }
        }
        if (!target) return;

        target.stream.addTrack(event.track);
        if (target.videoNode) {
            target.videoNode.srcObject = target.stream;
            const playPromise = target.videoNode.play();
            if (playPromise && typeof playPromise.catch === "function") {
                playPromise.catch(function (err) {
                    console.error("SFU peer video play() rejected", err);
                });
            }
        }
        if (event.track.kind === "audio") {
            const key = connectionKeyFromSub(target);
            if (key && !audioStreams.has(key)) {
                handleAudioStream(target.stream, key);
            }
        }
    }

    function connectionKeyFromSub(sub) {
        if (!sub || !sub.connectionId) return null;
        return connectionKey(sub.connectionId);
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
