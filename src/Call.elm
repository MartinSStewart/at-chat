port module Call exposing
    ( ChannelSidebarMode(..)
    , ConnectionId
    , DeviceKind(..)
    , DisplayMode(..)
    , FromJs(..)
    , Ice
    , Local
    , LocalChange(..)
    , LocalOrConnection(..)
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
    , sidebarOffsetAttr
    , startArgs
    , startLocalStream
    , toJs
    , videoNodes
    , view
    )

import Bytes exposing (Bytes)
import Bytes.Decode
import Codec exposing (Codec)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import DmChannel
import Effect.Browser.Dom as Dom
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera as Lamdera exposing (ClientId)
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Time as Time
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
import Route exposing (DmChannelHeaderTab(..), Route(..))
import SecretId exposing (SecretId, TurnCredentials)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Ui exposing (Element)
import Ui.Font
import UserSession exposing (ToBeFilledInByBackend)


type LocalChange
    = Local_Join Time.Posix RoomId (ToBeFilledInByBackend (SecretId TurnCredentials))
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
    | PressedCopyError String
    | ChangedVolume ConnectionId Float
    | MouseEnterVideoNode LocalOrConnection
    | MouseExitVideoNode LocalOrConnection


type alias Local =
    { currentRoom : Maybe RoomId
    , voiceChats : SeqDict RoomId (NonemptySet ( Id UserId, ClientId ))
    , turnCredentials : Maybe (SecretId TurnCredentials)
    }


