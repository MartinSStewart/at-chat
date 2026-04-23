port module VoiceChat exposing
    ( ConnectionId
    , LocalChange(..)
    , Model
    , RoomId(..)
    , ServerChange(..)
    , Signal
    , addSessionIdHash
    , audioNodes
    , changeUpdate
    , hasJoined
    , init
    , leaveVoiceChatCmds
    , localChangeUpdate
    , peerHasJoined
    , serverChangeCmd
    , voiceChatFromJs
    , voiceChatStart
    )

import Codec exposing (Codec)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
import Html exposing (Html)
import Html.Attributes
import Id exposing (Id, UserId)
import Json.Decode
import Json.Encode
import NonemptySet exposing (NonemptySet)
import SeqDict exposing (SeqDict)
import SeqSet
import SessionIdHash exposing (SessionIdHash)


type LocalChange
    = Local_Join RoomId
    | Local_Leave RoomId
    | Local_Signal ConnectionId Signal


type ServerChange
    = Server_Joined ConnectionId
    | Server_Left ConnectionId
    | Server_SignalReceived ConnectionId Signal


type alias Model =
    { currentRoom : Maybe RoomId, voiceChats : SeqDict RoomId (NonemptySet SessionIdHash) }


init : SeqDict RoomId (NonemptySet SessionIdHash) -> Model
init voiceChats =
    { currentRoom = Nothing
    , voiceChats = voiceChats
    }


type alias ConnectionId =
    { roomId : RoomId, otherSession : SessionIdHash }


type RoomId
    = DmRoomId (Id UserId)


type Signal
    = OfferSignal Sdp
    | AnswerSignal Sdp
    | IceSignal Ice


type alias Sdp =
    { sdp : String }


type alias Ice =
    { candidate : String, sdpMLineIndex : Int, sdpMid : String, usernameFragment : String }


signalCodec : Codec Signal
signalCodec =
    Codec.custom
        (\offerSignalEncoder answerSignalEncoder iceSignalEncoder value ->
            case value of
                OfferSignal a ->
                    offerSignalEncoder a

                AnswerSignal a ->
                    answerSignalEncoder a

                IceSignal a ->
                    iceSignalEncoder a
        )
        |> Codec.variant1 "offer" OfferSignal sdpCodec
        |> Codec.variant1 "answer" AnswerSignal sdpCodec
        |> Codec.variant1 "ice" IceSignal iceCodec
        |> Codec.buildCustom


sdpCodec : Codec Sdp
sdpCodec =
    Codec.object Sdp
        |> Codec.field "sdp" .sdp Codec.string
        |> Codec.buildObject


iceCodec : Codec Ice
iceCodec =
    Codec.object Ice
        |> Codec.field "candidate" .candidate Codec.string
        |> Codec.field "sdpMLineIndex" .sdpMLineIndex Codec.int
        |> Codec.field "sdpMid" .sdpMid Codec.string
        |> Codec.field "usernameFragment" .usernameFragment Codec.string
        |> Codec.buildObject


audioNodes : Model -> Html msg
audioNodes model =
    SeqDict.toList model.voiceChats
        |> List.concatMap
            (\( roomId, sessions ) ->
                if hasJoined roomId model then
                    List.map
                        (\session ->
                            Html.audio
                                [ connectionIdToString { roomId = roomId, otherSession = session } |> Html.Attributes.id
                                , Html.Attributes.autoplay True
                                , Html.Attributes.style "display" "none"
                                ]
                                []
                        )
                        (NonemptySet.toList sessions)

                else
                    []
            )
        |> Html.div []


hasJoined : RoomId -> Model -> Bool
hasJoined roomId model =
    model.currentRoom == Just roomId


leaveVoiceChatCmds : Model -> Command FrontendOnly toMsg msg
leaveVoiceChatCmds model =
    case model.currentRoom of
        Just currentRoom ->
            case SeqDict.get currentRoom model.voiceChats of
                Just voiceChat ->
                    NonemptySet.toList voiceChat
                        |> List.map (\sessionIdHash2 -> voiceChatStop { roomId = currentRoom, otherSession = sessionIdHash2 })
                        |> Command.batch

                Nothing ->
                    Command.none

        Nothing ->
            Command.none


peerHasJoined :
    RoomId
    ->
        { b
            | calls : Model
            , otherSessions : SeqDict SessionIdHash f
        }
    -> Bool
peerHasJoined otherUserId local =
    case SeqDict.get otherUserId local.calls.voiceChats of
        Just voiceChat ->
            SeqDict.foldl
                (\sessionId _ set -> SeqSet.remove sessionId set)
                (NonemptySet.toSeqSet voiceChat)
                local.otherSessions
                |> SeqSet.isEmpty
                |> not

        Nothing ->
            False


serverChangeCmd :
    ServerChange
    -> SessionIdHash
    -> Command FrontendOnly toBackend msg
serverChangeCmd change sessionIdHash =
    case change of
        Server_Joined connectionId ->
            voiceChatStart
                connectionId
                (SessionIdHash.toString sessionIdHash < SessionIdHash.toString connectionId.otherSession)

        Server_Left connectionId ->
            voiceChatStop connectionId

        Server_SignalReceived connectionId signal ->
            voiceChatDeliverSignal connectionId signal


