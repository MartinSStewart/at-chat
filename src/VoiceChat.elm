port module VoiceChat exposing
    ( AudioTrackData
    , ConnectionId
    , DeviceKind(..)
    , Ice
    , LocalChange(..)
    , MediaDevices
    , MediaDevicesStatus(..)
    , Model
    , RoomId(..)
    , Sdp
    , ServerChange(..)
    , Signal(..)
    , Track(..)
    , VideoTrackData
    , VoiceChatSubscription(..)
    , addSessionIdHash
    , audioNodes
    , getMediaDevices
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
import NonemptySet exposing (NonemptySet)
import SeqDict exposing (SeqDict)


type LocalChange
    = Local_Join Time.Posix RoomId
    | Local_Leave Time.Posix
    | Local_Signal ConnectionId Signal


type ServerChange
    = Server_Joined Time.Posix ConnectionId
    | Server_Left Time.Posix ConnectionId
    | Server_SignalReceived ConnectionId Signal


type alias Model =
    { currentRoom : Maybe RoomId
    , voiceChats : SeqDict RoomId (NonemptySet ( Id UserId, ClientId ))
    }


type MediaDevicesStatus
    = MediaDevicesNotLoaded
    | HasMediaDevices (List MediaDevices)
    | FailedToGetMediaDevices String


init : SeqDict RoomId (NonemptySet ( Id UserId, ClientId )) -> Model
init voiceChats =
    { currentRoom = Nothing
    , voiceChats = voiceChats
    }


type alias ConnectionId =
    { roomId : RoomId, otherSession : ( Id UserId, ClientId ) }


type RoomId
    = DmRoomId (Id UserId)


{-| OpaqueVariants
-}
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
                    List.concatMap
                        (\session ->
                            [ Html.video
                                [ Html.Attributes.style "width" "300px"
                                , Html.Attributes.style "height" "200px"
                                , (connectionIdToString { roomId = roomId, otherSession = session } ++ " video") |> Html.Attributes.id
                                , Html.Attributes.style "background-color" "rgba(0,0,0,0.4)"
                                ]
                                []
                            ]
                        )
                        (NonemptySet.toList sessions)

                else
                    []
            )
        |> Html.div []


type Track
    = VideoTrack VideoTrackData
    | AudioTrack AudioTrackData


trackCodec : Codec Track
trackCodec =
    Codec.custom
        (\aEncoder bEncoder value ->
            case value of
                VideoTrack a ->
                    aEncoder a

                AudioTrack a ->
                    bEncoder a
        )
        |> Codec.variant1 "video" VideoTrack videoTrackCodec
        |> Codec.variant1 "audio" AudioTrack audioTrackCodec
        |> Codec.buildCustom


type alias VideoTrackData =
    { deviceId : String
    , frameRate : Int
    , groupId : String
    , width : Int
    , height : Int
    , resizeMode : String
    }


type alias AudioTrackData =
    { deviceId : String
    , autoGainControl : Bool
    , groupId : String
    , channelCount : Int
    , echoCancellation : Bool
    , noiseSuppression : Bool
    }


audioTrackCodec : Codec AudioTrackData
audioTrackCodec =
    Codec.object AudioTrackData
        |> Codec.field "deviceId" .deviceId Codec.string
        |> Codec.field "autoGainControl" .autoGainControl Codec.bool
        |> Codec.field "groupId" .groupId Codec.string
        |> Codec.field "channelCount" .channelCount Codec.int
        |> Codec.field "echoCancellation" .echoCancellation Codec.bool
        |> Codec.field "noiseSuppression" .noiseSuppression Codec.bool
        |> Codec.buildObject


videoTrackCodec : Codec VideoTrackData
videoTrackCodec =
    Codec.object VideoTrackData
        |> Codec.field "deviceId" .deviceId Codec.string
        |> Codec.field "frameRate" .frameRate Codec.int
        |> Codec.field "groupId" .groupId Codec.string
        |> Codec.field "width" .width Codec.int
        |> Codec.field "height" .height Codec.int
        |> Codec.field "resizeMode" .resizeMode Codec.string
        |> Codec.buildObject


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


serverChangeCmd : ServerChange -> ClientId -> Model -> Command FrontendOnly toBackend msg
serverChangeCmd change clientId model =
    case change of
        Server_Joined _ connectionId ->
            case model.currentRoom of
                Just roomId ->
                    if roomId == connectionId.roomId then
                        voiceChatStart clientId connectionId

                    else
                        Command.none

                Nothing ->
                    Command.none

        Server_Left _ connectionId ->
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


port voice_chat_to_js : Json.Encode.Value -> Cmd msg


port voice_chat_from_js : (Json.Decode.Value -> msg) -> Sub msg


getMediaDevices : Command FrontendOnly toBackend msg
getMediaDevices =
    Command.sendToJs
        "voice_chat_to_js"
        voice_chat_to_js
        (Json.Encode.object
            [ ( "kind", Json.Encode.string "get-media-devices" )
            ]
        )


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


type VoiceChatSubscription
    = GotSignal ConnectionId Signal
    | GotMediaStreamTracks (List Track)
    | GotUserMediaDevices (List MediaDevices)
    | GotUserMediaDevicesError String


voiceChatSubscriptionCodec : Codec VoiceChatSubscription
voiceChatSubscriptionCodec =
    Codec.custom
        (\aEncoder bEncoder cEncoder dDecoder value ->
            case value of
                GotSignal a b ->
                    aEncoder a b

                GotMediaStreamTracks videoTracks ->
                    bEncoder videoTracks

                GotUserMediaDevices mediaDevices ->
                    cEncoder mediaDevices

                GotUserMediaDevicesError string ->
                    dDecoder string
        )
        |> Codec.variant2 "got-signal" GotSignal connectionIdCodec signalCodec
        |> Codec.variant1 "got-tracks" GotMediaStreamTracks (Codec.list trackCodec)
        |> Codec.variant1 "got-media-devices" GotUserMediaDevices (Codec.list mediaDevicesCodec)
        |> Codec.variant1 "got-media-devices-error" GotUserMediaDevicesError Codec.string
        |> Codec.buildCustom


type alias MediaDevices =
    { deviceId : String
    , groupId : String
    , kind : DeviceKind
    , label : String
    }


type DeviceKind
    = AudioInput
    | VideoInput


mediaDevicesCodec : Codec MediaDevices
mediaDevicesCodec =
    Codec.object MediaDevices
        |> Codec.field "deviceId" .deviceId Codec.string
        |> Codec.field "groupId" .groupId Codec.string
        |> Codec.field "kind" .kind deviceKindCodec
        |> Codec.field "label" .label Codec.string
        |> Codec.buildObject


deviceKindCodec : Codec DeviceKind
deviceKindCodec =
    Codec.custom
        (\audioInputEncoder videoInputEncoder value ->
            case value of
                AudioInput ->
                    audioInputEncoder

                VideoInput ->
                    videoInputEncoder
        )
        |> Codec.variant0 "audioinput" AudioInput
        |> Codec.variant0 "videoinput" VideoInput
        |> Codec.buildCustom


voiceChatFromJs : (Result String VoiceChatSubscription -> msg) -> Subscription FrontendOnly msg
voiceChatFromJs msg =
    Subscription.fromJs
        "voice_chat_from_js"
        voice_chat_from_js
        (\json -> Codec.decodeValue voiceChatSubscriptionCodec json |> Result.mapError Json.Decode.errorToString |> msg)


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
