port module VoiceChat exposing
    ( ConnectionId
    , LocalChange(..)
    , Model
    , RoomId(..)
    , ServerChange(..)
    , addSessionIdHash
    , audioNodes
    , changeUpdate
    , hasJoined
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
    | Local_Signal ConnectionId String


type ServerChange
    = Server_Joined ConnectionId
    | Server_Left ConnectionId
    | Server_SignalReceived ConnectionId String


type alias Model =
    { voiceChats : SeqDict RoomId (NonemptySet SessionIdHash) }


type alias ConnectionId =
    { roomId : RoomId, otherSession : SessionIdHash }


type RoomId
    = DmRoomId (Id UserId)


audioNodes :
    { b
        | calls : Model
        , localUser : { d | session : { e | sessionIdHash : SessionIdHash } }
    }
    -> Html msg
audioNodes local =
    SeqDict.toList local.calls.voiceChats
        |> List.concatMap
            (\( roomId, sessions ) ->
                if hasJoined roomId local then
                    NonemptySet.remove local.localUser.session.sessionIdHash sessions
                        |> SeqSet.toList
                        |> List.map
                            (\session ->
                                Html.audio
                                    [ connectionIdToString { roomId = roomId, otherSession = session } |> Html.Attributes.id
                                    , Html.Attributes.autoplay True
                                    , Html.Attributes.style "display" "none"
                                    ]
                                    []
                            )

                else
                    []
            )
        |> Html.div []


hasJoined :
    RoomId
    ->
        { b
            | calls : Model
            , localUser : { d | session : { e | sessionIdHash : SessionIdHash } }
        }
    -> Bool
hasJoined roomId local =
    case SeqDict.get roomId local.calls.voiceChats of
        Just voiceChat ->
            NonemptySet.member local.localUser.session.sessionIdHash voiceChat

        Nothing ->
            False


leaveVoiceChatCmds : RoomId -> SessionIdHash -> Model -> Command FrontendOnly toMsg msg
leaveVoiceChatCmds voiceChatId sessionIdHash model =
    case SeqDict.get voiceChatId model.voiceChats of
        Just voiceChat ->
            NonemptySet.remove sessionIdHash voiceChat
                |> SeqSet.toList
                |> List.map (\sessionIdHash2 -> voiceChatStop { roomId = voiceChatId, otherSession = sessionIdHash2 })
                |> Command.batch

        Nothing ->
            Command.none


peerHasJoined :
    RoomId
    ->
        { b
            | calls : Model
            , localUser : { d | session : { e | sessionIdHash : SessionIdHash } }
            , otherSessions : SeqDict SessionIdHash f
        }
    -> Bool
peerHasJoined otherUserId local =
    case SeqDict.get otherUserId local.calls.voiceChats of
        Just voiceChat ->
            SeqDict.foldl
                (\sessionId _ set ->
                    SeqSet.remove sessionId set
                )
                (NonemptySet.remove local.localUser.session.sessionIdHash voiceChat)
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
            let
                voiceChatParticipants2 =
                    NonemptySet.remove sessionIdHash dmVoiceChat
                        |> NonemptySet.fromSeqSet
            in
            { model
                | voiceChats = SeqDict.update roomId (\_ -> voiceChatParticipants2) model.voiceChats
            }

        Nothing ->
            model


localChangeUpdate : LocalChange -> SessionIdHash -> { a | calls : Model } -> { a | calls : Model }
localChangeUpdate change sessionIdHash local =
    case change of
        Local_Join roomId ->
            let
                calls : Model
                calls =
                    local.calls
            in
            { local | calls = { calls | voiceChats = addSessionIdHash roomId sessionIdHash calls.voiceChats } }

        Local_Leave roomId ->
            { local | calls = removeSessionIdHash roomId sessionIdHash local.calls }

        Local_Signal _ _ ->
            local


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


voiceChatDeliverSignal : ConnectionId -> String -> Command FrontendOnly toBackend msg
voiceChatDeliverSignal connectionId signal =
    Command.sendToJs
        "voice_chat_to_js"
        voice_chat_to_js
        (Json.Encode.object
            [ ( "kind", Json.Encode.string "signal" )
            , ( "peerUserId", Codec.encoder connectionIdCodec connectionId )
            , ( "signal", Json.Encode.string signal )
            ]
        )


voiceChatFromJs : (ConnectionId -> String -> msg) -> Subscription FrontendOnly msg
voiceChatFromJs msg =
    Subscription.fromJs
        "voice_chat_from_js"
        voice_chat_from_js
        (\json ->
            Json.Decode.decodeValue
                (Json.Decode.map2 (\peerUserId signal -> msg peerUserId signal)
                    (Json.Decode.field "peerUserId" (Codec.decoder connectionIdCodec))
                    (Json.Decode.field "signal" Json.Decode.string)
                )
                json
                |> Result.withDefault
                    (msg
                        { roomId = DmRoomId (Id.fromInt 0)
                        , otherSession = SessionIdHash.fromString ""
                        }
                        ""
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
