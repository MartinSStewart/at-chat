port module VoiceChat exposing
    ( IceCandidate
    , SessionDescription
    , VoiceChatError
    , joinVoiceChat
    , leaveVoiceChat
    , onAnswer
    , onConnected
    , onDisconnected
    , onError
    , onIceCandidate
    , onOffer
    , receiveAnswer
    , receiveIceCandidate
    , setMuted
    , startVoiceChat
    , subscriptions
    )

import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
import Json.Decode
import Json.Encode



-- Outgoing ports (Elm → JS)


port voice_chat_start_to_js : Json.Encode.Value -> Cmd msg


port voice_chat_join_to_js : Json.Encode.Value -> Cmd msg


port voice_chat_receive_answer_to_js : Json.Encode.Value -> Cmd msg


port voice_chat_receive_ice_candidate_to_js : Json.Encode.Value -> Cmd msg


port voice_chat_leave_to_js : Json.Encode.Value -> Cmd msg


port voice_chat_set_muted_to_js : Json.Encode.Value -> Cmd msg



-- Incoming ports (JS → Elm)


port voice_chat_offer_from_js : (Json.Decode.Value -> msg) -> Sub msg


port voice_chat_answer_from_js : (Json.Decode.Value -> msg) -> Sub msg


port voice_chat_ice_candidate_from_js : (Json.Decode.Value -> msg) -> Sub msg


port voice_chat_connected_from_js : (Json.Decode.Value -> msg) -> Sub msg


port voice_chat_disconnected_from_js : (Json.Decode.Value -> msg) -> Sub msg


port voice_chat_error_from_js : (Json.Decode.Value -> msg) -> Sub msg



-- Types


type alias SessionDescription =
    { peerId : String
    , sdp : String
    }


type alias IceCandidate =
    { peerId : String
    , candidate : String
    }


type alias VoiceChatError =
    { peerId : String
    , error : String
    }



-- Commands (typed wrappers)


{-| Start a new voice chat session as the caller. This will request microphone
access, create an RTCPeerConnection, and generate an SDP offer. The offer is
returned via the `onOffer` subscription and should be sent to the remote peer
through your signaling channel (e.g. Lamdera ToBackend/ToFrontend messages).
-}
startVoiceChat : String -> Command FrontendOnly toMsg msg
startVoiceChat peerId =
    Command.sendToJs "voice_chat_start_to_js" voice_chat_start_to_js (Json.Encode.string peerId)


{-| Join an existing voice chat session as the callee. Pass in the SDP offer
received from the caller. This will request microphone access, create an
RTCPeerConnection, set the remote offer, and generate an SDP answer. The answer
is returned via the `onAnswer` subscription and should be sent back to the caller.
-}
joinVoiceChat : SessionDescription -> Command FrontendOnly toMsg msg
joinVoiceChat data =
    Command.sendToJs "voice_chat_join_to_js"
        voice_chat_join_to_js
        (encodeSessionDescription data)


{-| Provide the SDP answer received from the callee to the caller's
RTCPeerConnection. Call this on the caller side after receiving the answer
through signaling.
-}
receiveAnswer : SessionDescription -> Command FrontendOnly toMsg msg
receiveAnswer data =
    Command.sendToJs "voice_chat_receive_answer_to_js"
        voice_chat_receive_answer_to_js
        (encodeSessionDescription data)


{-| Forward an ICE candidate received from the remote peer. ICE candidates are
exchanged through signaling and added to the local RTCPeerConnection to
establish network connectivity.
-}
receiveIceCandidate : IceCandidate -> Command FrontendOnly toMsg msg
receiveIceCandidate data =
    Command.sendToJs "voice_chat_receive_ice_candidate_to_js"
        voice_chat_receive_ice_candidate_to_js
        (Json.Encode.object
            [ ( "peerId", Json.Encode.string data.peerId )
            , ( "candidate", Json.Encode.string data.candidate )
            ]
        )


{-| Leave a voice chat session. Closes the RTCPeerConnection, stops the local
media stream, and removes the remote audio element.
-}
leaveVoiceChat : String -> Command FrontendOnly toMsg msg
leaveVoiceChat peerId =
    Command.sendToJs "voice_chat_leave_to_js" voice_chat_leave_to_js (Json.Encode.string peerId)


{-| Mute or unmute the local microphone across all active voice chat sessions.
-}
setMuted : Bool -> Command FrontendOnly toMsg msg
setMuted muted =
    Command.sendToJs "voice_chat_set_muted_to_js" voice_chat_set_muted_to_js (Json.Encode.bool muted)



-- Subscriptions (typed wrappers)


