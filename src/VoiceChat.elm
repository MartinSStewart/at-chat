port module VoiceChat exposing
    ( AudioTrackData
    , ConnectionId
    , DeviceKind(..)
    , Ice
    , Local
    , LocalChange(..)
    , MediaDevice
    , MediaDeviceId
    , MediaDevicesStatus(..)
    , Model
    , Msg(..)
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
    , gotUserMediaDevices
    , hasJoined
    , init
    , initModel
    , isPressMsg
    , joinedUsers
    , leaveVoiceChatCmds
    , mediaDeviceSelectors
    , serverChangeCmd
    , setMuted
    , setVideoPaused
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
import Html.Events
import Id exposing (Id, UserId)
import IdString exposing (IdString)
import Json.Decode
import Json.Encode
import List.Extra
import MyUi
import NonemptySet exposing (NonemptySet)
import SeqDict exposing (SeqDict)
import Ui exposing (Element)
import Ui.Font


type LocalChange
    = Local_Join Time.Posix RoomId
    | Local_Leave Time.Posix
    | Local_Signal ConnectionId Signal


type ServerChange
    = Server_Joined Time.Posix ConnectionId
    | Server_Left Time.Posix ConnectionId
    | Server_SignalReceived ConnectionId Signal


type Msg
    = SelectedAudioInputDevice (IdString MediaDeviceId)
    | SelectedVideoInputDevice (IdString MediaDeviceId)
    | PressedToggleMute
    | PressedTogglePauseVideo


type alias Local =
    { currentRoom : Maybe RoomId
    , voiceChats : SeqDict RoomId (NonemptySet ( Id UserId, ClientId ))
    }


type alias Model =
    { userMediaDevices : MediaDevicesStatus
    , selectedAudioInputDevice : Maybe (IdString MediaDeviceId)
    , selectedVideoInputDevice : Maybe (IdString MediaDeviceId)
    , isMuted : Bool
    , isVideoPaused : Bool
    }


type MediaDevicesStatus
    = MediaDevicesNotLoaded
    | HasMediaDevices (List MediaDevice)
    | FailedToGetMediaDevices String


init : SeqDict RoomId (NonemptySet ( Id UserId, ClientId )) -> Local
init voiceChats =
    { currentRoom = Nothing
    , voiceChats = voiceChats
    }


initModel : Model
initModel =
    { userMediaDevices = MediaDevicesNotLoaded
    , selectedAudioInputDevice = Nothing
    , selectedVideoInputDevice = Nothing
    , isMuted = False
    , isVideoPaused = False
    }


gotUserMediaDevices : List MediaDevice -> List (IdString MediaDeviceId) -> Model -> Model
gotUserMediaDevices devices selectedDevices model =
    { model
        | userMediaDevices = HasMediaDevices devices
        , selectedAudioInputDevice =
            List.Extra.findMap
                (\device ->
                    if device.kind == AudioInput && List.member device.deviceId selectedDevices then
                        Just device.deviceId

                    else
                        Nothing
                )
                devices
        , selectedVideoInputDevice =
            List.Extra.findMap
                (\device ->
                    if device.kind == VideoInput && List.member device.deviceId selectedDevices then
                        Just device.deviceId

                    else
                        Nothing
                )
                devices
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


audioNodes : Local -> Html msg
audioNodes model =
    List.concatMap
        (\( roomId, sessions ) ->
            if hasJoined roomId model then
                List.map
                    (\session ->
                        Html.video
                            [ Html.Attributes.style "width" "300px"
                            , Html.Attributes.style "height" "200px"
                            , Html.Attributes.id (connectionIdToString { roomId = roomId, otherSession = session })
                            , Html.Attributes.style "background-color" "rgba(0,0,0,0.4)"
                            ]
                            []
                    )
                    (NonemptySet.toList sessions)

            else
                []
        )
        (SeqDict.toList model.voiceChats)
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


hasJoined : RoomId -> Local -> Bool
hasJoined roomId model =
    model.currentRoom == Just roomId


leaveVoiceChatCmds : Local -> Command FrontendOnly toMsg msg
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


joinedUsers : RoomId -> Local -> SeqDict (Id UserId) (NonemptySet ClientId)
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


serverChangeCmd : ServerChange -> ClientId -> Local -> Model -> Command FrontendOnly toBackend msg
serverChangeCmd change clientId local model =
    case change of
        Server_Joined _ connectionId ->
            case local.currentRoom of
                Just roomId ->
                    if roomId == connectionId.roomId then
                        voiceChatStart clientId connectionId model

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


voiceChatStart : ClientId -> ConnectionId -> Model -> Command FrontendOnly toBackend msg
voiceChatStart clientId connectionId model =
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
            , ( "audioInput"
              , case model.selectedAudioInputDevice of
                    Just input ->
                        Codec.encoder IdString.codec input

                    Nothing ->
                        Json.Encode.null
              )
            , ( "videoInput"
              , case model.selectedVideoInputDevice of
                    Just input ->
                        Codec.encoder IdString.codec input

                    Nothing ->
                        Json.Encode.null
              )
            , ( "isMuted", Json.Encode.bool model.isMuted )
            , ( "isVideoPaused", Json.Encode.bool model.isVideoPaused )
            ]
        )


setMuted : Bool -> Command FrontendOnly toBackend msg
setMuted muted =
    Command.sendToJs
        "voice_chat_to_js"
        voice_chat_to_js
        (Json.Encode.object
            [ ( "kind", Json.Encode.string "set-muted" )
            , ( "muted", Json.Encode.bool muted )
            ]
        )


