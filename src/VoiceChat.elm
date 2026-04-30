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
    , joinedUsers
    , leaveVoiceChatCmds
    , serverChangeCmd
    , voiceChatFromJs
    , voiceChatStart
    )

import Codec exposing (Codec)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera as Lamdera exposing (ClientId)
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Time as Time
import Html exposing (Html)
import Html.Attributes
import Id exposing (Id, UserId)
import Json.Decode
import Json.Encode
import List.Nonempty exposing (Nonempty(..))
import NonemptySet exposing (NonemptySet)
import SeqDict exposing (SeqDict)
import SeqSet
import SessionIdHash exposing (SessionIdHash)


type LocalChange
    = Local_Join Time.Posix RoomId
    | Local_Leave Time.Posix
    | Local_Signal ConnectionId Signal


type ServerChange
    = Server_Joined ConnectionId
    | Server_Left ConnectionId
    | Server_SignalReceived ConnectionId Signal


type alias Model =
    { currentRoom : Maybe RoomId, voiceChats : SeqDict RoomId (NonemptySet ( Id UserId, ClientId )) }


init : SeqDict RoomId (NonemptySet ( Id UserId, ClientId )) -> Model
init voiceChats =
    { currentRoom = Nothing
    , voiceChats = voiceChats
    }


type alias ConnectionId =
    { roomId : RoomId, otherSession : ( Id UserId, ClientId ) }


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


joinedUsers : RoomId -> Model -> SeqDict (Id UserId) (NonemptySet ClientId)
joinedUsers roomId model =
    case SeqDict.get roomId model.voiceChats of
        Just voiceChat ->
            NonemptySet.foldl
                (\( userId, clientId ) dict ->
                    SeqDict.update
                        userId
                        (\maybe ->
                            case maybe of
                                Just nonempty ->
                                    NonemptySet.insert clientId nonempty |> Just

                                Nothing ->
                                    NonemptySet.singleton clientId |> Just
                        )
                        dict
                )
                SeqDict.empty
                voiceChat

        Nothing ->
            SeqDict.empty


serverChangeCmd : ServerChange -> ClientId -> Command FrontendOnly toBackend msg
serverChangeCmd change clientId =
    case change of
        Server_Joined connectionId ->
            voiceChatStart clientId connectionId

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


changeUpdate : ServerChange -> Model -> Model
changeUpdate change model =
    case change of
        Server_Joined connectionId ->
            { model
                | voiceChats =
                    addSessionIdHash connectionId.roomId connectionId.otherSession model.voiceChats
            }

        Server_Left { roomId, otherSession } ->
            case SeqDict.get roomId model.voiceChats of
                Just dmVoiceChat ->
                    { model
                        | voiceChats =
                            SeqDict.update
                                roomId
                                (\_ -> NonemptySet.remove otherSession dmVoiceChat |> NonemptySet.fromSeqSet)
                                model.voiceChats
                    }

                Nothing ->
                    model

        Server_SignalReceived _ _ ->
            model


port voice_chat_to_js : Json.Encode.Value -> Cmd msg


port voice_chat_from_js : (Json.Decode.Value -> msg) -> Sub msg


voiceChatStart : ClientId -> ConnectionId -> Command FrontendOnly toBackend msg
voiceChatStart clientId connectionId =
    let
        shouldOffer : Bool
        shouldOffer =
            Lamdera.clientIdToString clientId < Lamdera.clientIdToString (Tuple.second connectionId.otherSession)
    in
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
                        , otherSession = ( Id.fromInt 0, Lamdera.clientIdFromString "" )
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
        ++ Id.toString (Tuple.first otherSession)
        ++ " "
        ++ Lamdera.clientIdToString (Tuple.second otherSession)


connectionIdCodec : Codec ConnectionId
connectionIdCodec =
    Codec.andThen
        (\text ->
            case String.split " " text of
                [ first, second, third ] ->
                    case ( String.toInt first, String.toInt second ) of
                        ( Just int, Just userId ) ->
                            Codec.succeed
                                { roomId = DmRoomId (Id.fromInt int)
                                , otherSession = ( Id.fromInt userId, Lamdera.clientIdFromString third )
                                }

                        _ ->
                            Codec.fail ("Invalid connectionId: " ++ text)

                _ ->
                    Codec.fail ("Invalid connectionId: " ++ text)
        )
        connectionIdToString
        Codec.string
