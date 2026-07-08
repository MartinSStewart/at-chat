port module Call exposing
    ( CallError(..)
    , CallId(..)
    , ChannelSidebarMode(..)
    , ConnectionId
    , DeviceKind(..)
    , DisplayMode(..)
    , ExistingPeer
    , FromJs(..)
    , Local
    , LocalChange(..)
    , LocalOrConnection(..)
    , MediaDevice
    , MediaDeviceId
    , MediaDevicesStatus(..)
    , Model
    , Msg(..)
    , PublishResult
    , Recording
    , RemoteCallData
    , ServerChange(..)
    , StartCallData
    , StartLocalStreamData
    , ToJs(..)
    , defaultRemoteCallData
    , displayMode
    , displayModeChangeCmd
    , dragThumbnail
    , encodeFromJs
    , fromJs
    , gotUserMediaDevices
    , init
    , initModel
    , insideThumbnail
    , isPressMsg
    , leaveVoiceChatCmds
    , serverChangeCmd
    , sidebarOffsetAttr
    , startCallCmd
    , startLocalStream
    , toJs
    , videoNodes
    , videoPosAndSize
    , view
    , voiceChatToJsCodec
    )

import Bytes exposing (Bytes)
import Cloudflare
import Codec exposing (Codec)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import DmChannelId
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
import Id exposing (Id, UserId, VideoNodeId)
import IdString exposing (IdString)
import Json.Decode
import Json.Encode
import List.Extra
import List.Nonempty exposing (Nonempty)
import MyUi
import NonemptyDict exposing (NonemptyDict)
import Route exposing (ChannelHeaderTab(..), Route(..))
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Ui exposing (Element)
import Ui.Font
import User exposing (LocalUser)
import UserSession exposing (ToBeFilledInByBackend)


type LocalChange
    = Local_Join Time.Posix CallId (ToBeFilledInByBackend (Result () (List ExistingPeer)))
    | Local_Leave Time.Posix
    | Local_PublishTracks Cloudflare.Sdp (List String) (ToBeFilledInByBackend PublishResult)
    | Local_PublishConnected
    | Local_PullTracks ConnectionId Cloudflare.RealtimeSessionId (List Cloudflare.TrackName) (ToBeFilledInByBackend (Result () Cloudflare.PullTracksResult))
    | Local_RenegotiateAnswer Cloudflare.Sdp (ToBeFilledInByBackend (Result () ()))
    | Local_SetRemoteCallData RemoteCallData


type ServerChange
    = Server_Joined Time.Posix ConnectionId Cloudflare.RealtimeSessionId (List Cloudflare.TrackName)
    | Server_Joining Time.Posix ConnectionId
    | Server_Left Time.Posix ConnectionId
    | Server_SetRemoteCallData ConnectionId RemoteCallData


type alias ExistingPeer =
    { connectionId : ConnectionId
    , sessionId : Cloudflare.RealtimeSessionId
    , trackNames : List Cloudflare.TrackName
    }


type alias PublishResult =
    { answerSdp : Cloudflare.Sdp
    , sessionId : Cloudflare.RealtimeSessionId
    , trackNames : List Cloudflare.TrackName
    }


existingPeerCodec : Codec ExistingPeer
existingPeerCodec =
    Codec.object ExistingPeer
        |> Codec.field "connectionId" .connectionId connectionIdCodec
        |> Codec.field "sessionId" .sessionId Cloudflare.sessionIdCodec
        |> Codec.field "trackNames" .trackNames (Codec.list Cloudflare.trackNameCodec)
        |> Codec.buildObject


type Msg
    = SelectedAudioInputDevice (IdString MediaDeviceId)
    | SelectedVideoInputDevice (IdString MediaDeviceId)
    | PressedToggleMute
    | PressedTogglePauseVideo
    | PressedJoinCall CallId
    | PressedLeaveCall
    | PressedDownloadRecording CallId
    | PressedCopyError String
    | ChangedVolume ConnectionId Float
    | MouseEnterVideoNode LocalOrConnection
    | MouseExitVideoNode LocalOrConnection
    | DoubleClickedVideoNode


type alias Local =
    { currentRoom : Maybe CallId
    , voiceChats : SeqDict CallId (NonemptyDict ( Id UserId, ClientId ) RemoteCallData)
    , error : Maybe CallError
    }


type alias RemoteCallData =
    { audioInputEnabled : Bool, videoInputEnabled : Bool }