setVideoPaused : Bool -> Command FrontendOnly toBackend msg
setVideoPaused paused =
    Command.sendToJs
        "voice_chat_to_js"
        voice_chat_to_js
        (Json.Encode.object
            [ ( "kind", Json.Encode.string "set-video-paused" )
            , ( "paused", Json.Encode.bool paused )
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


type MediaDeviceId
    = MediaDeviceId Never


type VoiceChatSubscription
    = GotSignal ConnectionId Signal
    | GotMediaStreamTracks (List Track)
    | GotUserMediaDevices (List MediaDevice) (List (IdString MediaDeviceId))
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

                GotUserMediaDevices a b ->
                    cEncoder a b

                GotUserMediaDevicesError string ->
                    dDecoder string
        )
        |> Codec.variant2 "got-signal" GotSignal connectionIdCodec signalCodec
        |> Codec.variant1 "got-tracks" GotMediaStreamTracks (Codec.list trackCodec)
        |> Codec.variant2 "got-media-devices" GotUserMediaDevices (Codec.list mediaDevicesCodec) (Codec.list IdString.codec)
        |> Codec.variant1 "got-media-devices-error" GotUserMediaDevicesError Codec.string
        |> Codec.buildCustom


type alias MediaDevice =
    { deviceId : IdString MediaDeviceId
    , groupId : String
    , kind : DeviceKind
    , label : String
    }


type DeviceKind
    = AudioInput
    | VideoInput
    | AudioOutput


mediaDevicesCodec : Codec MediaDevice
mediaDevicesCodec =
    Codec.object MediaDevice
        |> Codec.field "deviceId" .deviceId IdString.codec
        |> Codec.field "groupId" .groupId Codec.string
        |> Codec.field "kind" .kind deviceKindCodec
        |> Codec.field "label" .label Codec.string
        |> Codec.buildObject


deviceKindCodec : Codec DeviceKind
deviceKindCodec =
    Codec.enum Codec.string [ ( "audioinput", AudioInput ), ( "audiooutput", AudioOutput ), ( "videoinput", VideoInput ) ]


voiceChatFromJs : (Result String VoiceChatSubscription -> msg) -> Subscription FrontendOnly msg
voiceChatFromJs msg =
    Subscription.fromJs
        "voice_chat_from_js"
        voice_chat_from_js
        (\json ->
            Codec.decodeValue voiceChatSubscriptionCodec json
                |> Result.mapError
                    (\error ->
                        let
                            _ =
                                Debug.log "voice_chat_from_js error" (Json.Encode.encode 0 json)
                        in
                        Json.Decode.errorToString error
                    )
                |> msg
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


mediaDeviceSelectors : Model -> Element Msg
mediaDeviceSelectors model =
    case model.userMediaDevices of
        MediaDevicesNotLoaded ->
            Ui.none

        FailedToGetMediaDevices error ->
            Ui.el
                [ Ui.padding 16
                , Ui.alignBottom
                , Ui.Font.color MyUi.font1
                ]
                (Ui.text ("Failed to get media devices: " ++ error))

        HasMediaDevices devices ->
            let
                audioDevices : List MediaDevice
                audioDevices =
                    List.filter (\d -> d.kind == AudioInput) devices

                videoDevices : List MediaDevice
                videoDevices =
                    List.filter (\d -> d.kind == VideoInput) devices
            in
            Ui.column
                [ Ui.padding 16
                , Ui.spacing 12
                , Ui.alignBottom
                , Ui.width (Ui.px 400)
                , Ui.widthMax 400
                ]
                [ deviceDropdown "Microphone" audioDevices model.selectedAudioInputDevice SelectedAudioInputDevice
                , deviceDropdown "Camera" videoDevices model.selectedVideoInputDevice SelectedVideoInputDevice
                ]


isPressMsg : Msg -> Bool
isPressMsg msg =
    case msg of
        SelectedAudioInputDevice _ ->
            False

        SelectedVideoInputDevice _ ->
            False

        PressedToggleMute ->
            True

        PressedTogglePauseVideo ->
            True


deviceDropdown : String -> List MediaDevice -> Maybe (IdString MediaDeviceId) -> (IdString MediaDeviceId -> msg) -> Element msg
deviceDropdown labelText devices selected onSelect =
    Ui.column
        [ Ui.spacing 4, Ui.Font.color MyUi.font1 ]
        [ Ui.text labelText
        , Ui.html
            (Html.select
                [ Html.Attributes.value
                    (case selected of
                        Just a ->
                            IdString.toString a

                        Nothing ->
                            ""
                    )
                , Html.Events.onInput (\text -> IdString.fromString text |> onSelect)
                , Html.Attributes.style "width" "100%"
                , Html.Attributes.style "padding" "7px 8px"
                , Html.Attributes.style "border" "1px solid rgb(97,104,124)"
                , Html.Attributes.style "border-radius" "4px"
                , Html.Attributes.style "font-size" "16px"
                , Html.Attributes.style "background-color" "rgb(32,40,70)"
                , Html.Attributes.style "color" "rgb(255,255,255)"
                , Html.Attributes.style "cursor" "pointer"
                ]
                (case devices of
                    [] ->
                        [ Html.option [] [ Html.text "No devices available" ] ]

                    _ ->
                        List.map
                            (\device ->
                                Html.option
                                    [ Html.Attributes.value (IdString.toString device.deviceId)
                                    , Html.Attributes.selected (Just device.deviceId == selected)
                                    ]
                                    [ Html.text
                                        (if String.isEmpty device.label then
                                            IdString.toString device.deviceId

                                         else
                                            device.label
                                        )
                                    ]
                            )
                            devices
                )
            )
        ]
