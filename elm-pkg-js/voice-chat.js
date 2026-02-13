exports.init = async function (app) {
  // Map of peerId -> { pc: RTCPeerConnection, localStream: MediaStream }
  var sessions = {};

  var ICE_SERVERS = [
    { urls: "stun:stun.l.google.com:19302" },
    { urls: "stun:stun1.l.google.com:19302" },
  ];

  function getLocalStream() {
    return navigator.mediaDevices.getUserMedia({ audio: true, video: false });
  }

  function cleanupSession(peerId) {
    var session = sessions[peerId];
    if (!session) {
      return;
    }

    if (session.pc) {
      session.pc.close();
    }

    if (session.localStream) {
      session.localStream.getTracks().forEach(function (track) {
        track.stop();
      });
    }

    var audio = document.getElementById("voice-chat-remote-" + peerId);
    if (audio) {
      audio.srcObject = null;
      audio.remove();
    }

    delete sessions[peerId];
  }

  function setupPeerConnection(peerId) {
    var pc = new RTCPeerConnection({ iceServers: ICE_SERVERS });

    pc.onicecandidate = function (event) {
      if (event.candidate) {
        app.ports.voice_chat_ice_candidate_from_js.send({
          peerId: peerId,
          candidate: JSON.stringify(event.candidate),
        });
      }
    };

    pc.onconnectionstatechange = function () {
      if (pc.connectionState === "connected") {
        app.ports.voice_chat_connected_from_js.send(peerId);
      } else if (
        pc.connectionState === "disconnected" ||
        pc.connectionState === "failed" ||
        pc.connectionState === "closed"
      ) {
        app.ports.voice_chat_disconnected_from_js.send(peerId);
      }
    };

    pc.ontrack = function (event) {
      // Remove any existing audio element for this peer
      var existing = document.getElementById("voice-chat-remote-" + peerId);
      if (existing) {
        existing.srcObject = null;
        existing.remove();
      }

      var audio = document.createElement("audio");
      audio.id = "voice-chat-remote-" + peerId;
      audio.autoplay = true;
      audio.srcObject = event.streams[0];
      // Hidden element, audio only
      audio.style.display = "none";
      document.body.appendChild(audio);
    };

    return pc;
  }

  // Start a voice chat session as the caller.
  // Creates an RTCPeerConnection, captures microphone audio, creates an SDP
  // offer, and sends it back to Elm so it can be relayed to the remote peer
  // via signaling.
  app.ports.voice_chat_start_to_js.subscribe(function (peerId) {
    // Clean up any existing session for this peer
    cleanupSession(peerId);

    getLocalStream()
      .then(function (stream) {
        var pc = setupPeerConnection(peerId);

        sessions[peerId] = { pc: pc, localStream: stream };

        stream.getTracks().forEach(function (track) {
          pc.addTrack(track, stream);
        });

        return pc.createOffer().then(function (offer) {
          return pc.setLocalDescription(offer).then(function () {
            app.ports.voice_chat_offer_from_js.send({
              peerId: peerId,
              sdp: JSON.stringify(offer),
            });
          });
        });
      })
      .catch(function (error) {
        app.ports.voice_chat_error_from_js.send({
          peerId: peerId,
          error: error.message || "Failed to start voice chat",
        });
      });
  });

  // Join an existing voice chat session as the callee.
  // Takes an SDP offer from the caller, captures microphone audio, creates an
  // RTCPeerConnection, sets the remote offer, creates an SDP answer, and sends
  // it back to Elm to be relayed to the caller via signaling.
  app.ports.voice_chat_join_to_js.subscribe(function (data) {
    // Clean up any existing session for this peer
    cleanupSession(data.peerId);

    getLocalStream()
      .then(function (stream) {
        var pc = setupPeerConnection(data.peerId);

        sessions[data.peerId] = { pc: pc, localStream: stream };

        stream.getTracks().forEach(function (track) {
          pc.addTrack(track, stream);
        });

        var offer = JSON.parse(data.sdp);
        return pc
          .setRemoteDescription(new RTCSessionDescription(offer))
          .then(function () {
            return pc.createAnswer();
          })
          .then(function (answer) {
            return pc.setLocalDescription(answer).then(function () {
              app.ports.voice_chat_answer_from_js.send({
                peerId: data.peerId,
                sdp: JSON.stringify(answer),
              });
            });
          });
      })
      .catch(function (error) {
        app.ports.voice_chat_error_from_js.send({
          peerId: data.peerId,
          error: error.message || "Failed to join voice chat",
        });
      });
  });

  // Set the remote SDP answer on the caller's RTCPeerConnection.
  // Called after the callee's answer arrives through signaling.
  app.ports.voice_chat_receive_answer_to_js.subscribe(function (data) {
    var session = sessions[data.peerId];
    if (!session || !session.pc) {
      return;
    }

    var answer = JSON.parse(data.sdp);
    session.pc
      .setRemoteDescription(new RTCSessionDescription(answer))
      .catch(function (error) {
        app.ports.voice_chat_error_from_js.send({
          peerId: data.peerId,
          error: error.message || "Failed to process answer",
        });
      });
  });

  // Add a remote ICE candidate to the local RTCPeerConnection.
  // Called when an ICE candidate arrives from the remote peer through signaling.
  app.ports.voice_chat_receive_ice_candidate_to_js.subscribe(function (data) {
    var session = sessions[data.peerId];
    if (!session || !session.pc) {
      return;
    }

    var candidate = JSON.parse(data.candidate);
    session.pc.addIceCandidate(new RTCIceCandidate(candidate)).catch(function (error) {
      app.ports.voice_chat_error_from_js.send({
        peerId: data.peerId,
        error: error.message || "Failed to add ICE candidate",
      });
    });
  });

  // Leave a voice chat session.
  // Closes the RTCPeerConnection, stops the local media stream, and removes
  // the remote audio element.
  app.ports.voice_chat_leave_to_js.subscribe(function (peerId) {
    cleanupSession(peerId);
  });

  // Mute or unmute the local microphone across all active sessions.
  app.ports.voice_chat_set_muted_to_js.subscribe(function (muted) {
    Object.keys(sessions).forEach(function (peerId) {
      var session = sessions[peerId];
      if (session && session.localStream) {
        session.localStream.getAudioTracks().forEach(function (track) {
          track.enabled = !muted;
        });
      }
    });
  });
};