defaultRemoteCallData : RemoteCallData
defaultRemoteCallData =
    { audioInputEnabled = True, videoInputEnabled = True }


type CallError
    = MissingApiKeys
    | FailedToPullTracks
    | FailedToRenegotiate


type alias Model =
    { userMediaDevices : MediaDevicesStatus
    , selectedAudioInputDevice : Maybe (IdString MediaDeviceId)
    , selectedVideoInputDevice : Maybe (IdString MediaDeviceId)
    , remoteCallData : RemoteCallData
    , isSpeaking : SeqSet ConnectionId
    , recordings : SeqDict CallId (Nonempty Recording)
    , localIsSpeaking : Bool
    , startConnectionError : Maybe String
    , volume : SeqDict ( Id UserId, ClientId ) Float
    , videoHover : Maybe LocalOrConnection
    , -- Thumbnail coordinate ranges from 0 to 1. Actual pixel position is derived by multiplying this by the windowSize
      thumbnailPosition : ( Float, Float )
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


init : SeqDict CallId (NonemptyDict ( Id UserId, ClientId ) RemoteCallData) -> Local
init voiceChats =
    { currentRoom = Nothing
    , voiceChats = voiceChats
    , error = Nothing
    }


initModel : Model
initModel =
    { userMediaDevices = MediaDevicesNotLoaded
    , selectedAudioInputDevice = Nothing
    , selectedVideoInputDevice = Nothing
    , remoteCallData = defaultRemoteCallData
    , isSpeaking = SeqSet.empty
    , recordings = SeqDict.empty
    , localIsSpeaking = False
    , startConnectionError = Nothing
    , volume = SeqDict.empty
    , videoHover = Nothing
    , thumbnailPosition = ( 1, 0.1 )
    }


thumbnailPosition : Coord CssPixels -> Model -> Coord CssPixels
thumbnailPosition windowSize model =
    let
        ( x, y ) =
            model.thumbnailPosition
    in
    Coord.xy
        (round (toFloat (Coord.xRaw windowSize - thumbnailWindowWidth) * x))
        (round ((toFloat (Coord.yRaw windowSize) - thumbnailWindowWidth / aspectRatio) * y))


{-| Move the thumbnail by the given drag delta (in CSS pixels). The stored
position is normalized to 0..1, so we divide the pixel delta by the range the
thumbnail can travel and clamp it back into bounds.
-}
dragThumbnail : { x : Float, y : Float } -> Coord CssPixels -> Model -> Model
dragThumbnail delta windowSize model =
    let
        ( x, y ) =
            model.thumbnailPosition

        availableWidth : Float
        availableWidth =
            toFloat (Coord.xRaw windowSize - thumbnailWindowWidth)

        availableHeight : Float
        availableHeight =
            toFloat (Coord.yRaw windowSize) - thumbnailWindowWidth / aspectRatio
    in
    { model
        | thumbnailPosition =
            ( if availableWidth > 0 then
                clamp 0 1 (x + delta.x / availableWidth)

              else
                x
            , if availableHeight > 0 then
                clamp 0 1 (y + delta.y / availableHeight)

              else
                y
            )
    }


thumbnailWindowWidth : number
thumbnailWindowWidth =
    200


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
    { roomId : CallId, otherClientId : ( Id UserId, ClientId ) }


type CallId
    = DmRoomId (Id UserId)


type DisplayMode
    = NoVideo
    | ShowLocalVideo
    | ShowLocalVideoAndCall CallId
    | ShowLocalVideoAndCallThumbnail CallId


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
                , audioInputEnabled = model.remoteCallData.audioInputEnabled
                , videoInputEnabled = model.remoteCallData.videoInputEnabled
                }
                |> toJs


showLocalVideo : DisplayMode -> Bool
showLocalVideo displayMode2 =
    case displayMode2 of
        NoVideo ->
            False

        ShowLocalVideo ->
            True

        ShowLocalVideoAndCall _ ->
            True

        ShowLocalVideoAndCallThumbnail _ ->
            True