type alias Model =
    { userMediaDevices : MediaDevicesStatus
    , selectedAudioInputDevice : Maybe (IdString MediaDeviceId)
    , selectedVideoInputDevice : Maybe (IdString MediaDeviceId)
    , audioInputEnabled : Bool
    , videoInputEnabled : Bool
    , isSpeaking : SeqSet ConnectionId
    , recordings : SeqDict RoomId (Nonempty Recording)
    , localIsSpeaking : Bool
    , startConnectionError : Maybe String
    , volume : SeqDict ( Id UserId, ClientId ) Float
    , videoHover : Maybe LocalOrConnection
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


type ChannelSidebarMode
    = ChannelSidebarClosed
    | ChannelSidebarOpened
    | ChannelSidebarClosing { offset : Float }
    | ChannelSidebarOpening { offset : Float }
    | ChannelSidebarDragging { offset : Float, previousOffset : Float, time : Time.Posix }


init : SeqDict RoomId (NonemptySet ( Id UserId, ClientId )) -> Local
init voiceChats =
    { currentRoom = Nothing
    , voiceChats = voiceChats
    , turnCredentials = Nothing
    }


initModel : Model
initModel =
    { userMediaDevices = MediaDevicesNotLoaded
    , selectedAudioInputDevice = Nothing
    , selectedVideoInputDevice = Nothing
    , audioInputEnabled = True
    , videoInputEnabled = True
    , isSpeaking = SeqSet.empty
    , recordings = SeqDict.empty
    , localIsSpeaking = False
    , startConnectionError = Nothing
    , volume = SeqDict.empty
    , videoHover = Nothing
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


displayMode : Id UserId -> Route -> Local -> DisplayMode
displayMode currentUserId route local =
    let
        thumbnailOrNoVideo =
            case local.currentRoom of
                Just _ ->
                    ShowLocalVideoAndCallThumbnail

                Nothing ->
                    NoVideo
    in
    case route of
        HomePageRoute ->
            thumbnailOrNoVideo

        AdminRoute _ ->
            thumbnailOrNoVideo

        GuildRoute _ _ ->
            thumbnailOrNoVideo

        DiscordGuildRoute _ ->
            thumbnailOrNoVideo

        DmRoute dmRoute ->
            case DmChannel.otherUserId currentUserId dmRoute.channelId of
                Just otherUserId ->
                    let
                        roomId =
                            DmRoomId otherUserId

                        isTabExpanded =
                            dmRoute.tab == Just DmChannelHeaderTab_VoiceChat
                    in
                    if Just roomId == local.currentRoom && isTabExpanded then
                        case SeqDict.get roomId local.voiceChats of
                            Just _ ->
                                ShowLocalVideoAndCall

                            Nothing ->
                                ShowLocalVideo

                    else if isTabExpanded then
                        ShowLocalVideo

                    else
                        thumbnailOrNoVideo

                Nothing ->
                    thumbnailOrNoVideo

        DiscordDmRoute _ ->
            thumbnailOrNoVideo

        AiChatRoute ->
            thumbnailOrNoVideo

        SlackOAuthRedirect _ ->
            thumbnailOrNoVideo

        TextEditorRoute ->
            thumbnailOrNoVideo

        LinkDiscord _ ->
            thumbnailOrNoVideo


localVideoNodeId : String
localVideoNodeId =
    "local-video"


videoNodes :
    Id UserId
    -> { a | windowSize : Coord CssPixels, route : Route }
    -> { b | voiceChat : Model, sidebarMode : ChannelSidebarMode }
    -> Local
    -> Html Msg
videoNodes currentUserId config loggedIn local =
    let
        model =
            loggedIn.voiceChat

        viewingRoomId : Maybe RoomId
        viewingRoomId =
            case Route.toGuildOrDmId currentUserId config.route of
                Just ( GuildOrDmId (GuildOrDmId_Dm otherUserId), _ ) ->
                    DmRoomId otherUserId |> Just

                _ ->
                    Nothing

        voiceChatX : Int
        voiceChatX =
            if isMobile then
                0

            else
                MyUi.channelAndGuildColumnWidth config.windowSize

        voiceChatY =
            MyUi.channelHeaderHeight

        maxWidth : Int
        maxWidth =
            Coord.xRaw config.windowSize - voiceChatX

        --|> min (ceiling (toFloat voiceChatHeight * 16 / 9))
        maxHeight : Int
        maxHeight =
            viewHeight config.windowSize
                - voiceChatY
                - (if isMobile then
                    150

                   else
                    120
                  )

        padding =
            8

        spacing =
            8

        videoPosAndSize : Int -> Int -> ( Int, Int, Int )
        videoPosAndSize total index =
            case total of
                1 ->
                    let
                        width =
                            min (round (toFloat maxHeight * aspectRatio)) maxWidth - padding * 2

                        voiceChatX2 =
                            voiceChatX + (maxWidth - width) // 2 + sidebarOffsetAttr loggedIn.sidebarMode config
                    in
                    ( voiceChatX2
                    , voiceChatY + padding
                    , width
                    )

                2 ->
                    let
                        width =
                            min (round (toFloat maxHeight * aspectRatio * 2)) maxWidth

                        voiceChatX2 =
                            voiceChatX + (maxWidth - width) // 2 + sidebarOffsetAttr loggedIn.sidebarMode config

                        width2 =
                            (width - padding * 2 - spacing) // 2
                    in
                    if index == 0 then
                        ( voiceChatX2 + padding, voiceChatY + padding, width2 )

                    else
                        ( voiceChatX2 + padding + spacing + width2, voiceChatY + padding, width2 )

                _ ->
                    ( padding + index * 20 + sidebarOffsetAttr loggedIn.sidebarMode config
                    , voiceChatY + padding
                    , maxWidth // total
                    )

        isMobile : Bool
        isMobile =
            MyUi.isMobile { windowSize = config.windowSize }
    in
    (case viewingRoomId of
        Just viewingRoomId2 ->
            let
                isTabExpanded =
                    case config.route of
                        DmRoute dmRoute ->
                            dmRoute.tab == Just DmChannelHeaderTab_VoiceChat

                        HomePageRoute ->
                            False

                        AdminRoute _ ->
                            False

                        GuildRoute _ _ ->
                            False

                        DiscordGuildRoute _ ->
                            False

                        DiscordDmRoute _ ->
                            False

                        AiChatRoute ->
                            False

                        SlackOAuthRedirect _ ->
                            False

                        TextEditorRoute ->
                            False

                        LinkDiscord _ ->
                            False
            in
            if Just viewingRoomId2 == local.currentRoom && isTabExpanded then
                case SeqDict.get viewingRoomId2 local.voiceChats of
                    Just sessions ->
                        let
                            total : Int
                            total =
                                NonemptySet.size sessions + 1
                        in
                        videoNode IsLocal False (videoPosAndSize total 0) model.localIsSpeaking model
                            :: List.indexedMap
                                (\index session ->
                                    let
                                        connectionId : ConnectionId
                                        connectionId =
                                            { roomId = viewingRoomId2, otherClientId = session }
                                    in
                                    videoNode
                                        (IsConnection connectionId)
                                        False
                                        (videoPosAndSize total (index + 1))
                                        (SeqSet.member connectionId model.isSpeaking)
                                        model
                                )
                                (NonemptySet.toList sessions)

                    Nothing ->
                        [ videoNode IsLocal False (videoPosAndSize 1 0) model.localIsSpeaking model ]

            else if isTabExpanded then
                [ videoNode IsLocal False (videoPosAndSize 1 0) model.localIsSpeaking model ]

            else
                [ videoNode IsLocal True (videoPosAndSize 1 0) model.localIsSpeaking model ]

        Nothing ->
            [ videoNode IsLocal True (videoPosAndSize 1 0) model.localIsSpeaking model ]
    )
        |> Html.Keyed.node "div" []


aspectRatio : Float
aspectRatio =
    16 / 9


videoNode :
    LocalOrConnection
    -> Bool
    -> ( Int, Int, Int )
    -> Bool
    -> Model
    -> ( String, Html Msg )
videoNode id isHidden ( x, y, width ) isSpeaking model =
    let
        height : Float
        height =
            toFloat width / aspectRatio

        idString =
            case id of
                IsLocal ->
                    localVideoNodeId

                IsConnection connectionId ->
                    connectionIdToString connectionId
    in
    ( idString
    , Html.div
        [ Html.Attributes.style "width" (String.fromInt width ++ "px")
        , Html.Attributes.style "height" (String.fromFloat height ++ "px")
        , Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "left" (String.fromInt x ++ "px")
        , Html.Attributes.style "top" ("calc(" ++ MyUi.insetTop ++ " + " ++ String.fromInt y ++ "px)")
        , Html.Attributes.style
            "pointer-events"
            (if isHidden then
                "none"

             else
                "auto"
            )
        , Html.Events.onMouseEnter (MouseEnterVideoNode id)
        , Html.Events.onMouseLeave (MouseExitVideoNode id)
        , Html.Attributes.style
            "opacity"
            (if isHidden then
                "0"

             else
                "1"
            )
        ]
        [ Html.video
            [ Html.Attributes.id idString
            , Html.Attributes.style "background-color" "rgba(0,0,0,0.4)"
            , Html.Attributes.style "width" (String.fromInt width ++ "px")
            , Html.Attributes.style "height" (String.fromFloat height ++ "px")
            , Html.Attributes.style
                "outline"
                (if isSpeaking then
                    "4px solid rgb(131, 147, 167)"

                 else
                    "0 solid rgb(131, 147, 167)"
                )
            , Html.Attributes.style "transition" "outline-width 50ms ease-out"
            , Html.Attributes.style "border-radius" "8px"
            , Html.Attributes.style "pointer-events" "none"
            , Html.Attributes.attribute "playsinline" ""
            , Html.Attributes.attribute "webkit-playsinline" ""
            ]
            []
        , case id of
            IsConnection connectionId ->
                let
                    volume =
                        SeqDict.get connectionId.otherClientId model.volume |> Maybe.withDefault 1

                    sliderHeight : Int
                    sliderHeight =
                        80

                    iconSize : Int
                    iconSize =
                        20

                    spacing =
                        4

                    padding =
                        4

                    sliderBottomMargin =
                        4

                    containerHeight =
                        sliderHeight + iconSize + spacing + sliderBottomMargin + padding * 2

                    isVisible =
                        model.videoHover == Just id && not isHidden
                in
                Html.div
                    [ Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "left" (String.fromInt 8 ++ "px")
                    , Html.Attributes.style "z-index" "999"
                    , Html.Attributes.style
                        "top"
                        (String.fromInt (round height - containerHeight - 8) ++ "px")
                    , Html.Attributes.style "display" "flex"
                    , Html.Attributes.style "flex-direction" "column"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "gap" (String.fromInt spacing ++ "px")
                    , Html.Attributes.style "padding" (String.fromInt padding ++ "px")
                    , Html.Attributes.style "background-color" "rgba(0,0,0,0.4)"
                    , Html.Attributes.style "border-radius" "6px"
                    , Html.Attributes.style "color" "white"
                    , Html.Attributes.style "opacity"
                        (if isVisible then
                            "1"

                         else
                            "0"
                        )
                    , Html.Attributes.style "pointer-events"
                        (if isVisible then
                            "auto"

                         else
                            "none"
                        )
                    , Html.Attributes.style "transition" "opacity 0.2s ease-in-out"
                    ]
                    [ Html.div
                        [ Html.Attributes.style "width" (String.fromInt iconSize ++ "px")
                        , Html.Attributes.style "height" (String.fromInt iconSize ++ "px")
                        ]
                        [ Icons.volume ]
                    , Html.input
                        [ Html.Attributes.type_ "range"
                        , Html.Attributes.min "0"
                        , Html.Attributes.max "1"
                        , Html.Attributes.step "0.01"
                        , Html.Attributes.style "margin-bottom" (String.fromInt sliderBottomMargin ++ "px")
                        , Html.Attributes.value (String.fromFloat volume)
                        , Html.Events.onInput
                            (\str ->
                                ChangedVolume
                                    connectionId
                                    (String.toFloat str |> Maybe.withDefault 1)
                            )
                        , Html.Attributes.style "height" (String.fromInt sliderHeight ++ "px")
                        , Html.Attributes.style "appearance" "slider-vertical"
                        , Html.Attributes.style "-webkit-appearance" "slider-vertical"
                        , Html.Attributes.style "width" (String.fromInt iconSize ++ "px")
                        ]
                        []
                    ]

            IsLocal ->
                Html.text ""
        ]
    )


green : Ui.Color
green =
    Ui.rgb 60 160 70


red : Ui.Color
red =
    Ui.rgb 200 60 60


redBorder : Ui.Color
redBorder =
    Ui.rgb 202 92 92


viewHeight : Coord CssPixels -> Int
viewHeight windowSize =
    round (toFloat (Coord.yRaw windowSize * 2) / 3)


view : Coord CssPixels -> RoomId -> Local -> Model -> Element Msg
view windowSize roomId calls model =
    let
        ongoingCall : Maybe (NonemptySet ( Id UserId, ClientId ))
        ongoingCall =
            SeqDict.get roomId calls.voiceChats

        hasJoined2 : Bool
        hasJoined2 =
            hasJoined roomId calls

        isMobile =
            MyUi.isMobile { windowSize = windowSize }
    in
    Ui.el
        [ Ui.height (Ui.px (viewHeight windowSize))
        , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
        , Ui.borderColor MyUi.border2
        , Ui.background MyUi.tabBackground
        , MyUi.noShrinking
        , Ui.inFront
            (Ui.column
                [ Ui.alignBottom ]
                [ case model.startConnectionError of
                    Just error ->
                        MyUi.errorBox (Dom.id "voiceChat_errorBox") PressedCopyError error

                    Nothing ->
                        Ui.none
                , (if isMobile then
                    Ui.column

                   else
                    Ui.row
                  )
                    [ Ui.contentBottom
                    , if isMobile then
                        Ui.padding 8

                      else
                        Ui.padding 16
                    , Ui.spacing 8
                    ]
                    [ mediaDeviceSelectors isMobile roomId model
                    , Ui.row
                        [ Ui.alignRight
                        , Ui.width Ui.shrink
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
                                    "End\u{00A0}Call"

                                ( True, Just _ ) ->
                                    "Leave\u{00A0}Call"

                                ( False, Nothing ) ->
                                    "Start\u{00A0}Call"

                                ( False, Just _ ) ->
                                    "Join\u{00A0}Call"
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
                            (Ui.html Icons.camera)
                            model.videoInputEnabled
                            PressedTogglePauseVideo
                        ]
                    ]
                ]
            )
        ]
        Ui.none


voiceChatControlButton : String -> Element msg -> Bool -> msg -> Element msg
voiceChatControlButton htmlId iconHtml isEnabled onPress =
    MyUi.elButton
        (Dom.id htmlId)
        onPress
        [ Ui.width (Ui.px 40)
        , Ui.height (Ui.px 40)
        , Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.rounded 20
        , Ui.border 1
        , Ui.borderColor
            (if isEnabled then
                MyUi.inputBorder

             else
                redBorder
            )
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
                    [ Ui.height Ui.fill
                    ]
                    (Ui.html Icons.diagonalSlash)
                )
        ]
        iconHtml


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


serverChangeCmd : ServerChange -> ClientId -> Id UserId -> Local -> Model -> Command FrontendOnly toBackend msg
serverChangeCmd change clientId currentUserId local model =
    case change of
        Server_Joined _ connectionId ->
            case local.currentRoom of
                Just roomId ->
                    if roomId == connectionId.roomId then
                        startArgs clientId currentUserId connectionId local model

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
    | ToJs_SetVolume ConnectionId Float


type alias StartLocalStreamData =
    { audioInput : Maybe (IdString MediaDeviceId)
    , videoInput : Maybe (IdString MediaDeviceId)
    , audioInputEnabled : Bool
    , videoInputEnabled : Bool
    }


startLocalStream : Model -> Command FrontendOnly toMsg msg
startLocalStream model =
    ToJs_StartLocalStream
        { audioInput = model.selectedAudioInputDevice
        , videoInput = model.selectedVideoInputDevice
        , audioInputEnabled = model.audioInputEnabled
        , videoInputEnabled = model.videoInputEnabled
        }
        |> toJs


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
    , turnCredentials : Maybe (SecretId TurnCredentials)
    , userId : Id UserId
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
        |> Codec.field "turnCredentials" .turnCredentials (Codec.nullable SecretId.codec)
        |> Codec.field "userId" .userId Id.codec
        |> Codec.buildObject


voiceChatToJsCodec : Codec ToJs
voiceChatToJsCodec =
    Codec.custom
        (\eStart eStop eSignal eSetMuted eSetAudioInput eSetVideoPaused eGetMediaDevices eStartLocalStream eStopLocalStream eSetVolume value ->
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

                ToJs_SetVolume a b ->
                    eSetVolume a b
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
        |> Codec.variant2 "set-volume" ToJs_SetVolume connectionIdCodec Codec.float
        |> Codec.buildCustom


toJs : ToJs -> Command FrontendOnly toMsg msg
toJs msg =
    Command.sendToJs
        "voice_chat_to_js"
        voice_chat_to_js
        (Codec.encoder voiceChatToJsCodec msg)


startArgs : ClientId -> Id UserId -> ConnectionId -> Local -> Model -> Command FrontendOnly toMsg msg
startArgs clientId currentUserId connectionId local model =
    { peerUserId = connectionId
    , shouldOffer =
        Lamdera.clientIdToString clientId < Lamdera.clientIdToString (Tuple.second connectionId.otherClientId)
    , audioInput = model.selectedAudioInputDevice
    , videoInput = model.selectedVideoInputDevice
    , audioInputEnabled = model.audioInputEnabled
    , videoInputEnabled = model.videoInputEnabled
    , turnCredentials = local.turnCredentials
    , userId = currentUserId
    }
        |> ToJs_Start
        |> toJs


type MediaDeviceId
    = MediaDeviceId Never


type FromJs
    = FromJs_GotSignal ConnectionId Signal
    | FromJs_GotUserMediaDevices (List MediaDevice) (List (IdString MediaDeviceId))
    | FromJs_GotUserMediaDevicesError String
    | FromJs_SpeakingChanged LocalOrConnection Bool
    | FromJs_StartConnectionError String


type LocalOrConnection
    = IsLocal
    | IsConnection ConnectionId


localOrConnectionCodec : Codec LocalOrConnection
localOrConnectionCodec =
    Codec.custom
        (\aEncoder bEncoder value ->
            case value of
                IsLocal ->
                    aEncoder

                IsConnection a ->
                    bEncoder a
        )
        |> Codec.variant0 localVideoNodeId IsLocal
        |> Codec.variant1 "is-connection" IsConnection connectionIdCodec
        |> Codec.buildCustom


voiceChatFromJsCodec : Codec FromJs
voiceChatFromJsCodec =
    Codec.custom
        (\aEncoder cEncoder dEncoder eEncoder fEncoder value ->
            case value of
                FromJs_GotSignal a b ->
                    aEncoder a b

                FromJs_GotUserMediaDevices a b ->
                    cEncoder a b

                FromJs_GotUserMediaDevicesError string ->
                    dEncoder string

                FromJs_SpeakingChanged a b ->
                    eEncoder a b

                FromJs_StartConnectionError string ->
                    fEncoder string
        )
        |> Codec.variant2 "got-signal" FromJs_GotSignal connectionIdCodec signalCodec
        |> Codec.variant2 "got-media-devices" FromJs_GotUserMediaDevices (Codec.list mediaDevicesCodec) (Codec.list IdString.codec)
        |> Codec.variant1 "got-media-devices-error" FromJs_GotUserMediaDevicesError Codec.string
        |> Codec.variant2 "is-speaking-changed" FromJs_SpeakingChanged localOrConnectionCodec Codec.bool
        |> Codec.variant1 "start-connection-error" FromJs_StartConnectionError Codec.string
        |> Codec.buildCustom



--port got_recorded_data : (Bytes -> msg) -> Sub msg


gotRecordedData : (Bytes -> msg) -> Subscription FrontendOnly msg
gotRecordedData _ =
    Subscription.none



--Subscription.fromJsBytes "got_recorded_data" got_recorded_data msg


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


mediaDeviceSelectors : Bool -> RoomId -> Model -> Element Msg
mediaDeviceSelectors isMobile roomId model =
    case model.userMediaDevices of
        MediaDevicesNotLoaded ->
            Ui.none

        FailedToGetMediaDevices error ->
            Ui.el
                [ Ui.alignBottom
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
                [ Ui.spacing 8
                , Ui.alignBottom
                , Ui.widthMax 400
                , Ui.attrIf isMobile Ui.alignRight
                ]
                [ case SeqDict.get roomId model.recordings of
                    Just _ ->
                        MyUi.simpleButton
                            (Dom.id "voiceChat_downloadRecording")
                            (PressedDownloadRecording roomId)
                            (Ui.text "Download recording")

                    Nothing ->
                        Ui.none
                , deviceDropdown isMobile "Microphone" Icons.microphone audioDevices model.selectedAudioInputDevice SelectedAudioInputDevice
                , deviceDropdown isMobile "Camera" Icons.camera videoDevices model.selectedVideoInputDevice SelectedVideoInputDevice
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

        PressedCopyError _ ->
            True

        ChangedVolume _ _ ->
            False

        MouseEnterVideoNode _ ->
            False

        MouseExitVideoNode _ ->
            False


deviceDropdown :
    Bool
    -> String
    -> Html msg
    -> List MediaDevice
    -> Maybe (IdString MediaDeviceId)
    -> (IdString MediaDeviceId -> msg)
    -> Element msg
deviceDropdown isMobile labelText icon devices selected onSelect =
    Ui.row
        [ Ui.spacing 8 ]
        [ Ui.html icon
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
                , Html.Attributes.style "padding"
                    (if isMobile then
                        "4px"

                     else
                        "7px 8px"
                    )
                , Html.Attributes.style "border" "1px solid rgb(97,104,124)"
                , Html.Attributes.style "border-radius" "4px"
                , Html.Attributes.style "font-size"
                    (if isMobile then
                        "14px"

                     else
                        "16px"
                    )
                , Html.Attributes.style "background-color" "rgb(32,40,70)"
                , Html.Attributes.style "color" "rgb(255,255,255)"
                , Html.Attributes.style "cursor" "pointer"
                , Html.Attributes.attribute "aria-label" labelText
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


sidebarOffsetAttr : ChannelSidebarMode -> { a | windowSize : Coord CssPixels } -> Int
sidebarOffsetAttr sidebarMode model =
    let
        width : Int
        width =
            Coord.xRaw model.windowSize
    in
    (case sidebarMode of
        ChannelSidebarClosed ->
            1

        ChannelSidebarOpened ->
            0

        ChannelSidebarClosing a ->
            a.offset

        ChannelSidebarOpening a ->
            a.offset

        ChannelSidebarDragging a ->
            a.offset
    )
        * toFloat width
        |> round
