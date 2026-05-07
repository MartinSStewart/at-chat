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
    , Recording
    , RoomId(..)
    , Sdp
    , ServerChange(..)
    , Signal(..)
    , StartArgs
    , Track(..)
    , VideoTrackData
    , VoiceChatFromJs(..)
    , VoiceChatToJs(..)
    , decodeVoiceChatRecorder
    , gotRecordedData
    , gotUserMediaDevices
    , hasJoined
    , init
    , initModel
    , isPressMsg
    , joinedUsers
    , leaveVoiceChatCmds
    , mediaDeviceSelectors
    , serverChangeCmd
    , startArgs
    , videoNodes
    , voiceChatFromJs
    , voiceChatToJs
    )

import Bytes exposing (Bytes)
import Bytes.Decode
import Codec exposing (Codec)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Effect.Browser.Dom as Dom
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
import List.Nonempty exposing (Nonempty)
import MyUi
import NonemptySet exposing (NonemptySet)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
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
    | PressedJoinCall RoomId
    | PressedLeaveCall RoomId
    | PressedDownloadRecording RoomId


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
    , isSpeaking : SeqSet ConnectionId
    , recordings : SeqDict RoomId (Nonempty Recording)
    , expanded : SeqSet RoomId
    }


type alias Recording =
    { mimeType : String
    , extraData : String
    , startTime : Time.Posix
    , endTime : Time.Posix
    , data : Bytes
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
    , isVideoPaused = True
    , isSpeaking = SeqSet.empty
    , recordings = SeqDict.empty
    , expanded = SeqSet.empty
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
    { roomId : RoomId, otherClientId : ( Id UserId, ClientId ) }


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


videoNodes : Coord CssPixels -> Model -> Local -> Html msg
videoNodes windowSize model local =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobile { windowSize = windowSize }
    in
    List.concatMap
        (\( roomId, sessions ) ->
            if hasJoined roomId local then
                let
                    total =
                        NonemptySet.size sessions
                in
                List.indexedMap
                    (\index session ->
                        let
                            connectionId : ConnectionId
                            connectionId =
                                { roomId = roomId, otherClientId = session }
                        in
                        Html.video
                            [ Html.Attributes.style "width" "300px"
                            , Html.Attributes.style "height" "200px"
                            , Html.Attributes.style "position" "absolute"
                            , Html.Attributes.style
                                "left"
                                (String.fromInt
                                    (if isMobile then
                                        index * 320 + 10

                                     else
                                        index * 320 + 10 + MyUi.channelAndGuildColumnWidth windowSize
                                    )
                                    ++ "px"
                                )
                            , Html.Attributes.style "top" "10px"
                            , Html.Attributes.id (connectionIdToString connectionId)
                            , Html.Attributes.style "background-color" "rgba(0,0,0,0.4)"
                            , Html.Attributes.style
                                "outline"
                                (if SeqSet.member connectionId model.isSpeaking then
                                    "4px solid aliceblue"

                                 else
                                    "0 solid aliceblue"
                                )
                            ]
                            []
                    )
                    (NonemptySet.toList sessions)

            else
                []
        )
        (SeqDict.toList local.voiceChats)
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
                        |> List.map
                            (\sessionIdHash2 ->
                                voiceChatToJs
                                    (Js_Stop { roomId = currentRoom, otherClientId = sessionIdHash2 })
                            )
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
                        voiceChatToJs (Js_Start (startArgs clientId connectionId model))

                    else
                        Command.none

                Nothing ->
                    Command.none

        Server_Left _ connectionId ->
            voiceChatToJs (Js_Stop connectionId)

        Server_SignalReceived connectionId signal ->
            voiceChatToJs (Js_Signal connectionId signal)


port voice_chat_to_js : Json.Encode.Value -> Cmd msg


port voice_chat_from_js : (Json.Decode.Value -> msg) -> Sub msg


type VoiceChatToJs
    = Js_Start StartArgs
    | Js_Stop ConnectionId
    | Js_Signal ConnectionId Signal
    | Js_SetMuted Bool
    | Js_SetAudioInput (IdString MediaDeviceId)
    | Js_SetVideoPaused Bool
    | Js_GetMediaDevices


type alias StartArgs =
    { peerUserId : ConnectionId
    , shouldOffer : Bool
    , audioInput : Maybe (IdString MediaDeviceId)
    , videoInput : Maybe (IdString MediaDeviceId)
    , isMuted : Bool
    , isVideoPaused : Bool
    }


startArgsCodec : Codec StartArgs
startArgsCodec =
    Codec.object StartArgs
        |> Codec.field "peerUserId" .peerUserId connectionIdCodec
        |> Codec.field "shouldOffer" .shouldOffer Codec.bool
        |> Codec.field "audioInput" .audioInput (Codec.nullable IdString.codec)
        |> Codec.field "videoInput" .videoInput (Codec.nullable IdString.codec)
        |> Codec.field "isMuted" .isMuted Codec.bool
        |> Codec.field "isVideoPaused" .isVideoPaused Codec.bool
        |> Codec.buildObject


voiceChatToJsCodec : Codec VoiceChatToJs
voiceChatToJsCodec =
    Codec.custom
        (\eStart eStop eSignal eSetMuted eSetAudioInput eSetVideoPaused eGetMediaDevices value ->
            case value of
                Js_Start a ->
                    eStart a

                Js_Stop a ->
                    eStop a

                Js_Signal a b ->
                    eSignal a b

                Js_SetMuted a ->
                    eSetMuted a

                Js_SetAudioInput a ->
                    eSetAudioInput a

                Js_SetVideoPaused a ->
                    eSetVideoPaused a

                Js_GetMediaDevices ->
                    eGetMediaDevices
        )
        |> Codec.variant1 "start" Js_Start startArgsCodec
        |> Codec.variant1 "stop" Js_Stop connectionIdCodec
        |> Codec.variant2 "signal" Js_Signal connectionIdCodec signalCodec
        |> Codec.variant1 "set-muted" Js_SetMuted Codec.bool
        |> Codec.variant1 "set-audio-input" Js_SetAudioInput IdString.codec
        |> Codec.variant1 "set-video-paused" Js_SetVideoPaused Codec.bool
        |> Codec.variant0 "get-media-devices" Js_GetMediaDevices
        |> Codec.buildCustom


voiceChatToJs : VoiceChatToJs -> Command FrontendOnly toMsg msg
voiceChatToJs msg =
    Command.sendToJs
        "voice_chat_to_js"
        voice_chat_to_js
        (Codec.encoder voiceChatToJsCodec msg)


startArgs : ClientId -> ConnectionId -> Model -> StartArgs
startArgs clientId connectionId model =
    { peerUserId = connectionId
    , shouldOffer =
        Lamdera.clientIdToString clientId
            < Lamdera.clientIdToString (Tuple.second connectionId.otherClientId)
    , audioInput = model.selectedAudioInputDevice
    , videoInput = model.selectedVideoInputDevice
    , isMuted = model.isMuted
    , isVideoPaused = model.isVideoPaused
    }


type MediaDeviceId
    = MediaDeviceId Never


type VoiceChatFromJs
    = GotSignal ConnectionId Signal
    | GotMediaStreamTracks (List Track)
    | GotUserMediaDevices (List MediaDevice) (List (IdString MediaDeviceId))
    | GotUserMediaDevicesError String
    | IsSpeakingChanged ConnectionId Bool


voiceChatFromJsCodec : Codec VoiceChatFromJs
voiceChatFromJsCodec =
    Codec.custom
        (\aEncoder bEncoder cEncoder dEncoder eEncoder value ->
            case value of
                GotSignal a b ->
                    aEncoder a b

                GotMediaStreamTracks videoTracks ->
                    bEncoder videoTracks

                GotUserMediaDevices a b ->
                    cEncoder a b

                GotUserMediaDevicesError string ->
                    dEncoder string

                IsSpeakingChanged a b ->
                    eEncoder a b
        )
        |> Codec.variant2 "got-signal" GotSignal connectionIdCodec signalCodec
        |> Codec.variant1 "got-tracks" GotMediaStreamTracks (Codec.list trackCodec)
        |> Codec.variant2 "got-media-devices" GotUserMediaDevices (Codec.list mediaDevicesCodec) (Codec.list IdString.codec)
        |> Codec.variant1 "got-media-devices-error" GotUserMediaDevicesError Codec.string
        |> Codec.variant2 "is-speaking-changed" IsSpeakingChanged connectionIdCodec Codec.bool
        |> Codec.buildCustom


port got_recorded_data : (Bytes -> msg) -> Sub msg


gotRecordedData : (Bytes -> msg) -> Subscription FrontendOnly msg
gotRecordedData msg =
    Subscription.fromJsBytes "got_recorded_data" got_recorded_data msg


decodeVoiceChatRecorder : Bytes -> Bytes.Decode.Decoder ( ConnectionId, Recording )
decodeVoiceChatRecorder bytes =
    Bytes.Decode.map4 (\a b c d -> ( a, b, ( c, d ) )) decodeString decodeMimeType decodeTime decodeTime
        |> Bytes.Decode.andThen
            (\( ( connectionIdLength, connectionId ), ( mimeTypeLength, ( mimeType, extraData ) ), ( startTime, endTime ) ) ->
                case connectionIdFromString connectionId of
                    Ok connectionId2 ->
                        Bytes.Decode.bytes (Bytes.width bytes - (connectionIdLength + mimeTypeLength + 8 + 8))
                            |> Bytes.Decode.map
                                (\recording ->
                                    ( connectionId2
                                    , { mimeType = mimeType
                                      , extraData = extraData
                                      , data = recording
                                      , startTime = startTime
                                      , endTime = endTime
                                      }
                                    )
                                )

                    Err () ->
                        Bytes.Decode.fail
            )


decodeMimeType : Bytes.Decode.Decoder ( Int, ( String, String ) )
decodeMimeType =
    Bytes.Decode.map
        (\( length, text ) ->
            ( length
            , case String.split ";" text of
                mimeType :: extraData ->
                    ( mimeType, String.join ";" extraData )

                _ ->
                    ( "", "" )
            )
        )
        decodeString


decodeString : Bytes.Decode.Decoder ( Int, String )
decodeString =
    Bytes.Decode.andThen (\length -> Bytes.Decode.map (Tuple.pair (length + 1)) (Bytes.Decode.string length)) Bytes.Decode.unsignedInt8


decodeTime : Bytes.Decode.Decoder Time.Posix
decodeTime =
    Bytes.Decode.map (\a -> Time.millisToPosix (round a)) (Bytes.Decode.float64 Bytes.BE)


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


voiceChatFromJs : (Result String VoiceChatFromJs -> msg) -> Subscription FrontendOnly msg
voiceChatFromJs msg =
    Subscription.fromJs
        "voice_chat_from_js"
        voice_chat_from_js
        (\json ->
            Codec.decodeValue voiceChatFromJsCodec json
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
connectionIdToString { roomId, otherClientId } =
    (case roomId of
        DmRoomId otherUserId ->
            Id.toString otherUserId
    )
        ++ " "
        ++ Id.toString (Tuple.first otherClientId)
        ++ " "
        ++ Lamdera.clientIdToString (Tuple.second otherClientId)


connectionIdFromString : String -> Result () ConnectionId
connectionIdFromString text =
    case String.split " " text of
        [ first, second, third ] ->
            case ( String.toInt first, String.toInt second ) of
                ( Just int, Just userId ) ->
                    Ok
                        { roomId = DmRoomId (Id.fromInt int)
                        , otherClientId = ( Id.fromInt userId, Lamdera.clientIdFromString third )
                        }

                _ ->
                    Err ()

        _ ->
            Err ()


connectionIdCodec : Codec ConnectionId
connectionIdCodec =
    Codec.andThen
        (\text ->
            case connectionIdFromString text of
                Ok ok ->
                    Codec.succeed ok

                Err () ->
                    Codec.fail ("Invalid connectionId: " ++ text)
        )
        connectionIdToString
        Codec.string


mediaDeviceSelectors : RoomId -> Model -> Element Msg
mediaDeviceSelectors roomId model =
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
                [ case SeqDict.get roomId model.recordings of
                    Just _ ->
                        MyUi.simpleButton
                            (Dom.id "voiceChat_downloadRecording")
                            (PressedDownloadRecording roomId)
                            (Ui.text "Download recording")

                    Nothing ->
                        Ui.none
                , deviceDropdown "Microphone" audioDevices model.selectedAudioInputDevice SelectedAudioInputDevice
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

        PressedJoinCall roomId ->
            True

        PressedLeaveCall roomId ->
            True

        PressedDownloadRecording roomId ->
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
                (List.map
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