displayMode : Id UserId -> Route -> Local -> DisplayMode
displayMode currentUserId route local =
    let
        thumbnailOrNoVideo =
            case local.currentRoom of
                Just currentRoom ->
                    ShowLocalVideoAndCallThumbnail currentRoom

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
            case DmChannelId.otherUserId currentUserId dmRoute.channelId of
                Just otherUserId ->
                    let
                        roomId =
                            DmRoomId otherUserId

                        isTabExpanded =
                            dmRoute.tab == Just ChannelHeaderTab_VoiceChat
                    in
                    if Just roomId == local.currentRoom && isTabExpanded then
                        case SeqDict.get roomId local.voiceChats of
                            Just _ ->
                                ShowLocalVideoAndCall roomId

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

        PublicGoMatchRoute _ ->
            thumbnailOrNoVideo


localVideoNodeId : String
localVideoNodeId =
    "local-video"


type VideoNodeState
    = VideoNodeHidden
    | VideoNodeThumbnail
    | VideoNodeFullSize


videoNodes :
    LocalUser
    -> { a | windowSize : Coord CssPixels, route : Route }
    -> { b | voiceChat : Model, sidebarMode : ChannelSidebarMode }
    -> Local
    -> Html Msg
videoNodes localUser config loggedIn local =
    let
        model =
            loggedIn.voiceChat

        voiceChatX : Int
        voiceChatX =
            if isMobile then
                padding

            else
                MyUi.channelAndGuildColumnWidth config.windowSize + padding

        voiceChatY =
            MyUi.channelHeaderHeight + 4

        maxWidth : Int
        maxWidth =
            Coord.xRaw config.windowSize - voiceChatX - padding

        maxHeight : Int
        maxHeight =
            viewHeight config.windowSize
                - voiceChatY
                - (if isMobile then
                    150

                   else
                    120
                  )
                - (padding * 2)

        padding =
            8

        spacing =
            8

        posAndSizes : Int -> List ( Coord CssPixels, Int )
        posAndSizes total =
            videoPosAndSize
                { containerWidth = maxWidth, containerHeight = maxHeight, spacing = spacing }
                (List.range 1 total |> List.map (\index -> { id = Id.fromInt index, aspectRatio = aspectRatio }))
                |> List.map (\a -> ( Coord.xy (a.x + voiceChatX) (a.y + voiceChatY), a.width ))

        getPosAndSize index list =
            List.Extra.getAt index list |> Maybe.withDefault ( Coord.origin, 100 )

        isMobile : Bool
        isMobile =
            MyUi.isMobile { windowSize = config.windowSize }
    in
    (case displayMode localUser.session.userId config.route local of
        NoVideo ->
            [ videoNode
                localUser.session.userId
                localUser
                IsLocal
                model.remoteCallData
                VideoNodeHidden
                (getPosAndSize 0 (posAndSizes 1))
                model.localIsSpeaking
                model
            ]

        ShowLocalVideo ->
            [ videoNode
                localUser.session.userId
                localUser
                IsLocal
                model.remoteCallData
                VideoNodeFullSize
                (getPosAndSize 0 (posAndSizes 1))
                model.localIsSpeaking
                model
            ]

        ShowLocalVideoAndCall callId ->
            let
                total : Int
                total =
                    List.length sessions + 1

                list : List ( Coord CssPixels, Int )
                list =
                    posAndSizes total

                sessions : List ( ( Id UserId, ClientId ), RemoteCallData )
                sessions =
                    case SeqDict.get callId local.voiceChats of
                        Just sessions2 ->
                            NonemptyDict.toList sessions2

                        Nothing ->
                            []
            in
            videoNode
                localUser.session.userId
                localUser
                IsLocal
                model.remoteCallData
                VideoNodeFullSize
                (getPosAndSize 0 list)
                model.localIsSpeaking
                model
                :: List.indexedMap
                    (\index ( session, data ) ->
                        let
                            connectionId : ConnectionId
                            connectionId =
                                { roomId = callId, otherClientId = session }
                        in
                        videoNode
                            (Tuple.first session)
                            localUser
                            (IsConnection connectionId)
                            data
                            VideoNodeFullSize
                            (getPosAndSize (index + 1) list)
                            (SeqSet.member connectionId model.isSpeaking)
                            model
                    )
                    sessions

        ShowLocalVideoAndCallThumbnail callId ->
            let
                visibleIndex : Int
                visibleIndex =
                    case sessions of
                        [] ->
                            0

                        _ ->
                            1

                sessions : List ( ( Id UserId, ClientId ), RemoteCallData )
                sessions =
                    case SeqDict.get callId local.voiceChats of
                        Just sessions2 ->
                            NonemptyDict.toList sessions2

                        Nothing ->
                            []
            in
            videoNode
                localUser.session.userId
                localUser
                IsLocal
                model.remoteCallData
                (if visibleIndex == 0 then
                    VideoNodeThumbnail

                 else
                    VideoNodeHidden
                )
                ( thumbnailPosition config.windowSize model, thumbnailWindowWidth )
                model.localIsSpeaking
                model
                :: List.indexedMap
                    (\index ( session, data ) ->
                        let
                            connectionId : ConnectionId
                            connectionId =
                                { roomId = callId, otherClientId = session }
                        in
                        videoNode
                            (Tuple.first session)
                            localUser
                            (IsConnection connectionId)
                            data
                            (if visibleIndex == (index + 1) then
                                VideoNodeThumbnail

                             else
                                VideoNodeHidden
                            )
                            ( thumbnailPosition config.windowSize model, thumbnailWindowWidth )
                            (SeqSet.member connectionId model.isSpeaking)
                            model
                    )
                    sessions
    )
        |> Html.Keyed.node "div" []