{-| Fired when the local RTCPeerConnection has created an SDP offer (after
calling `startVoiceChat`). Send this offer to the remote peer through signaling.
-}
onOffer : (Result String SessionDescription -> msg) -> Subscription FrontendOnly msg
onOffer msg =
    Subscription.fromJs
        "voice_chat_offer_from_js"
        voice_chat_offer_from_js
        (\json ->
            Json.Decode.decodeValue sessionDescriptionDecoder json
                |> Result.mapError Json.Decode.errorToString
                |> msg
        )


{-| Fired when the local RTCPeerConnection has created an SDP answer (after
calling `joinVoiceChat`). Send this answer back to the caller through signaling.
-}
onAnswer : (Result String SessionDescription -> msg) -> Subscription FrontendOnly msg
onAnswer msg =
    Subscription.fromJs
        "voice_chat_answer_from_js"
        voice_chat_answer_from_js
        (\json ->
            Json.Decode.decodeValue sessionDescriptionDecoder json
                |> Result.mapError Json.Decode.errorToString
                |> msg
        )


{-| Fired when the local RTCPeerConnection generates an ICE candidate. Send
this candidate to the remote peer through signaling so they can call
`receiveIceCandidate`.
-}
onIceCandidate : (Result String IceCandidate -> msg) -> Subscription FrontendOnly msg
onIceCandidate msg =
    Subscription.fromJs
        "voice_chat_ice_candidate_from_js"
        voice_chat_ice_candidate_from_js
        (\json ->
            Json.Decode.decodeValue iceCandidateDecoder json
                |> Result.mapError Json.Decode.errorToString
                |> msg
        )


{-| Fired when the WebRTC peer connection transitions to the "connected" state,
meaning audio is now flowing.
-}
onConnected : (String -> msg) -> Subscription FrontendOnly msg
onConnected msg =
    Subscription.fromJs
        "voice_chat_connected_from_js"
        voice_chat_connected_from_js
        (\json ->
            Json.Decode.decodeValue Json.Decode.string json
                |> Result.withDefault ""
                |> msg
        )


{-| Fired when the WebRTC peer connection disconnects, fails, or is closed.
-}
onDisconnected : (String -> msg) -> Subscription FrontendOnly msg
onDisconnected msg =
    Subscription.fromJs
        "voice_chat_disconnected_from_js"
        voice_chat_disconnected_from_js
        (\json ->
            Json.Decode.decodeValue Json.Decode.string json
                |> Result.withDefault ""
                |> msg
        )


{-| Fired when an error occurs during any WebRTC operation (e.g. microphone
permission denied, connection failure).
-}
onError : (VoiceChatError -> msg) -> Subscription FrontendOnly msg
onError msg =
    Subscription.fromJs
        "voice_chat_error_from_js"
        voice_chat_error_from_js
        (\json ->
            Json.Decode.decodeValue voiceChatErrorDecoder json
                |> Result.withDefault { peerId = "", error = "Unknown error" }
                |> msg
        )


{-| Batch subscription for all voice chat events. Use this in your main
subscriptions function, mapping each event to the appropriate msg type.
-}
subscriptions :
    { onOffer : Result String SessionDescription -> msg
    , onAnswer : Result String SessionDescription -> msg
    , onIceCandidate : Result String IceCandidate -> msg
    , onConnected : String -> msg
    , onDisconnected : String -> msg
    , onError : VoiceChatError -> msg
    }
    -> Subscription FrontendOnly msg
subscriptions config =
    Subscription.batch
        [ onOffer config.onOffer
        , onAnswer config.onAnswer
        , onIceCandidate config.onIceCandidate
        , onConnected config.onConnected
        , onDisconnected config.onDisconnected
        , onError config.onError
        ]



-- JSON Encoders


encodeSessionDescription : SessionDescription -> Json.Encode.Value
encodeSessionDescription data =
    Json.Encode.object
        [ ( "peerId", Json.Encode.string data.peerId )
        , ( "sdp", Json.Encode.string data.sdp )
        ]



-- JSON Decoders


sessionDescriptionDecoder : Json.Decode.Decoder SessionDescription
sessionDescriptionDecoder =
    Json.Decode.map2 SessionDescription
        (Json.Decode.field "peerId" Json.Decode.string)
        (Json.Decode.field "sdp" Json.Decode.string)


iceCandidateDecoder : Json.Decode.Decoder IceCandidate
iceCandidateDecoder =
    Json.Decode.map2 IceCandidate
        (Json.Decode.field "peerId" Json.Decode.string)
        (Json.Decode.field "candidate" Json.Decode.string)


voiceChatErrorDecoder : Json.Decode.Decoder VoiceChatError
voiceChatErrorDecoder =
    Json.Decode.map2 VoiceChatError
        (Json.Decode.field "peerId" Json.Decode.string)
        (Json.Decode.field "error" Json.Decode.string)
