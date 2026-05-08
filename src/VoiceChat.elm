port module VoiceChat exposing
    ( AudioTrackData
    , ConnectionId
    , DeviceKind(..)
    , FromJs(..)
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
    , StartData
    , StartLocalStreamData
    , ToJs(..)
    , Track(..)
    , VideoTrackData
    , decodeVoiceChatRecorder
    , displayMode
    , displayModeChangeCmd
    , fromJs
    , gotRecordedData
    , gotUserMediaDevices
    , init
    , initModel
    , isPressMsg
    , leaveVoiceChatCmds
    , serverChangeCmd
    , startArgs
    , toJs
    , videoNodes
    , view
    , voiceChatButton
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
import GuildIcon
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Html.Keyed
import Icons
import Id exposing (AnyGuildOrDmId(..), GuildOrDmId(..), Id, UserId)
import IdString exposing (IdString)
import Json.Decode
import Json.Encode
import List.Extra
import List.Nonempty exposing (Nonempty)
import MyUi
import NonemptySet exposing (NonemptySet)
import OneOrGreater
import Route exposing (Route)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Ui exposing (Element)
import Ui.Font
import User exposing (LocalUser)


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
    | PressedLeaveCall
    | PressedDownloadRecording RoomId
    | PressedChannelHeaderVoiceChatButton RoomId


type alias Local =
    { currentRoom : Maybe RoomId
    , voiceChats : SeqDict RoomId (NonemptySet ( Id UserId, ClientId ))
    }


type alias Model =
    { userMediaDevices : MediaDevicesStatus
    , selectedAudioInputDevice : Maybe (IdString MediaDeviceId)
    , selectedVideoInputDevice : Maybe (IdString MediaDeviceId)
    , audioInputEnabled : Bool
    , videoInputEnabled : Bool
    , isSpeaking : SeqSet ConnectionId
    , recordings : SeqDict RoomId (Nonempty Recording)
    , expanded : SeqSet RoomId
    , localIsSpeaking : Bool
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
    , audioInputEnabled = True
    , videoInputEnabled = False
    , isSpeaking = SeqSet.empty
    , recordings = SeqDict.empty
    , expanded = SeqSet.empty
    , localIsSpeaking = False
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


type DisplayMode
    = NoVideo
    | ShowLocalVideo
    | ShowLocalVideoAndCall
    | ShowLocalVideoAndCallThumbnail


displayModeChangeCmd : DisplayMode -> DisplayMode -> Model -> Command FrontendOnly toMsg msg
displayModeChangeCmd displayModeOld displayModeNew model =
    case ( showLocalVideo displayModeOld, showLocalVideo displayModeNew ) of
        ( True, True ) ->
            Command.none

        ( False, False ) ->
            Command.none

        ( True, False ) ->
            toJs ToJs_StopLocalStream

        ( False, True ) ->
            ToJs_StartLocalStream
                { audioInput = model.selectedAudioInputDevice
                , videoInput = model.selectedVideoInputDevice
                , audioInputEnabled = model.audioInputEnabled
                , videoInputEnabled = model.videoInputEnabled
                }
                |> toJs


showLocalVideo : DisplayMode -> Bool
showLocalVideo displayMode2 =
    case displayMode2 of
        NoVideo ->
            False

        ShowLocalVideo ->
            True

        ShowLocalVideoAndCall ->
            True

        ShowLocalVideoAndCallThumbnail ->
            True


displayMode : Route -> Model -> Local -> DisplayMode
displayMode route model local =
    let
        viewingRoomId : Maybe RoomId
        viewingRoomId =
            case Route.toGuildOrDmId route of
                Just ( GuildOrDmId (GuildOrDmId_Dm otherUserId), _ ) ->
                    DmRoomId otherUserId |> Just

                _ ->
                    Nothing
    in
    case viewingRoomId of
        Just viewingRoomId2 ->
            if Just viewingRoomId2 == local.currentRoom && SeqSet.member viewingRoomId2 model.expanded then
                case SeqDict.get viewingRoomId2 local.voiceChats of
                    Just sessions ->
                        ShowLocalVideoAndCall

                    Nothing ->
                        ShowLocalVideo

            else if SeqSet.member viewingRoomId2 model.expanded then
                ShowLocalVideo

            else
                NoVideo

        Nothing ->
            case local.currentRoom of
                Just currentRoom ->
                    ShowLocalVideoAndCallThumbnail

                Nothing ->
                    NoVideo


videoNodes : Route -> Coord CssPixels -> Model -> Local -> Html msg
videoNodes route windowSize model local =
    let
        viewingRoomId : Maybe RoomId
        viewingRoomId =
            case Route.toGuildOrDmId route of
                Just ( GuildOrDmId (GuildOrDmId_Dm otherUserId), _ ) ->
                    DmRoomId otherUserId |> Just

                _ ->
                    Nothing

        voiceChatX =
            if isMobile then
                0

            else
                MyUi.channelAndGuildColumnWidth windowSize

        voiceChatY =
            MyUi.channelHeaderHeight

        voiceChatWidth =
            Coord.xRaw windowSize - voiceChatX |> min 500

        padding =
            0

        spacing =
            8

        videoPosAndSize : Int -> Int -> ( Int, Int, Int )
        videoPosAndSize total index =
            case total of
                1 ->
                    ( voiceChatX + padding, voiceChatY + padding, voiceChatWidth - padding * 2 )

                2 ->
                    let
                        width2 =
                            (voiceChatWidth - padding * 2 - spacing) // 2
                    in
                    if index == 0 then
                        ( voiceChatX + padding, voiceChatY + padding, width2 )

                    else
                        ( voiceChatX + padding + spacing + width2, voiceChatY + padding, width2 )

                _ ->
                    ( padding + index * 20, voiceChatY + padding, voiceChatWidth // total )

        isMobile : Bool
        isMobile =
            MyUi.isMobile { windowSize = windowSize }
    in
    (case viewingRoomId of
        Just viewingRoomId2 ->
            if Just viewingRoomId2 == local.currentRoom && SeqSet.member viewingRoomId2 model.expanded then
                case SeqDict.get viewingRoomId2 local.voiceChats of
                    Just sessions ->
                        let
                            total : Int
                            total =
                                NonemptySet.size sessions + 1
                        in
                        videoNode "local-video" False (videoPosAndSize total 0) False
                            :: List.indexedMap
                                (\index session ->
                                    let
                                        connectionId : ConnectionId
                                        connectionId =
                                            { roomId = viewingRoomId2, otherClientId = session }
                                    in
                                    videoNode
                                        (connectionIdToString connectionId)
                                        False
                                        (videoPosAndSize total (index + 1))
                                        (SeqSet.member connectionId model.isSpeaking)
                                )
                                (NonemptySet.toList sessions)

                    Nothing ->
                        [ videoNode "local-video" False (videoPosAndSize 1 0) False ]

            else if SeqSet.member viewingRoomId2 model.expanded then
                [ videoNode "local-video" False (videoPosAndSize 1 0) False ]

            else
                [ videoNode "local-video" True (videoPosAndSize 1 0) False ]

        Nothing ->
            [ videoNode "local-video" True (videoPosAndSize 1 0) False ]
    )
        |> Html.Keyed.node "div" []


videoNode : String -> Bool -> ( Int, Int, Int ) -> Bool -> ( String, Html msg )
videoNode id isHidden ( x, y, width ) isSpeaking =
    ( id
    , Html.video
        [ Html.Attributes.style "width" (String.fromInt width ++ "px")
        , Html.Attributes.style "height" (String.fromFloat (toFloat width * 9 / 16) ++ "px")
        , Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "left" (String.fromInt x ++ "px")
        , Html.Attributes.style "top" (String.fromInt y ++ "px")
        , Html.Attributes.style "pointer-events" "none"
        , Html.Attributes.style
            "opacity"
            (if isHidden then
                "0.1"

             else
                "1"
            )
        , Html.Attributes.id id
        , Html.Attributes.style "background-color" "rgba(0,0,0,0.4)"
        , Html.Attributes.style
            "outline"
            (if isSpeaking then
                "4px solid aliceblue"

             else
                "0 solid aliceblue"
            )
        ]
        []
    )


green : Ui.Color
green =
    Ui.rgb 60 160 70


red : Ui.Color
red =
    Ui.rgb 200 60 60


view : Coord CssPixels -> RoomId -> LocalUser -> Local -> Model -> Element Msg
view windowSize roomId localUser calls model =
    let
        ongoingCall : Maybe (NonemptySet ( Id UserId, ClientId ))
        ongoingCall =
            SeqDict.get roomId calls.voiceChats

        hasJoined2 : Bool
        hasJoined2 =
            hasJoined roomId calls
    in
    Ui.el
        [ Ui.height (Ui.px (round (toFloat (Coord.yRaw windowSize * 2) / 3)))
        , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
        , Ui.borderColor MyUi.border2
        , Ui.background MyUi.background3
        , MyUi.noShrinking
        , Ui.inFront (Ui.el [ Ui.paddingXY 16 0 ] (voiceChatButton roomId localUser calls))
        , Ui.inFront
            (Ui.row
                [ Ui.alignBottom
                , Ui.alignRight
                , Ui.width Ui.shrink
                , Ui.padding 16
                , Ui.spacing 8
                ]
                [ MyUi.rowButton
                    (Dom.id "guild_startVoiceChat")
                    (if hasJoined2 then
                        PressedLeaveCall

                     else
                        PressedJoinCall roomId
                    )
                    [ Ui.spacing 8
                    , Ui.background
                        (if hasJoined2 then
                            red

                         else
                            green
                        )
                    , Ui.rounded 99
                    , Ui.height Ui.fill
                    , Ui.paddingWith { left = 12, right = 16, top = 0, bottom = 0 }
                    ]
                    [ Ui.html Icons.phone
                    , (case ( hasJoined2, ongoingCall ) of
                        ( True, Nothing ) ->
                            "End Call"

                        ( True, Just _ ) ->
                            "Leave Call"

                        ( False, Nothing ) ->
                            "Start Call"

                        ( False, Just _ ) ->
                            "Join Call"
                      )
                        |> Ui.text
                        |> Ui.el [ Ui.move { x = 0, y = 1, z = 0 } ]
                    ]
                , voiceChatControlButton
                    "guild_voiceChatMute"
                    (Ui.html Icons.microphone)
                    model.audioInputEnabled
                    PressedToggleMute
                , voiceChatControlButton
                    "guild_voiceChatPauseVideo"
                    (Ui.el [ Ui.move { x = 2, y = 0, z = 0 } ] (Ui.html Icons.camera))
                    model.videoInputEnabled
                    PressedTogglePauseVideo
                ]
            )
        ]
        (mediaDeviceSelectors roomId model)


voiceChatButton : RoomId -> LocalUser -> Local -> Element Msg
voiceChatButton voiceChatId localUser calls =
    let
        joined : Element msg
        joined =
            joinedUsers voiceChatId calls
                |> SeqDict.toList
                |> List.map
                    (\( userId, clientIds ) ->
                        let
                            count =
                                NonemptySet.size clientIds
                        in
                        Ui.el
                            [ case ( count > 1, OneOrGreater.fromInt count ) of
                                ( True, Just count2 ) ->
                                    GuildIcon.notificationHelper
                                        MyUi.background1
                                        MyUi.white
                                        MyUi.border1
                                        2
                                        -2
                                        count2

                                _ ->
                                    Ui.noAttr
                            ]
                            (case User.getUser userId localUser of
                                Just user ->
                                    User.profileImage user.icon

                                Nothing ->
                                    User.profileImage Nothing
                            )
                    )
                |> Ui.row [ Ui.width Ui.shrink, Ui.spacing 4 ]
    in
    Ui.row
        [ Ui.width Ui.shrink, Ui.alignRight, Ui.spacing 8 ]
        [ joined
        , MyUi.elButton
            (Dom.id "guild_voiceChat")
            (PressedChannelHeaderVoiceChatButton voiceChatId)
            [ Ui.width (Ui.px 44)
            , Ui.paddingXY 4 0
            , Ui.height Ui.fill
            ]
            (Ui.row
                [ Ui.spacing 2, Ui.centerY ]
                [ Ui.el [ Ui.width (Ui.px 20) ] (Ui.html Icons.phone)
                , if hasJoined voiceChatId calls then
                    Ui.el
                        [ Ui.width (Ui.px 8)
                        , Ui.height (Ui.px 8)
                        , Ui.background (Ui.rgb 40 190 80)
                        , Ui.rounded 4
                        ]
                        Ui.none

                  else
                    Ui.none
                ]
            )
        ]


voiceChatControlButton : String -> Element msg -> Bool -> msg -> Element msg
voiceChatControlButton htmlId iconHtml isEnabled onPress =
    MyUi.elButton
        (Dom.id htmlId)
        onPress
        [ Ui.width (Ui.px 40)
        , Ui.height (Ui.px 40)
        , Ui.padding 8
        , Ui.rounded 20
        , Ui.background
            (if isEnabled then
                Ui.rgb 60 70 100

             else
                red
            )
        , Ui.Font.color MyUi.white
        , if isEnabled then
            Ui.noAttr

          else
            Ui.inFront
                (Ui.el
                    [ Ui.width Ui.fill
                    , Ui.height Ui.fill
                    ]
                    (Ui.html Icons.diagonalSlash)
                )
        ]
        (Ui.el [ Ui.width (Ui.px 24), Ui.height (Ui.px 24) ] iconHtml)


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
                                toJs
                                    (ToJs_Stop { roomId = currentRoom, otherClientId = sessionIdHash2 })
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
                        toJs (ToJs_Start (startArgs clientId connectionId model))

                    else
                        Command.none

                Nothing ->
                    Command.none

        Server_Left _ connectionId ->
            toJs (ToJs_Stop connectionId)

        Server_SignalReceived connectionId signal ->
            toJs (ToJs_Signal connectionId signal)


port voice_chat_to_js : Json.Encode.Value -> Cmd msg


port voice_chat_from_js : (Json.Decode.Value -> msg) -> Sub msg


type ToJs
    = ToJs_Start StartData
    | ToJs_Stop ConnectionId
    | ToJs_Signal ConnectionId Signal
    | ToJs_SetAudioInputEnabled Bool
    | ToJs_SetInput Bool (IdString MediaDeviceId)
    | ToJs_SetVideoInputEnabled Bool
    | ToJs_GetMediaDevices
    | ToJs_StartLocalStream StartLocalStreamData
    | ToJs_StopLocalStream


type alias StartLocalStreamData =
    { audioInput : Maybe (IdString MediaDeviceId)
    , videoInput : Maybe (IdString MediaDeviceId)
    , audioInputEnabled : Bool
    , videoInputEnabled : Bool
    }


startLocalStreamDataCodec : Codec StartLocalStreamData
startLocalStreamDataCodec =
    Codec.object StartLocalStreamData
        |> Codec.field "audioInput" .audioInput (Codec.nullable IdString.codec)
        |> Codec.field "videoInput" .videoInput (Codec.nullable IdString.codec)
        |> Codec.field "audioInputEnabled" .audioInputEnabled Codec.bool
        |> Codec.field "videoInputEnabled" .videoInputEnabled Codec.bool
        |> Codec.buildObject


type alias StartData =
    { peerUserId : ConnectionId
    , shouldOffer : Bool
    , audioInput : Maybe (IdString MediaDeviceId)
    , videoInput : Maybe (IdString MediaDeviceId)
    , audioInputEnabled : Bool
    , videoInputEnabled : Bool
    }


startDataCodec : Codec StartData
startDataCodec =
    Codec.object StartData
        |> Codec.field "peerUserId" .peerUserId connectionIdCodec
        |> Codec.field "shouldOffer" .shouldOffer Codec.bool
        |> Codec.field "audioInput" .audioInput (Codec.nullable IdString.codec)
        |> Codec.field "videoInput" .videoInput (Codec.nullable IdString.codec)
        |> Codec.field "audioInputEnabled" .audioInputEnabled Codec.bool
        |> Codec.field "videoInputEnabled" .videoInputEnabled Codec.bool
        |> Codec.buildObject


voiceChatToJsCodec : Codec ToJs
voiceChatToJsCodec =
    Codec.custom
        (\eStart eStop eSignal eSetMuted eSetAudioInput eSetVideoPaused eGetMediaDevices eStartLocalStream eStopLocalStream value ->
            case value of
                ToJs_Start a ->
                    eStart a

                ToJs_Stop a ->
                    eStop a

                ToJs_Signal a b ->
                    eSignal a b

                ToJs_SetAudioInputEnabled a ->
                    eSetMuted a

                ToJs_SetInput a b ->
                    eSetAudioInput a b

                ToJs_SetVideoInputEnabled a ->
                    eSetVideoPaused a

                ToJs_GetMediaDevices ->
                    eGetMediaDevices

                ToJs_StartLocalStream a ->
                    eStartLocalStream a

                ToJs_StopLocalStream ->
                    eStopLocalStream
        )
        |> Codec.variant1 "start" ToJs_Start startDataCodec
        |> Codec.variant1 "stop" ToJs_Stop connectionIdCodec
        |> Codec.variant2 "signal" ToJs_Signal connectionIdCodec signalCodec
        |> Codec.variant1 "set-audio-input-enabled" ToJs_SetAudioInputEnabled Codec.bool
        |> Codec.variant2 "set-input" ToJs_SetInput Codec.bool IdString.codec
        |> Codec.variant1 "set-video-input-enabled" ToJs_SetVideoInputEnabled Codec.bool
        |> Codec.variant0 "get-media-devices" ToJs_GetMediaDevices
        |> Codec.variant1 "start-local-stream" ToJs_StartLocalStream startLocalStreamDataCodec
        |> Codec.variant0 "stop-local-stream" ToJs_StopLocalStream
        |> Codec.buildCustom


toJs : ToJs -> Command FrontendOnly toMsg msg
toJs msg =
    Command.sendToJs
        "voice_chat_to_js"
        voice_chat_to_js
        (Codec.encoder voiceChatToJsCodec msg)


startArgs : ClientId -> ConnectionId -> Model -> StartData
startArgs clientId connectionId model =
    { peerUserId = connectionId
    , shouldOffer =
        Lamdera.clientIdToString clientId < Lamdera.clientIdToString (Tuple.second connectionId.otherClientId)
    , audioInput = model.selectedAudioInputDevice
    , videoInput = model.selectedVideoInputDevice
    , audioInputEnabled = model.audioInputEnabled
    , videoInputEnabled = model.videoInputEnabled
    }


type MediaDeviceId
    = MediaDeviceId Never


type FromJs
    = FromJs_GotSignal ConnectionId Signal
    | FromJs_GotUserMediaDevices (List MediaDevice) (List (IdString MediaDeviceId))
    | FromJs_GotUserMediaDevicesError String
    | FromJs_SpeakingChanged (Maybe ConnectionId) Bool


voiceChatFromJsCodec : Codec FromJs
voiceChatFromJsCodec =
    Codec.custom
        (\aEncoder cEncoder dEncoder eEncoder value ->
            case value of
                FromJs_GotSignal a b ->
                    aEncoder a b

                FromJs_GotUserMediaDevices a b ->
                    cEncoder a b

                FromJs_GotUserMediaDevicesError string ->
                    dEncoder string

                FromJs_SpeakingChanged a b ->
                    eEncoder a b
        )
        |> Codec.variant2 "got-signal" FromJs_GotSignal connectionIdCodec signalCodec
        |> Codec.variant2 "got-media-devices" FromJs_GotUserMediaDevices (Codec.list mediaDevicesCodec) (Codec.list IdString.codec)
        |> Codec.variant1 "got-media-devices-error" FromJs_GotUserMediaDevicesError Codec.string
        |> Codec.variant2 "is-speaking-changed" FromJs_SpeakingChanged (Codec.nullable connectionIdCodec) Codec.bool
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


fromJs : (Result String FromJs -> msg) -> Subscription FrontendOnly msg
fromJs msg =
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

        PressedJoinCall _ ->
            True

        PressedLeaveCall ->
            True

        PressedDownloadRecording _ ->
            True

        PressedChannelHeaderVoiceChatButton _ ->
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