insideThumbnail : Coord CssPixels -> { a | windowSize : Coord CssPixels } -> Model -> Bool
insideThumbnail coord config model =
    let
        pA =
            thumbnailPosition config.windowSize model

        pB =
            Coord.addTuple_ ( thumbnailWindowWidth, round (thumbnailWindowWidth / aspectRatio) ) pA
    in
    Coord.maximum pA coord == coord && Coord.minimum pB coord == coord


aspectRatio : Float
aspectRatio =
    16 / 9


videoPosAndSize :
    { containerWidth : Int, containerHeight : Int, spacing : Int }
    -> List { id : Id VideoNodeId, aspectRatio : Float }
    -> List { id : Id VideoNodeId, x : Int, y : Int, width : Int, height : Int }
videoPosAndSize container videos =
    let
        count : Int
        count =
            List.length videos
    in
    if count == 0 then
        []

    else
        let
            bestCols : Int
            bestCols =
                List.range 1 count
                    |> List.Extra.maximumBy
                        (\cols -> layoutScore container videos cols)
                    |> Maybe.withDefault 1
        in
        layoutVideos container videos bestCols


layoutScore :
    { containerWidth : Int, containerHeight : Int, spacing : Int }
    -> List { a | aspectRatio : Float }
    -> Int
    -> Float
layoutScore container videos cols =
    let
        rows : Int
        rows =
            (List.length videos + cols - 1) // cols

        spacing : Float
        spacing =
            toFloat container.spacing

        cellWidth : Float
        cellWidth =
            (toFloat container.containerWidth - toFloat (cols - 1) * spacing) / toFloat cols

        cellHeight : Float
        cellHeight =
            (toFloat container.containerHeight - toFloat (rows - 1) * spacing) / toFloat rows
    in
    if cellWidth <= 0 || cellHeight <= 0 then
        0

    else
        List.foldl
            (\video total ->
                let
                    fittedWidth : Float
                    fittedWidth =
                        min cellWidth (cellHeight * video.aspectRatio)

                    fittedHeight : Float
                    fittedHeight =
                        fittedWidth / video.aspectRatio
                in
                total + fittedWidth * fittedHeight
            )
            0
            videos


layoutVideos :
    { containerWidth : Int, containerHeight : Int, spacing : Int }
    -> List { id : Id VideoNodeId, aspectRatio : Float }
    -> Int
    -> List { id : Id VideoNodeId, x : Int, y : Int, width : Int, height : Int }