addSessionIdHash :
    dmChannelId
    -> sessionId
    -> SeqDict dmChannelId (NonemptySet sessionId)
    -> SeqDict dmChannelId (NonemptySet sessionId)
addSessionIdHash otherUserId sessionIdHash dmVoiceChats =
    SeqDict.update
        otherUserId
        (\maybe ->
            case maybe of
                Just nonemptySet ->
                    NonemptySet.insert sessionIdHash nonemptySet |> Just

                Nothing ->
                    NonemptySet.singleton sessionIdHash |> Just
        )
        dmVoiceChats


removeSessionIdHash : RoomId -> SessionIdHash -> Model -> Model
removeSessionIdHash roomId sessionIdHash model =
    case SeqDict.get roomId model.voiceChats of
        Just dmVoiceChat ->
            { model
                | voiceChats =
                    SeqDict.update
                        roomId
                        (\_ -> NonemptySet.remove sessionIdHash dmVoiceChat |> NonemptySet.fromSeqSet)
                        model.voiceChats
            }

        Nothing ->
            model


localChangeUpdate : LocalChange -> Model -> Model
localChangeUpdate change model =
    case change of
        Local_Join roomId ->
            { model | currentRoom = Just roomId }

        Local_Leave roomId ->
            { model
                | currentRoom =
                    if Just roomId == model.currentRoom then
                        Nothing

                    else
                        model.currentRoom
            }

        Local_Signal _ _ ->
            model


changeUpdate : ServerChange -> { a | calls : Model } -> { a | calls : Model }
changeUpdate change local =
    case change of
        Server_Joined connectionId ->
            let
                calls : Model
                calls =
                    local.calls
            in
            { local
                | calls =
                    { calls
                        | voiceChats =
                            addSessionIdHash connectionId.roomId connectionId.otherSession calls.voiceChats
                    }
            }

        Server_Left connectionId ->
            { local | calls = removeSessionIdHash connectionId.roomId connectionId.otherSession local.calls }

        Server_SignalReceived _ _ ->
            local


port voice_chat_to_js : Json.Encode.Value -> Cmd msg


port voice_chat_from_js : (Json.Decode.Value -> msg) -> Sub msg


voiceChatStart : ConnectionId -> Bool -> Command FrontendOnly toBackend msg
voiceChatStart connectionId shouldOffer =
    Command.sendToJs
        "voice_chat_to_js"
        voice_chat_to_js
        (Json.Encode.object
            [ ( "kind", Json.Encode.string "start" )
            , ( "peerUserId", Codec.encoder connectionIdCodec connectionId )
            , ( "shouldOffer", Json.Encode.bool shouldOffer )
            ]
        )


voiceChatStop : ConnectionId -> Command FrontendOnly toBackend msg
voiceChatStop connectionId =
    Command.sendToJs
        "voice_chat_to_js"
        voice_chat_to_js
        (Json.Encode.object
            [ ( "kind", Json.Encode.string "stop" )
            , ( "peerUserId", Codec.encoder connectionIdCodec connectionId )
            ]
        )


voiceChatDeliverSignal : ConnectionId -> Signal -> Command FrontendOnly toBackend msg
voiceChatDeliverSignal connectionId signal =
    Command.sendToJs
        "voice_chat_to_js"
        voice_chat_to_js
        (Json.Encode.object
            [ ( "kind", Json.Encode.string "signal" )
            , ( "peerUserId", Codec.encoder connectionIdCodec connectionId )
            , ( "signal", Codec.encoder signalCodec signal )
            ]
        )


voiceChatFromJs : (ConnectionId -> Signal -> msg) -> Subscription FrontendOnly msg
voiceChatFromJs msg =
    Subscription.fromJs
        "voice_chat_from_js"
        voice_chat_from_js
        (\json ->
            Json.Decode.decodeValue
                (Json.Decode.map2 (\peerUserId signal -> msg peerUserId (Debug.log "signal" signal))
                    (Json.Decode.field "peerUserId" (Codec.decoder connectionIdCodec))
                    (Json.Decode.field "signal" (Codec.decoder signalCodec))
                )
                json
                |> Result.withDefault
                    (msg
                        { roomId = DmRoomId (Id.fromInt 0)
                        , otherSession = SessionIdHash.fromString ""
                        }
                        (OfferSignal { sdp = "" })
                    )
        )


connectionIdToString : ConnectionId -> String
connectionIdToString { roomId, otherSession } =
    (case roomId of
        DmRoomId otherUserId ->
            Id.toString otherUserId
    )
        ++ " "
        ++ SessionIdHash.toString otherSession


connectionIdCodec : Codec ConnectionId
connectionIdCodec =
    Codec.andThen
        (\text ->
            case String.split " " text of
                [ first, second ] ->
                    case String.toInt first of
                        Just int ->
                            Codec.succeed
                                { roomId = DmRoomId (Id.fromInt int)
                                , otherSession = SessionIdHash.fromString second
                                }

                        Nothing ->
                            Codec.fail ("Invalid connectionId: " ++ text)

                _ ->
                    Codec.fail ("Invalid connectionId: " ++ text)
        )
        connectionIdToString
        Codec.string