layoutVideos container videos cols =
    let
        count : Int
        count =
            List.length videos

        rows : Int
        rows =
            (count + cols - 1) // cols

        spacing : Float
        spacing =
            toFloat container.spacing

        rowBudget : Float
        rowBudget =
            (toFloat container.containerHeight - toFloat (rows - 1) * spacing) / toFloat rows

        videoRows : List (List { id : Id VideoNodeId, aspectRatio : Float })
        videoRows =
            List.Extra.greedyGroupsOf cols videos

        rowHeight : List { id : Id VideoNodeId, aspectRatio : Float } -> Float
        rowHeight rowVideos =
            let
                k : Int
                k =
                    List.length rowVideos

                sumAspectRatio : Float
                sumAspectRatio =
                    List.sum (List.map .aspectRatio rowVideos)

                availableWidth : Float
                availableWidth =
                    toFloat container.containerWidth - toFloat (k - 1) * spacing
            in
            if sumAspectRatio <= 0 || availableWidth <= 0 then
                0

            else
                min rowBudget (availableWidth / sumAspectRatio)

        rowsWithHeights : List ( List { id : Id VideoNodeId, aspectRatio : Float }, Float )
        rowsWithHeights =
            List.map (\rowVideos -> ( rowVideos, rowHeight rowVideos )) videoRows

        totalHeight : Float
        totalHeight =
            List.sum (List.map Tuple.second rowsWithHeights) + toFloat (rows - 1) * spacing

        yStart : Float
        yStart =
            (toFloat container.containerHeight - totalHeight) / 2

        layoutRow : ( List { id : Id VideoNodeId, aspectRatio : Float }, Float ) -> ( Float, List { id : Id VideoNodeId, x : Int, y : Int, width : Int, height : Int } ) -> ( Float, List { id : Id VideoNodeId, x : Int, y : Int, width : Int, height : Int } )
        layoutRow ( rowVideos, height ) ( y, acc ) =
            let
                k : Int
                k =
                    List.length rowVideos

                rowWidth : Float
                rowWidth =
                    height * List.sum (List.map .aspectRatio rowVideos) + toFloat (k - 1) * spacing

                xStart : Float
                xStart =
                    (toFloat container.containerWidth - rowWidth) / 2

                ( _, rowResults ) =
                    List.foldl
                        (\video ( x, list ) ->
                            let
                                w : Float
                                w =
                                    height * video.aspectRatio
                            in
                            ( x + w + spacing
                            , { id = video.id
                              , x = round x
                              , y = round y
                              , width = round w
                              , height = round height
                              }
                                :: list
                            )
                        )
                        ( xStart, [] )
                        rowVideos
            in
            ( y + height + spacing, rowResults ++ acc )
    in
    List.foldl layoutRow ( yStart, [] ) rowsWithHeights
        |> Tuple.second
        |> List.reverse


videoNode :
    Id UserId
    -> LocalUser
    -> LocalOrConnection
    -> RemoteCallData
    -> VideoNodeState
    -> ( Coord CssPixels, Int )
    -> Bool
    -> Model
    -> ( String, Html Msg )
videoNode userId localUser id remoteCallData videoNodeState ( position, width ) isSpeaking model =
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
        ([ Html.Attributes.style "width" (String.fromInt width ++ "px")
         , Html.Attributes.style "height" (String.fromFloat height ++ "px")
         , Html.Attributes.style "position" "absolute"
         , Html.Attributes.style "left" (String.fromInt (Coord.xRaw position) ++ "px")
         , Html.Attributes.style "top" ("calc(" ++ MyUi.insetTop ++ " + " ++ String.fromInt (Coord.yRaw position) ++ "px)")
         , Html.Attributes.style
            "pointer-events"
            (if videoNodeState == VideoNodeHidden then
                "none"

             else
                "auto"
            )
         , Html.Events.onDoubleClick DoubleClickedVideoNode
         , Html.Events.onMouseEnter (MouseEnterVideoNode id)
         , Html.Events.onMouseLeave (MouseExitVideoNode id)
         , Html.Attributes.style
            "opacity"
            (if videoNodeState == VideoNodeHidden then
                "0"

             else
                "1"
            )
         ]
            ++ (case videoNodeState of
                    VideoNodeThumbnail ->
                        [ Html.Attributes.id "call_videoThumbnail" ]

                    VideoNodeHidden ->
                        []

                    VideoNodeFullSize ->
                        []
               )
        )
        [ Html.div
            [ Html.Attributes.style "position" "absolute"
            , Html.Attributes.style "left" (String.fromInt ((width - User.profileImageSize) // 2) ++ "px")
            , Html.Attributes.style "top" (String.fromFloat ((height - User.profileImageSize) / 2) ++ "px")
            , Html.Attributes.style
                "opacity"
                (if remoteCallData.videoInputEnabled then
                    "0"

                 else
                    "0.8"
                )
            , Html.Attributes.style "pointer-events" "none"
            ]
            [ User.profileImageHtml userId (User.getUser userId localUser |> Maybe.andThen .icon) ]
        , Html.video
            [ Html.Attributes.id idString
            , Html.Attributes.style "background-color" "rgba(0,0,0)"
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
        , case ( id, videoNodeState ) of
            ( IsConnection connectionId, VideoNodeFullSize ) ->
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
                        model.videoHover == Just id
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
                        , Html.Attributes.attribute "orient" "vertical"
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

            _ ->
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


view : Coord CssPixels -> CallId -> Local -> Model -> Element Msg
view windowSize roomId calls model =
    let
        ongoingCall : Maybe (NonemptyDict ( Id UserId, ClientId ) RemoteCallData)
        ongoingCall =
            SeqDict.get roomId calls.voiceChats

        hasJoined2 : Bool
        hasJoined2 =
            hasJoined roomId calls

        isMobile =
            MyUi.isMobileAlt windowSize
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
                [ case calls.error of
                    Just callError ->
                        MyUi.errorBox
                            (Dom.id "voiceChat_errorBox")
                            PressedCopyError
                            (case callError of
                                MissingApiKeys ->
                                    "Call API keys missing. Admin needs to add them."

                                FailedToPullTracks ->
                                    "Failed to pull remote audio/video tracks."

                                FailedToRenegotiate ->
                                    "Failed to renegotiate connection."
                            )
                            |> Ui.el [ Ui.paddingXY 16 0 ]

                    Nothing ->
                        case model.startConnectionError of
                            Just error ->
                                MyUi.errorBox (Dom.id "voiceChat_errorBox") PressedCopyError error |> Ui.el [ Ui.paddingXY 16 0 ]

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
                            (if hasJoined2 then
                                Dom.id "guild_leaveVoiceChat"

                             else
                                Dom.id "guild_startVoiceChat"
                            )
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
                            model.remoteCallData.audioInputEnabled
                            PressedToggleMute
                        , voiceChatControlButton
                            "guild_voiceChatPauseVideo"
                            (Ui.html (Icons.camera 24))
                            model.remoteCallData.videoInputEnabled
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


hasJoined : CallId -> Local -> Bool
hasJoined roomId model =
    model.currentRoom == Just roomId


leaveVoiceChatCmds : Local -> Command FrontendOnly toMsg msg
leaveVoiceChatCmds model =
    case model.currentRoom of
        Just _ ->
            toJs ToJs_LeaveCall

        Nothing ->
            Command.none


serverChangeCmd : ServerChange -> ClientId -> Id UserId -> Local -> Model -> Command FrontendOnly toBackend msg
serverChangeCmd change _ _ local _ =
    case change of
        Server_Joined _ connectionId sessionId trackNames ->
            case local.currentRoom of
                Just roomId ->
                    if roomId == connectionId.roomId then
                        toJs
                            (ToJs_PeerJoined
                                { connectionId = connectionId
                                , sessionId = sessionId
                                , trackNames = trackNames
                                }
                            )

                    else
                        Command.none

                Nothing ->
                    Command.none

        Server_Joining _ _ ->
            Command.none

        Server_Left _ connectionId ->
            toJs (ToJs_PeerLeft connectionId)

        Server_SetRemoteCallData _ _ ->
            Command.none


port voice_chat_to_js : Json.Encode.Value -> Cmd msg


port voice_chat_from_js : (Json.Decode.Value -> msg) -> Sub msg


type ToJs
    = ToJs_StartCall StartCallData
    | ToJs_LeaveCall
    | ToJs_PublishAnswer { answerSdp : Cloudflare.Sdp }
    | ToJs_PeerJoined { connectionId : ConnectionId, sessionId : Cloudflare.RealtimeSessionId, trackNames : List Cloudflare.TrackName }
    | ToJs_PeerLeft ConnectionId
    | ToJs_AcceptPullOffer { connectionId : ConnectionId, offerSdp : Cloudflare.Sdp }
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
        , audioInputEnabled = model.remoteCallData.audioInputEnabled
        , videoInputEnabled = model.remoteCallData.videoInputEnabled
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


type alias StartCallData =
    { roomId : CallId
    , audioInput : Maybe (IdString MediaDeviceId)
    , videoInput : Maybe (IdString MediaDeviceId)
    , audioInputEnabled : Bool
    , videoInputEnabled : Bool
    , existingPeers : List ExistingPeer
    }


startCallDataCodec : Codec StartCallData
startCallDataCodec =
    Codec.object StartCallData
        |> Codec.field "roomId" .roomId roomIdCodec
        |> Codec.field "audioInput" .audioInput (Codec.nullable IdString.codec)
        |> Codec.field "videoInput" .videoInput (Codec.nullable IdString.codec)
        |> Codec.field "audioInputEnabled" .audioInputEnabled Codec.bool
        |> Codec.field "videoInputEnabled" .videoInputEnabled Codec.bool
        |> Codec.field "existingPeers" .existingPeers (Codec.list existingPeerCodec)
        |> Codec.buildObject


publishAnswerArgsCodec : Codec { answerSdp : Cloudflare.Sdp }
publishAnswerArgsCodec =
    Codec.object (\sdp -> { answerSdp = sdp })
        |> Codec.field "answerSdp" .answerSdp Cloudflare.sdpCodec
        |> Codec.buildObject


peerJoinedArgsCodec : Codec { connectionId : ConnectionId, sessionId : Cloudflare.RealtimeSessionId, trackNames : List Cloudflare.TrackName }
peerJoinedArgsCodec =
    Codec.object (\c s t -> { connectionId = c, sessionId = s, trackNames = t })
        |> Codec.field "connectionId" .connectionId connectionIdCodec
        |> Codec.field "sessionId" .sessionId Cloudflare.sessionIdCodec
        |> Codec.field "trackNames" .trackNames (Codec.list Cloudflare.trackNameCodec)
        |> Codec.buildObject


pullOfferArgsCodec : Codec { connectionId : ConnectionId, offerSdp : Cloudflare.Sdp }
pullOfferArgsCodec =
    Codec.object (\c s -> { connectionId = c, offerSdp = s })
        |> Codec.field "connectionId" .connectionId connectionIdCodec
        |> Codec.field "offerSdp" .offerSdp Cloudflare.sdpCodec
        |> Codec.buildObject



--roomIdCodec : Codec RoomId
--roomIdCodec =
--    Codec.custom
--        (\dmEncoder value ->
--            case value of
--                DmRoomId a ->
--                    dmEncoder a
--        )
--        |> Codec.variant1 "dm" DmRoomId (Codec.map Id.fromInt Id.toInt Codec.int)
--        |> Codec.buildCustom


voiceChatToJsCodec : Codec ToJs
voiceChatToJsCodec =
    Codec.custom
        (\eStartCall eLeaveCall ePublishAnswer ePeerJoined ePeerLeft eAcceptPullOffer eSetMuted eSetAudioInput eSetVideoPaused eGetMediaDevices eStartLocalStream eStopLocalStream eSetVolume value ->
            case value of
                ToJs_StartCall a ->
                    eStartCall a

                ToJs_LeaveCall ->
                    eLeaveCall

                ToJs_PublishAnswer a ->
                    ePublishAnswer a

                ToJs_PeerJoined a ->
                    ePeerJoined a

                ToJs_PeerLeft a ->
                    ePeerLeft a

                ToJs_AcceptPullOffer a ->
                    eAcceptPullOffer a

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
        |> Codec.variant1 "start-call" ToJs_StartCall startCallDataCodec
        |> Codec.variant0 "leave-call" ToJs_LeaveCall
        |> Codec.variant1 "publish-answer" ToJs_PublishAnswer publishAnswerArgsCodec
        |> Codec.variant1 "peer-joined" ToJs_PeerJoined peerJoinedArgsCodec
        |> Codec.variant1 "peer-left" ToJs_PeerLeft connectionIdCodec
        |> Codec.variant1 "accept-pull-offer" ToJs_AcceptPullOffer pullOfferArgsCodec
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


startCallCmd : CallId -> List ExistingPeer -> Model -> Command FrontendOnly toMsg msg
startCallCmd roomId existingPeers model =
    { roomId = roomId
    , audioInput = model.selectedAudioInputDevice
    , videoInput = model.selectedVideoInputDevice
    , audioInputEnabled = model.remoteCallData.audioInputEnabled
    , videoInputEnabled = model.remoteCallData.videoInputEnabled
    , existingPeers = existingPeers
    }
        |> ToJs_StartCall
        |> toJs


type MediaDeviceId
    = MediaDeviceId Never


type FromJs
    = FromJs_PublishOffer Cloudflare.Sdp (List String)
    | FromJs_PublishConnected
    | FromJs_PullAnswer ConnectionId Cloudflare.Sdp
    | FromJs_RequestPullTracks ConnectionId Cloudflare.RealtimeSessionId (List Cloudflare.TrackName)
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
        (\ePublishOffer ePublishConnected ePullAnswer eRequestPull cEncoder dEncoder eEncoder fEncoder value ->
            case value of
                FromJs_PublishOffer sdp mids ->
                    ePublishOffer sdp mids

                FromJs_PublishConnected ->
                    ePublishConnected

                FromJs_PullAnswer connId sdp ->
                    ePullAnswer connId sdp

                FromJs_RequestPullTracks connId sessId trackNames ->
                    eRequestPull connId sessId trackNames

                FromJs_GotUserMediaDevices a b ->
                    cEncoder a b

                FromJs_GotUserMediaDevicesError string ->
                    dEncoder string

                FromJs_SpeakingChanged a b ->
                    eEncoder a b

                FromJs_StartConnectionError string ->
                    fEncoder string
        )
        |> Codec.variant2 "publish-offer" FromJs_PublishOffer Cloudflare.sdpCodec (Codec.list Codec.string)
        |> Codec.variant0 "publish-connected" FromJs_PublishConnected
        |> Codec.variant2 "pull-answer" FromJs_PullAnswer connectionIdCodec Cloudflare.sdpCodec
        |> Codec.variant3 "request-pull-tracks" FromJs_RequestPullTracks connectionIdCodec Cloudflare.sessionIdCodec (Codec.list Cloudflare.trackNameCodec)
        |> Codec.variant2 "got-media-devices" FromJs_GotUserMediaDevices (Codec.list mediaDevicesCodec) (Codec.list IdString.codec)
        |> Codec.variant1 "got-media-devices-error" FromJs_GotUserMediaDevicesError Codec.string
        |> Codec.variant2 "is-speaking-changed" FromJs_SpeakingChanged localOrConnectionCodec Codec.bool
        |> Codec.variant1 "start-connection-error" FromJs_StartConnectionError Codec.string
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


encodeFromJs : FromJs -> Json.Encode.Value
encodeFromJs value =
    Codec.encodeToValue voiceChatFromJsCodec value


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


otherUserIdToString : ( Id UserId, ClientId ) -> String
otherUserIdToString otherClientId =
    Id.toString (Tuple.first otherClientId) ++ " " ++ Lamdera.clientIdToString (Tuple.second otherClientId)


connectionIdToString : ConnectionId -> String
connectionIdToString { roomId, otherClientId } =
    (case roomId of
        DmRoomId otherUserId ->
            Id.toString otherUserId
    )
        ++ " "
        ++ otherUserIdToString otherClientId


connectionIdFromString : String -> Result () ( Id UserId, ClientId )
connectionIdFromString text =
    case String.split " " text of
        second :: rest0 :: rest ->
            case String.toInt second of
                Just userId ->
                    Ok ( Id.fromInt userId, Lamdera.clientIdFromString (String.join " " (rest0 :: rest)) )

                _ ->
                    Err ()

        _ ->
            Err ()


otherClientIdCodec : Codec ( Id UserId, ClientId )
otherClientIdCodec =
    Codec.andThen
        (\text ->
            case connectionIdFromString text of
                Ok id ->
                    Codec.succeed id

                Err () ->
                    Codec.fail ("Invalid roomId: " ++ text)
        )
        otherUserIdToString
        Codec.string


roomIdCodec : Codec CallId
roomIdCodec =
    Codec.andThen
        (\text ->
            case Id.fromString text of
                Just id ->
                    Codec.succeed (DmRoomId id)

                Nothing ->
                    Codec.fail ("Invalid roomId: " ++ text)
        )
        (\roomId ->
            case roomId of
                DmRoomId otherUserId ->
                    Id.toString otherUserId
        )
        Codec.string


connectionIdCodec : Codec ConnectionId
connectionIdCodec =
    Codec.object ConnectionId
        |> Codec.field "roomId" .roomId roomIdCodec
        |> Codec.field "otherClientId" .otherClientId otherClientIdCodec
        |> Codec.buildObject



--Codec.andThen
--    (\text ->
--        case connectionIdFromString text of
--            Ok ok ->
--                Codec.succeed ok
--
--            Err () ->
--                Codec.fail ("Invalid connectionId: " ++ text)
--    )
--    connectionIdToString
--    Codec.string


mediaDeviceSelectors : Bool -> CallId -> Model -> Element Msg
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
                , deviceDropdown
                    isMobile
                    "Microphone"
                    Icons.microphone
                    audioDevices
                    model.selectedAudioInputDevice
                    SelectedAudioInputDevice
                , deviceDropdown
                    isMobile
                    "Camera"
                    (Icons.camera 24)
                    videoDevices
                    model.selectedVideoInputDevice
                    SelectedVideoInputDevice
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

        DoubleClickedVideoNode ->
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
