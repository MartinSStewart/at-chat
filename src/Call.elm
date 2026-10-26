port module Call exposing
    ( CallId(..)
    , ConnectionId
    , DebugRow
    , DebugSection
    , DeviceKind(..)
    , DisplayMode(..)
    , FromJs(..)
    , Local
    , LocalChange(..)
    , LocalOrConnection(..)
    , MediaDevice
    , MediaDeviceId
    , MediaDevicesStatus(..)
    , Model
    , Msg(..)
    , RecordingStatus(..)
    , RemoteCallData
    , ServerChange(..)
    , SharedCallId(..)
    , StartCallData
    , StartLocalStreamData
    , StartRecordingData
    , ToJs(..)
    , canShareScreen
    , connectionIdToString
    , conversationOffset
    , debugDataSubscription
    , defaultRemoteCallData
    , displayMode
    , displayModeChangeCmd
    , dragThumbnail
    , encodeFromJs
    , fromJs
    , fromSharedCallId
    , gotUserMediaDevices
    , init
    , initModel
    , insideThumbnail
    , isPressMsg
    , joinedUsers
    , leaveVoiceChatCmds
    , localVideoNodeId
    , memberColumnOffset
    , recordingChangeCmd
    , recordingId
    , recordingIdFromString
    , recordingIdToString
    , recordingNoticeView
    , recordingUploadView
    , serverChangeCmd
    , startCallCmd
    , startLocalStream
    , toJs
    , toSharedCallId
    , videoNodes
    , videoPosAndSize
    , view
    , voiceChatToJsCodec
    )

import Codec exposing (Codec)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import DmChannelId exposing (DmChannelId)
import Duration
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera as Lamdera exposing (ClientId)
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Time as Time
import FileStatus
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Html.Keyed
import Icons
import Id exposing (Id, UserId, VideoNodeId, Viewing_ChannelId, Viewing_DmId)
import IdString exposing (IdString)
import Json.Decode
import Json.Encode
import List.Extra
import MyUi
import NonemptyDict exposing (NonemptyDict)
import OneOrGreater exposing (OneOrGreater)
import Quantity
import Route exposing (ChannelSidebarMode(..), ChannelsVisibleOnMobile(..), Route(..), ShowChannelSettings(..))
import SeqDict exposing (SeqDict)
import SeqDictHelper
import SeqSet exposing (SeqSet)
import Ui exposing (Element)
import Ui.Font
import Ui.Prose
import Url
import User exposing (LocalUser)
import UserAgent exposing (Device(..), UserAgent)
import UserSession exposing (ChannelHeaderTab(..))


type LocalChange
    = Local_Leave Time.Posix
    | Local_SetRemoteCallData RemoteCallData
    | Local_RequestRecording
    | Local_AnswerRecording Bool
    | Local_CancelRecording


type ServerChange
    = Server_YouJoined Time.Posix CallId
    | Server_OtherJoined Time.Posix ConnectionId
    | Server_Left Time.Posix ConnectionId
    | Server_SetRemoteCallData ConnectionId RemoteCallData
    | Server_RecordingChanged CallId (Maybe RecordingStatus)


{-| A call that isn't being recorded and hasn't just had a recording turned down has no
status at all. The person who asked is taken to have allowed it.
-}
type RecordingStatus
    = AskingToRecord { requestedBy : Id UserId, requestedAt : Time.Posix, allowedBy : SeqSet (Id UserId) }
    | RecordingDeclined { requestedBy : Id UserId, declinedBy : Maybe (Id UserId), declinedAt : Time.Posix }
    | RecordingSince Time.Posix


{-| `CallId` is relative to whoever is looking at it, which makes a DM call look like two
different calls to the backend. This is the same for both people in it.
-}
type SharedCallId
    = SharedDmCall DmChannelId
    | SharedGuildCall Viewing_ChannelId


type Msg
    = SelectedAudioInputDevice (IdString MediaDeviceId)
    | SelectedVideoInputDevice (IdString MediaDeviceId)
    | PressedToggleMute
    | PressedTogglePauseVideo
    | PressedToggleScreenShare
    | PressedJoinCall CallId
    | PressedLeaveCall
    | PressedRecord
    | PressedCancelRecording
    | PressedAnswerRecording Bool
    | PressedCopyError String
    | ChangedVolume ConnectionId Float
    | MouseEnterVideoNode LocalOrConnection
    | MouseExitVideoNode LocalOrConnection
    | DoubleClickedVideoNode
    | PressedToggleDebugData
    | PolledDebugData


type alias Local =
    { currentRoom : Maybe CallId
    , voiceChats : SeqDict CallId (NonemptyDict ( Id UserId, ClientId ) RemoteCallData)
    , recordings : SeqDict CallId RecordingStatus
    }


type alias RemoteCallData =
    { audioInputEnabled : Bool, videoInputEnabled : Bool, screenShareEnabled : Bool }


defaultRemoteCallData : RemoteCallData
defaultRemoteCallData =
    { audioInputEnabled = True, videoInputEnabled = True, screenShareEnabled = False }


type alias Model =
    { userMediaDevices : MediaDevicesStatus
    , selectedAudioInputDevice : Maybe (IdString MediaDeviceId)
    , selectedVideoInputDevice : Maybe (IdString MediaDeviceId)
    , remoteCallData : RemoteCallData
    , isSpeaking : SeqSet ConnectionId
    , localIsSpeaking : Bool
    , startConnectionError : Maybe String
    , volume : SeqDict ( Id UserId, ClientId ) Float
    , videoHover : Maybe LocalOrConnection
    , -- Thumbnail coordinate ranges from 0 to 1. Actual pixel position is derived by multiplying this by the windowSize
      thumbnailPosition : ( Float, Float )
    , pollDebugData : Bool
    , debugData : List DebugSection
    , recordingUpload : Maybe { uploaded : Int, total : Int }
    }


type MediaDevicesStatus
    = MediaDevicesNotLoaded
    | HasMediaDevices (List MediaDevice)
    | FailedToGetMediaDevices String


init :
    SeqDict CallId (NonemptyDict ( Id UserId, ClientId ) RemoteCallData)
    -> SeqDict CallId RecordingStatus
    -> Local
init voiceChats recordings =
    { currentRoom = Nothing
    , voiceChats = voiceChats
    , recordings = recordings
    }


toSharedCallId : Id UserId -> CallId -> SharedCallId
toSharedCallId currentUserId callId =
    case callId of
        DmRoomId id ->
            SharedDmCall (DmChannelId.fromUserIds currentUserId id.otherUserId)

        GuildRoomId id ->
            SharedGuildCall id


fromSharedCallId : Id UserId -> SharedCallId -> Maybe CallId
fromSharedCallId currentUserId sharedCallId =
    case sharedCallId of
        SharedDmCall dmChannelId ->
            case DmChannelId.otherUserId currentUserId dmChannelId of
                Just otherUserId ->
                    Just (DmRoomId { otherUserId = otherUserId })

                Nothing ->
                    Nothing

        SharedGuildCall id ->
            Just (GuildRoomId id)


{-| Everyone in a call and how many of their devices have joined it. The current user
is only known to be in it through `currentRoom`, so they're counted from that.
-}
joinedUsers : Id UserId -> CallId -> Local -> SeqDict (Id UserId) OneOrGreater
joinedUsers currentUserId roomId calls =
    let
        others : SeqDict (Id UserId) OneOrGreater
        others =
            case SeqDict.get roomId calls.voiceChats of
                Just voiceChat ->
                    NonemptyDict.foldl
                        (\( userId, _ ) _ dict -> SeqDictHelper.increment userId dict)
                        SeqDict.empty
                        voiceChat

                Nothing ->
                    SeqDict.empty
    in
    if calls.currentRoom == Just roomId then
        SeqDictHelper.increment currentUserId others

    else
        others


initModel : Model
initModel =
    { userMediaDevices = MediaDevicesNotLoaded
    , selectedAudioInputDevice = Nothing
    , selectedVideoInputDevice = Nothing
    , remoteCallData = defaultRemoteCallData
    , isSpeaking = SeqSet.empty
    , localIsSpeaking = False
    , startConnectionError = Nothing
    , volume = SeqDict.empty
    , videoHover = Nothing
    , thumbnailPosition = ( 1, 0.1 )
    , pollDebugData = False
    , debugData = []
    , recordingUpload = Nothing
    }


thumbnailPosition : Bool -> Coord CssPixels -> Model -> Coord CssPixels
thumbnailPosition isMobile windowSize model =
    let
        ( x, y ) =
            model.thumbnailPosition
    in
    Coord.xy
        (round (toFloat (Coord.xRaw windowSize - thumbnailWindowWidth isMobile) * x))
        (round ((toFloat (Coord.yRaw windowSize) - thumbnailWindowWidth isMobile / aspectRatio) * y))


{-| Move the thumbnail by the given drag delta (in CSS pixels). The stored
position is normalized to 0..1, so we divide the pixel delta by the range the
thumbnail can travel and clamp it back into bounds.
-}
dragThumbnail : Bool -> { x : Float, y : Float } -> Coord CssPixels -> Model -> Model
dragThumbnail isMobile delta windowSize model =
    let
        ( x, y ) =
            model.thumbnailPosition

        availableWidth : Float
        availableWidth =
            toFloat (Coord.xRaw windowSize - thumbnailWindowWidth isMobile)

        availableHeight : Float
        availableHeight =
            toFloat (Coord.yRaw windowSize) - thumbnailWindowWidth isMobile / aspectRatio
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


thumbnailWindowWidth : Bool -> number
thumbnailWindowWidth isMobile =
    if isMobile then
        200

    else
        300


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
    = DmRoomId Viewing_DmId
    | GuildRoomId Viewing_ChannelId


type DisplayMode
    = NoVideo
    | ShowLocalVideo CallId
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

        ShowLocalVideo _ ->
            True

        ShowLocalVideoAndCall _ ->
            True

        ShowLocalVideoAndCallThumbnail _ ->
            True


displayMode : Bool -> Id UserId -> Route -> Local -> DisplayMode
displayMode isMobile currentUserId route local =
    let
        thumbnailOrNoVideo =
            case local.currentRoom of
                Just currentRoom ->
                    ShowLocalVideoAndCallThumbnail currentRoom

                Nothing ->
                    NoVideo
    in
    case route of
        HomePageRoute _ ->
            thumbnailOrNoVideo

        AdminRoute _ ->
            thumbnailOrNoVideo

        NewGuildRoute ->
            thumbnailOrNoVideo

        GuildRoute guildId channelRoute channelsVisible _ ->
            -- Only mobile puts the channel list over the conversation the videos are laid
            -- out on top of, so only mobile can leave them with nothing to sit on
            case ( isMobile, channelsVisible ) of
                ( True, ChannelsVisibleOnMobile ) ->
                    thumbnailOrNoVideo

                _ ->
                    case channelRoute of
                        Route.ChannelRoute channelId _ tab ->
                            let
                                roomId =
                                    GuildRoomId { guildId = guildId, channelId = channelId }

                                isTabExpanded =
                                    tab == Just ChannelHeaderTab_VoiceChat
                            in
                            if Just roomId == local.currentRoom && isTabExpanded then
                                case SeqDict.get roomId local.voiceChats of
                                    Just _ ->
                                        ShowLocalVideoAndCall roomId

                                    Nothing ->
                                        ShowLocalVideo roomId

                            else if isTabExpanded then
                                ShowLocalVideo roomId

                            else
                                thumbnailOrNoVideo

                        Route.NewChannelRoute ->
                            thumbnailOrNoVideo

                        Route.GuildSettingsRoute ->
                            thumbnailOrNoVideo

                        Route.JoinRoute _ ->
                            thumbnailOrNoVideo

        DiscordGuildRoute _ ->
            thumbnailOrNoVideo

        DmRoute dmRoute ->
            -- Only mobile puts the friends list over the conversation the videos are laid
            -- out on top of, so only mobile can leave them with nothing to sit on
            case ( isMobile, dmRoute.channelsVisible ) of
                ( True, ChannelsVisibleOnMobile ) ->
                    thumbnailOrNoVideo

                _ ->
                    case DmChannelId.otherUserId currentUserId dmRoute.channelId of
                        Just otherUserId ->
                            let
                                roomId =
                                    DmRoomId { otherUserId = otherUserId }

                                isTabExpanded =
                                    dmRoute.tab == Just ChannelHeaderTab_VoiceChat
                            in
                            if Just roomId == local.currentRoom && isTabExpanded then
                                case SeqDict.get roomId local.voiceChats of
                                    Just _ ->
                                        ShowLocalVideoAndCall roomId

                                    Nothing ->
                                        ShowLocalVideo roomId

                            else if isTabExpanded then
                                ShowLocalVideo roomId

                            else
                                thumbnailOrNoVideo

                        Nothing ->
                            thumbnailOrNoVideo

        DiscordDmRoute _ ->
            thumbnailOrNoVideo

        SlackWorkspaceRoute _ ->
            thumbnailOrNoVideo

        SlackDmRoute _ ->
            thumbnailOrNoVideo

        AiChatRoute ->
            thumbnailOrNoVideo

        TextEditorRoute ->
            thumbnailOrNoVideo

        PrivacyRoute ->
            thumbnailOrNoVideo

        LinkDiscord _ ->
            thumbnailOrNoVideo

        PublicGoMatchRoute _ ->
            thumbnailOrNoVideo


localVideoNodeId : String
localVideoNodeId =
    "local-video"


{-| Must match LOCAL\_SCREEN\_NODE\_ID in voice-chat.js.
-}
localScreenShareNodeId : String
localScreenShareNodeId =
    "local-screen-share"


{-| Must match the screen's nodeId in voice-chat.js's addPeer.
-}
screenShareNodeId : ConnectionId -> String
screenShareNodeId connectionId =
    connectionIdToString connectionId ++ " screen"


speakingOutline : Bool -> String
speakingOutline isSpeaking =
    if isSpeaking then
        "4px solid rgb(131, 147, 167)"

    else
        "0 solid rgb(131, 147, 167)"


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
                -- The full size videos are drawn on top of the conversation view, so they
                -- travel with it while it's being swiped away
                padding + conversationOffset loggedIn.sidebarMode config

            else
                MyUi.channelAndGuildColumnWidth config.windowSize + padding

        voiceChatY =
            MyUi.channelHeaderHeight + 8

        maxWidth : Int
        maxWidth =
            MyUi.conversationWidthIgnoreScrollbar
                config.windowSize
                (case Route.toShowMembersTab config.route of
                    ( ShowChannelSettings, _ ) ->
                        True

                    ( HideChannelSettings, _ ) ->
                        False
                )
                - padding
                * 2

        maxHeight : Int
        maxHeight =
            -- The panel starts below the channel header, so only the gap between them is lost
            viewHeight config.windowSize
                - (voiceChatY - MyUi.channelHeaderHeight)
                - (if isMobile then
                    150

                   else
                    90
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

        displayMode2 : DisplayMode
        displayMode2 =
            displayMode isMobile localUser.session.userId config.route local

        viewedCall : Maybe CallId
        viewedCall =
            case displayMode2 of
                NoVideo ->
                    Nothing

                ShowLocalVideo callId ->
                    Just callId

                ShowLocalVideoAndCall callId ->
                    Just callId

                ShowLocalVideoAndCallThumbnail _ ->
                    Nothing

        -- The button that turns polling on lives in the voice chat panel, so
        -- the panel being open is also the only place it can be turned off
        -- again.
        showDebugData : Bool
        showDebugData =
            model.pollDebugData
                && (case displayMode2 of
                        NoVideo ->
                            False

                        ShowLocalVideo _ ->
                            True

                        ShowLocalVideoAndCall _ ->
                            True

                        ShowLocalVideoAndCallThumbnail _ ->
                            False
                   )
    in
    (case displayMode2 of
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

        ShowLocalVideo _ ->
            let
                tiles : List (( Coord CssPixels, Int ) -> ( String, Html Msg ))
                tiles =
                    localTiles localUser model

                list : List ( Coord CssPixels, Int )
                list =
                    posAndSizes (List.length tiles)
            in
            List.indexedMap (\index tile -> tile (getPosAndSize index list)) tiles

        ShowLocalVideoAndCall callId ->
            let
                sessions : List ( ( Id UserId, ClientId ), RemoteCallData )
                sessions =
                    case SeqDict.get callId local.voiceChats of
                        Just sessions2 ->
                            NonemptyDict.toList sessions2

                        Nothing ->
                            []

                tiles : List (( Coord CssPixels, Int ) -> ( String, Html Msg ))
                tiles =
                    localTiles localUser model
                        ++ List.concatMap
                            (\( session, data ) ->
                                let
                                    connectionId : ConnectionId
                                    connectionId =
                                        { roomId = callId, otherClientId = session }

                                    cameraTile : ( Coord CssPixels, Int ) -> ( String, Html Msg )
                                    cameraTile posAndSize =
                                        videoNode
                                            (Tuple.first session)
                                            localUser
                                            (IsConnection connectionId)
                                            data
                                            VideoNodeFullSize
                                            posAndSize
                                            (SeqSet.member connectionId model.isSpeaking)
                                            model
                                in
                                if data.screenShareEnabled then
                                    [ cameraTile, screenShareNode localUser (IsConnection connectionId) ]

                                else
                                    [ cameraTile ]
                            )
                            sessions

                list : List ( Coord CssPixels, Int )
                list =
                    posAndSizes (List.length tiles)
            in
            List.indexedMap (\index tile -> tile (getPosAndSize index list)) tiles

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
                ( thumbnailPosition isMobile config.windowSize model, thumbnailWindowWidth isMobile )
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
                            ( thumbnailPosition isMobile config.windowSize model, thumbnailWindowWidth isMobile )
                            (SeqSet.member connectionId model.isSpeaking)
                            model
                    )
                    sessions
    )
        ++ (case viewedCall of
                Just callId ->
                    case SeqDict.get callId local.recordings of
                        Just (RecordingSince _) ->
                            [ ( "call_recordingIndicator"
                              , recordingIndicator
                                    { right = Coord.xRaw config.windowSize - voiceChatX - maxWidth + padding
                                    , top = localUser.safeAreaInsetTop + voiceChatY + padding
                                    }
                              )
                            ]

                        Just (AskingToRecord _) ->
                            []

                        Just (RecordingDeclined _) ->
                            []

                        Nothing ->
                            []

                Nothing ->
                    []
           )
        ++ (if showDebugData then
                [ ( "call_debugData"
                  , debugDataView
                        { left = voiceChatX, top = localUser.safeAreaInsetTop + voiceChatY, maxHeight = maxHeight }
                        model.debugData
                  )
                ]

            else
                []
           )
        |> Html.Keyed.node "div" []


localTiles : LocalUser -> Model -> List (( Coord CssPixels, Int ) -> ( String, Html Msg ))
localTiles localUser model =
    let
        cameraTile : ( Coord CssPixels, Int ) -> ( String, Html Msg )
        cameraTile posAndSize =
            videoNode
                localUser.session.userId
                localUser
                IsLocal
                model.remoteCallData
                VideoNodeFullSize
                posAndSize
                model.localIsSpeaking
                model
    in
    if model.remoteCallData.screenShareEnabled then
        [ cameraTile, screenShareNode localUser IsLocal ]

    else
        [ cameraTile ]


{-| A recording only ends with the call, so this isn't a button.
-}
recordingIndicator : { right : Int, top : Int } -> Html msg
recordingIndicator position =
    Html.div
        [ Html.Attributes.id "voiceChat_recordingIndicator"
        , Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "right" (String.fromInt position.right ++ "px")
        , Html.Attributes.style "top" (String.fromInt position.top ++ "px")
        , Html.Attributes.style "z-index" "1000"
        , Html.Attributes.style "line-height" "0"
        , Html.Attributes.title "This call is being recorded"
        ]
        [ Icons.recording 24 ]


{-| Drawn as part of the video layer rather than inside the voice chat panel,
because the videos sit on top of that panel and would cover it.
-}
debugDataView : { left : Int, top : Int, maxHeight : Int } -> List DebugSection -> Html msg
debugDataView position sections =
    Html.div
        [ Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "left" (String.fromInt position.left ++ "px")
        , Html.Attributes.style "top" (String.fromInt position.top ++ "px")
        , Html.Attributes.style "width" "440px"
        , Html.Attributes.style "max-width" "calc(100% - 16px)"
        , Html.Attributes.style "max-height" (String.fromInt position.maxHeight ++ "px")
        , Html.Attributes.style "overflow-y" "auto"
        , Html.Attributes.style "z-index" "1000"
        , Html.Attributes.style "background-color" "rgba(0,0,0,0.85)"
        , Html.Attributes.style "color" "white"
        , Html.Attributes.style "font-family" "monospace"
        , Html.Attributes.style "font-size" "11px"
        , Html.Attributes.style "line-height" "1.5"
        , Html.Attributes.style "padding" "8px"
        , Html.Attributes.style "border-radius" "8px"
        , Html.Attributes.style "pointer-events" "auto"
        ]
        (case sections of
            [] ->
                [ Html.text "Waiting for JS to reply..." ]

            _ ->
                List.map debugSectionView sections
        )


debugSectionView : DebugSection -> Html msg
debugSectionView section =
    Html.div
        [ Html.Attributes.style "margin-bottom" "8px" ]
        (Html.div
            [ Html.Attributes.style "font-weight" "bold"
            , Html.Attributes.style "color" "rgb(150, 200, 255)"
            ]
            [ Html.text section.title ]
            :: List.map debugRowView section.rows
        )


debugRowView : DebugRow -> Html msg
debugRowView debugRow =
    Html.div
        [ Html.Attributes.style "display" "flex"
        , Html.Attributes.style "gap" "8px"
        ]
        [ Html.div
            [ Html.Attributes.style "flex" "0 0 45%"
            , Html.Attributes.style "color" "rgb(170, 180, 190)"
            , Html.Attributes.style "overflow-wrap" "anywhere"
            ]
            [ Html.text debugRow.label ]
        , Html.div
            [ Html.Attributes.style "flex" "1"
            , Html.Attributes.style "overflow-wrap" "anywhere"
            ]
            [ Html.text debugRow.value ]
        ]


insideThumbnail : Coord CssPixels -> { a | windowSize : Coord CssPixels } -> Model -> Bool
insideThumbnail coord config model =
    let
        isMobile =
            MyUi.isMobile config

        pA =
            thumbnailPosition isMobile config.windowSize model

        pB =
            Coord.addTuple_ ( thumbnailWindowWidth isMobile, round (thumbnailWindowWidth isMobile / aspectRatio) ) pA
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
         , Html.Attributes.style "top" (String.fromInt (localUser.safeAreaInsetTop + Coord.yRaw position) ++ "px")
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
            [ User.profileImageHtml (User.getUser userId localUser) ]
        , -- Our own camera is a live MediaStream, so it plays in a <video>. A peer
          -- arrives as encoded frames over the room socket, and a decoded
          -- VideoFrame can only be drawn, so peers get a <canvas> instead.
          case id of
            IsLocal ->
                Html.video
                    [ Html.Attributes.id idString
                    , Html.Attributes.style "background-color" "rgba(0,0,0)"
                    , Html.Attributes.style "width" (String.fromInt width ++ "px")
                    , Html.Attributes.style "height" (String.fromFloat height ++ "px")
                    , Html.Attributes.style "outline" (speakingOutline isSpeaking)
                    , Html.Attributes.style "transition" "outline-width 50ms ease-out"
                    , Html.Attributes.style "border-radius" "8px"
                    , Html.Attributes.style "pointer-events" "none"
                    , Html.Attributes.attribute "playsinline" ""
                    , Html.Attributes.attribute "webkit-playsinline" ""
                    ]
                    []

            IsConnection _ ->
                Html.canvas
                    [ Html.Attributes.id idString
                    , Html.Attributes.style "background-color" "rgba(0,0,0)"
                    , Html.Attributes.style "width" (String.fromInt width ++ "px")
                    , Html.Attributes.style "height" (String.fromFloat height ++ "px")
                    , Html.Attributes.style "outline" (speakingOutline isSpeaking)
                    , Html.Attributes.style "transition" "outline-width 50ms ease-out"
                    , Html.Attributes.style "border-radius" "8px"
                    , Html.Attributes.style "pointer-events" "none"
                    , Html.Attributes.style "object-fit" "cover"
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


{-| A shared screen can be any shape, so it's fitted inside the tile rather than
cropped to fill it the way a camera is.
-}
screenShareNode : LocalUser -> LocalOrConnection -> ( Coord CssPixels, Int ) -> ( String, Html Msg )
screenShareNode localUser id ( position, width ) =
    let
        height : Float
        height =
            toFloat width / aspectRatio

        idString : String
        idString =
            case id of
                IsLocal ->
                    localScreenShareNodeId

                IsConnection connectionId ->
                    screenShareNodeId connectionId

        mediaAttributes : List (Html.Attribute msg)
        mediaAttributes =
            [ Html.Attributes.id idString
            , Html.Attributes.style "background-color" "rgba(0,0,0)"
            , Html.Attributes.style "width" (String.fromInt width ++ "px")
            , Html.Attributes.style "height" (String.fromFloat height ++ "px")
            , Html.Attributes.style "border-radius" "8px"
            , Html.Attributes.style "pointer-events" "none"
            , Html.Attributes.style "object-fit" "contain"
            ]
    in
    ( idString
    , Html.div
        [ Html.Attributes.style "width" (String.fromInt width ++ "px")
        , Html.Attributes.style "height" (String.fromFloat height ++ "px")
        , Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "left" (String.fromInt (Coord.xRaw position) ++ "px")
        , Html.Attributes.style "top" (String.fromInt (localUser.safeAreaInsetTop + Coord.yRaw position) ++ "px")
        , Html.Attributes.style "pointer-events" "auto"
        ]
        [ case id of
            IsLocal ->
                Html.video
                    (Html.Attributes.attribute "playsinline" ""
                        :: Html.Attributes.attribute "webkit-playsinline" ""
                        :: mediaAttributes
                    )
                    []

            IsConnection _ ->
                Html.canvas mediaAttributes []
        , Html.div
            [ Html.Attributes.style "position" "absolute"
            , Html.Attributes.style "left" "8px"
            , Html.Attributes.style "bottom" "8px"
            , Html.Attributes.style "padding" "2px 6px"
            , Html.Attributes.style "border-radius" "4px"
            , Html.Attributes.style "background-color" "rgba(0,0,0,0.6)"
            , Html.Attributes.style "color" "white"
            , Html.Attributes.style "font-size" "14px"
            , Html.Attributes.style "max-width" "calc(100% - 28px)"
            , Html.Attributes.style "white-space" "nowrap"
            , Html.Attributes.style "overflow" "hidden"
            , Html.Attributes.style "text-overflow" "ellipsis"
            , Html.Attributes.style "pointer-events" "none"
            ]
            [ Html.text
                (case id of
                    IsLocal ->
                        "Your screen"

                    IsConnection connectionId ->
                        User.toStringAlt (Tuple.first connectionId.otherClientId) localUser ++ "'s screen"
                )
            ]
        ]
    )


green : Ui.Color
green =
    Ui.rgb 60 160 70


red : Ui.Color
red =
    MyUi.dangerRed


redBorder : Ui.Color
redBorder =
    Ui.rgb 202 92 92


viewHeight : Coord CssPixels -> Int
viewHeight windowSize =
    round (toFloat (Coord.yRaw windowSize * 2) / 3)


view : Bool -> Bool -> Coord CssPixels -> CallId -> Local -> Model -> Element Msg
view isAdmin canShareScreen2 windowSize roomId calls model =
    let
        ongoingCall : Maybe (NonemptyDict ( Id UserId, ClientId ) RemoteCallData)
        ongoingCall =
            SeqDict.get roomId calls.voiceChats

        hasJoined2 : Bool
        hasJoined2 =
            hasJoined roomId calls

        isMobile =
            MyUi.isMobileAlt windowSize

        recordingStatus : Maybe RecordingStatus
        recordingStatus =
            SeqDict.get roomId calls.recordings
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
                        Ui.paddingXY 8 0

                      else
                        Ui.paddingXY 16 8
                    , Ui.spacing 8
                    ]
                    [ mediaDeviceSelectors isMobile model
                    , Ui.row
                        [ Ui.alignRight
                        , Ui.width Ui.shrink
                        , Ui.spacing 8
                        ]
                        [ if isAdmin then
                            MyUi.simpleButton
                                (Dom.id "voiceChat_toggleDebugData")
                                PressedToggleDebugData
                                (Ui.text "Debug")

                          else
                            Ui.none
                        , if hasJoined2 && not isMobile then
                            recordButton recordingStatus

                          else
                            Ui.none
                        , MyUi.rowButton
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
                                    case recordingStatus of
                                        Just (RecordingSince _) ->
                                            "Join\u{00A0}Recorded\u{00A0}Call"

                                        Just (AskingToRecord _) ->
                                            "Join\u{00A0}Call"

                                        Just (RecordingDeclined _) ->
                                            "Join\u{00A0}Call"

                                        Nothing ->
                                            "Join\u{00A0}Call"
                              )
                                |> Ui.text
                                |> Ui.el [ Ui.move { x = 0, y = 1, z = 0 } ]
                            ]
                        , voiceChatControlButton
                            "guild_voiceChatMute"
                            (if model.remoteCallData.audioInputEnabled then
                                "Mute microphone"

                             else
                                "Unmute microphone"
                            )
                            (Ui.html Icons.microphone)
                            model.remoteCallData.audioInputEnabled
                            PressedToggleMute
                        , voiceChatControlButton
                            "guild_voiceChatPauseVideo"
                            (if model.remoteCallData.videoInputEnabled then
                                "Turn off camera"

                             else
                                "Turn on camera"
                            )
                            (Ui.html (Icons.camera 24))
                            model.remoteCallData.videoInputEnabled
                            PressedTogglePauseVideo
                        , if hasJoined2 && canShareScreen2 then
                            screenShareButton model.remoteCallData.screenShareEnabled

                          else
                            Ui.none
                        ]
                    ]
                ]
            )
        ]
        Ui.none


recordButton : Maybe RecordingStatus -> Element Msg
recordButton recordingStatus =
    let
        button : HtmlId -> Msg -> Ui.Color -> String -> Element Msg
        button htmlId onPress background label =
            MyUi.rowButton
                htmlId
                onPress
                [ Ui.spacing 8
                , Ui.background background
                , Ui.border 1
                , Ui.borderColor MyUi.inputBorder
                , Ui.rounded 99
                , Ui.height Ui.fill
                , Ui.paddingWith { left = 12, right = 16, top = 0, bottom = 0 }
                , Ui.Font.color MyUi.white
                ]
                [ Ui.el [ Ui.width (Ui.px 12), Ui.height (Ui.px 12), Ui.rounded 6, Ui.background recordRed ] Ui.none
                , Ui.el [ Ui.move { x = 0, y = 1, z = 0 } ] (Ui.text label)
                ]
    in
    case recordingStatus of
        Just (RecordingSince _) ->
            Ui.none

        Just (AskingToRecord _) ->
            button (Dom.id "voiceChat_cancelRecording") PressedCancelRecording (Ui.rgb 42 50 78) "Cancel"

        Just (RecordingDeclined _) ->
            button (Dom.id "voiceChat_record") PressedRecord (Ui.rgb 42 50 78) "Record"

        Nothing ->
            button (Dom.id "voiceChat_record") PressedRecord (Ui.rgb 42 50 78) "Record"


recordRed : Ui.Color
recordRed =
    Ui.rgb 240 60 60


{-| This device's part of a call recording only goes up while at-chat is open on it.
-}
recordingUploadView : LocalUser -> Model -> Element msg
recordingUploadView localUser model =
    case model.recordingUpload of
        Just progress ->
            let
                filled : Int
                filled =
                    if progress.total > 0 then
                        clamp 0 1000 (progress.uploaded * 1000 // progress.total)

                    else
                        0
            in
            Ui.column
                [ Ui.id "voiceChat_recordingUpload"
                , Ui.width Ui.shrink
                , Ui.widthMax 400
                , Ui.centerX
                , Ui.alignTop
                , Ui.move { x = 0, y = localUser.safeAreaInsetTop + 8, z = 0 }
                , Ui.padding 12
                , Ui.spacing 8
                , Ui.rounded 8
                , Ui.border 1
                , Ui.borderColor MyUi.border1
                , Ui.background MyUi.background1
                , Ui.Font.color MyUi.font1
                , MyUi.htmlStyle "box-shadow" "0 4px 16px rgba(0,0,0,0.4)"
                ]
                [ Ui.text
                    ("Uploading recording ("
                        ++ megabytes progress.uploaded
                        ++ " of "
                        ++ megabytes progress.total
                        ++ " MB)"
                    )
                    |> Ui.el [ Ui.Font.bold ]
                , Ui.Prose.paragraph
                    [ Ui.Font.size 14 ]
                    [ Ui.text "Please leave this page open until it's finished (if closed, uploading will be paused until reopened)." ]
                , Ui.row
                    [ Ui.height (Ui.px 6), Ui.rounded 3, Ui.clip, Ui.background MyUi.background3 ]
                    [ Ui.el [ Ui.width (Ui.portion filled), Ui.height Ui.fill, Ui.background MyUi.buttonBackground ] Ui.none
                    , Ui.el [ Ui.width (Ui.portion (1000 - filled)) ] Ui.none
                    ]
                ]

        Nothing ->
            Ui.none


megabytes : Int -> String
megabytes bytes =
    String.fromFloat (toFloat (round (toFloat bytes / (1024 * 1024) * 10)) / 10)


{-| Shown over everything, so that someone who's in the call but looking at another
channel still gets asked.
-}
recordingNoticeView : LocalUser -> Time.Posix -> Local -> Element Msg
recordingNoticeView localUser time local =
    let
        currentUserId : Id UserId
        currentUserId =
            localUser.session.userId

        notice : List (Element Msg) -> Element Msg
        notice content =
            Ui.column
                [ Ui.width Ui.shrink
                , Ui.widthMax 400
                , Ui.centerX
                , Ui.alignTop
                , Ui.move { x = 0, y = localUser.safeAreaInsetTop + MyUi.channelHeaderHeight + 16, z = 0 }
                , Ui.padding 12
                , Ui.spacing 12
                , Ui.rounded 8
                , Ui.border 1
                , Ui.borderColor MyUi.border1
                , Ui.background MyUi.background1
                , Ui.Font.color MyUi.font1
                , MyUi.htmlStyle "box-shadow" "0 4px 16px rgba(0,0,0,0.4)"
                ]
                content

        isRecent : Time.Posix -> Bool
        isRecent since =
            Duration.from since time |> Quantity.lessThan (Duration.seconds 8)
    in
    case local.currentRoom of
        Just callId ->
            case SeqDict.get callId local.recordings of
                Just (AskingToRecord asking) ->
                    if asking.requestedBy == currentUserId then
                        notice [ Ui.text "Asking everyone if this call can be recorded…" ]

                    else if SeqSet.member currentUserId asking.allowedBy then
                        notice [ Ui.text "Waiting for everyone else to allow recording…" ]

                    else
                        notice
                            [ Ui.text (User.toStringAlt asking.requestedBy localUser ++ " wants to record this call")
                                |> Ui.el [ Ui.Font.bold, MyUi.htmlStyle "word-break" "break-all" ]
                            , Ui.Prose.paragraph
                                [ Ui.Font.size 14 ]
                                [ Ui.text "Cameras, microphones, and any screen sharing will be recorded." ]
                            , Ui.row
                                [ Ui.spacing 8 ]
                                [ MyUi.simpleButton
                                    (Dom.id "voiceChat_allowRecording")
                                    (PressedAnswerRecording True)
                                    (Ui.text "Allow")
                                , MyUi.secondaryButtonTall
                                    (Dom.id "voiceChat_declineRecording")
                                    (PressedAnswerRecording False)
                                    "Decline"
                                ]
                            ]

                Just (RecordingDeclined declined) ->
                    if isRecent declined.declinedAt then
                        notice
                            [ Ui.el
                                [ MyUi.htmlStyle "word-break" "break-all" ]
                                (case declined.declinedBy of
                                    Just declinedBy ->
                                        if declinedBy == currentUserId then
                                            Ui.text "Recording wasn't started because you declined"

                                        else
                                            "Recording wasn't started because "
                                                ++ User.toStringAlt declinedBy localUser
                                                ++ " declined"
                                                |> Ui.text

                                    Nothing ->
                                        Ui.text "Recording wasn't started because not everyone answered in time"
                                )
                            ]

                    else
                        Ui.none

                Just (RecordingSince since) ->
                    if isRecent since then
                        notice [ Ui.text "This call is now being recorded" ]

                    else
                        Ui.none

                Nothing ->
                    Ui.none

        Nothing ->
            Ui.none


voiceChatControlButton : String -> String -> Element msg -> Bool -> msg -> Element msg
voiceChatControlButton htmlId title iconHtml isEnabled onPress =
    MyUi.elButton
        (Dom.id htmlId)
        onPress
        [ Ui.width (Ui.px 40)
        , Ui.height (Ui.px 40)
        , Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.rounded 20
        , MyUi.hoverText title
        , Ui.border 1
        , Ui.borderColor
            (if isEnabled then
                MyUi.inputBorder

             else
                redBorder
            )
        , Ui.background
            (if isEnabled then
                Ui.rgb 42 50 78

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


{-| Neither iOS nor Android browsers implement getDisplayMedia.
-}
canShareScreen : UserAgent -> Bool
canShareScreen userAgent =
    case userAgent.device of
        IPhone ->
            False

        IPad ->
            False

        AndroidPhone ->
            False

        AndroidTablet ->
            False

        Mobile ->
            False

        Tablet ->
            False

        Windows ->
            True

        MacOS ->
            True

        ChromeOS ->
            True

        Linux ->
            True

        Desktop ->
            True


{-| Not sharing is the usual state, so unlike the mute and camera buttons it isn't
drawn as something switched off.
-}
screenShareButton : Bool -> Element Msg
screenShareButton isSharing =
    MyUi.elButton
        (Dom.id "guild_voiceChatScreenShare")
        PressedToggleScreenShare
        [ Ui.width (Ui.px 40)
        , Ui.height (Ui.px 40)
        , Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.rounded 20
        , MyUi.hoverText
            (if isSharing then
                "Stop sharing screen"

             else
                "Share screen"
            )
        , Ui.border 1
        , Ui.borderColor MyUi.inputBorder
        , Ui.background
            (if isSharing then
                green

             else
                Ui.rgb 42 50 78
            )
        , Ui.Font.color MyUi.white
        ]
        (Ui.html Icons.screenShare)


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


serverChangeCmd : ServerChange -> Id UserId -> Local -> Model -> Command FrontendOnly toBackend msg
serverChangeCmd change _ local _ =
    case change of
        Server_YouJoined _ _ ->
            Command.none

        Server_OtherJoined _ connectionId ->
            case local.currentRoom of
                Just roomId ->
                    if roomId == connectionId.roomId then
                        toJs
                            (ToJs_PeerJoined
                                { connectionId = connectionId
                                }
                            )

                    else
                        Command.none

                _ ->
                    Command.none

        Server_Left _ connectionId ->
            toJs (ToJs_PeerLeft connectionId)

        {- Nothing arrives from somebody whose camera is off, so their canvas would
           otherwise sit there showing the last frame that did. JS is told rather
           than left to guess from the silence, which it could only do on a timer
           that a slow connection would trip.
        -}
        Server_SetRemoteCallData connectionId remoteCallData ->
            toJs (ToJs_SetPeerVideoInputEnabled connectionId remoteCallData.videoInputEnabled)

        Server_RecordingChanged _ _ ->
            Command.none


port voice_chat_to_js : Json.Encode.Value -> Cmd msg


port voice_chat_from_js : (Json.Decode.Value -> msg) -> Sub msg


type ToJs
    = ToJs_StartCall StartCallData
    | ToJs_LeaveCall
    | ToJs_PeerJoined { connectionId : ConnectionId }
    | ToJs_PeerLeft ConnectionId
    | ToJs_SetAudioInputEnabled Bool
    | ToJs_SetInput Bool (IdString MediaDeviceId)
    | ToJs_SetVideoInputEnabled Bool
    | ToJs_SetPeerVideoInputEnabled ConnectionId Bool
    | ToJs_StartScreenShare
    | ToJs_StopScreenShare
    | ToJs_GetMediaDevices
    | ToJs_StartLocalStream StartLocalStreamData
    | ToJs_StopLocalStream
    | ToJs_SetVolume ConnectionId Float
    | ToJs_DebugDataRequest
    | ToJs_StartRecording StartRecordingData
    | ToJs_StopRecording


{-| `recordingId` is the same for everyone in the recording, and files from one person
are grouped under it on their device.
-}
type alias StartRecordingData =
    { recordingId : String
    , userName : String
    }


startRecordingDataCodec : Codec StartRecordingData
startRecordingDataCodec =
    Codec.object StartRecordingData
        |> Codec.field "recordingId" .recordingId Codec.string
        |> Codec.field "userName" .userName Codec.string
        |> Codec.buildObject


{-| The recording this device should be saving its camera, microphone and screen into,
if any.
-}
recordingId : Id UserId -> Local -> Maybe String
recordingId currentUserId local =
    case local.currentRoom of
        Just callId ->
            case SeqDict.get callId local.recordings of
                Just (RecordingSince since) ->
                    Just (recordingIdToString (toSharedCallId currentUserId callId) since)

                Just (AskingToRecord _) ->
                    Nothing

                Just (RecordingDeclined _) ->
                    Nothing

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


{-| The rust server keeps a recording's uploads in a folder with this name, so it has to
stay something that's safe as a folder name.
-}
recordingIdToString : SharedCallId -> Time.Posix -> String
recordingIdToString sharedCallId startedAt =
    (case sharedCallId of
        SharedDmCall dmChannelId ->
            "dm-" ++ DmChannelId.toString dmChannelId

        SharedGuildCall id ->
            "guild-" ++ Id.toString id.guildId ++ "-" ++ Id.toString id.channelId
    )
        ++ "-"
        ++ String.fromInt (Time.posixToMillis startedAt)


recordingIdFromString : String -> Maybe ( SharedCallId, Time.Posix )
recordingIdFromString text =
    case String.split "-" text of
        [ "dm", userIdA, userIdB, startedAt ] ->
            case ( Id.fromString userIdA, Id.fromString userIdB, String.toInt startedAt ) of
                ( Just userIdA2, Just userIdB2, Just startedAt2 ) ->
                    Just ( SharedDmCall (DmChannelId.fromUserIds userIdA2 userIdB2), Time.millisToPosix startedAt2 )

                _ ->
                    Nothing

        [ "guild", guildId, channelId, startedAt ] ->
            case ( Id.fromString guildId, Id.fromString channelId, String.toInt startedAt ) of
                ( Just guildId2, Just channelId2, Just startedAt2 ) ->
                    Just ( SharedGuildCall { guildId = guildId2, channelId = channelId2 }, Time.millisToPosix startedAt2 )

                _ ->
                    Nothing

        _ ->
            Nothing


recordingChangeCmd : String -> Maybe String -> Maybe String -> Command FrontendOnly toMsg msg
recordingChangeCmd userName recordingIdOld recordingIdNew =
    if recordingIdOld == recordingIdNew then
        Command.none

    else
        case recordingIdNew of
            Just recordingId2 ->
                toJs (ToJs_StartRecording { recordingId = recordingId2, userName = userName })

            Nothing ->
                toJs ToJs_StopRecording


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
    , websocketUrl : String
    , selfId : ( Id UserId, ClientId )
    , audioInput : Maybe (IdString MediaDeviceId)
    , videoInput : Maybe (IdString MediaDeviceId)
    , audioInputEnabled : Bool
    , videoInputEnabled : Bool
    }


startCallDataCodec : Codec StartCallData
startCallDataCodec =
    Codec.object StartCallData
        |> Codec.field "roomId" .roomId roomIdCodec
        |> Codec.field "websocketUrl" .websocketUrl Codec.string
        |> Codec.field "selfId" .selfId otherClientIdCodec
        |> Codec.field "audioInput" .audioInput (Codec.nullable IdString.codec)
        |> Codec.field "videoInput" .videoInput (Codec.nullable IdString.codec)
        |> Codec.field "audioInputEnabled" .audioInputEnabled Codec.bool
        |> Codec.field "videoInputEnabled" .videoInputEnabled Codec.bool
        |> Codec.buildObject


peerJoinedArgsCodec : Codec { connectionId : ConnectionId }
peerJoinedArgsCodec =
    Codec.object (\c -> { connectionId = c })
        |> Codec.field "connectionId" .connectionId connectionIdCodec
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
        (\eA eB eC eD eF eG eH eI eO eP eJ eK eL eM eN eQ eR value ->
            case value of
                ToJs_StartCall a ->
                    eA a

                ToJs_LeaveCall ->
                    eB

                ToJs_PeerJoined a ->
                    eC a

                ToJs_PeerLeft a ->
                    eD a

                ToJs_SetAudioInputEnabled a ->
                    eF a

                ToJs_SetInput a b ->
                    eG a b

                ToJs_SetVideoInputEnabled a ->
                    eH a

                ToJs_SetPeerVideoInputEnabled a b ->
                    eI a b

                ToJs_StartScreenShare ->
                    eO

                ToJs_StopScreenShare ->
                    eP

                ToJs_GetMediaDevices ->
                    eJ

                ToJs_StartLocalStream a ->
                    eK a

                ToJs_StopLocalStream ->
                    eL

                ToJs_SetVolume a b ->
                    eM a b

                ToJs_DebugDataRequest ->
                    eN

                ToJs_StartRecording a ->
                    eQ a

                ToJs_StopRecording ->
                    eR
        )
        |> Codec.variant1 "start-call" ToJs_StartCall startCallDataCodec
        |> Codec.variant0 "leave-call" ToJs_LeaveCall
        |> Codec.variant1 "peer-joined" ToJs_PeerJoined peerJoinedArgsCodec
        |> Codec.variant1 "peer-left" ToJs_PeerLeft connectionIdCodec
        |> Codec.variant1 "set-audio-input-enabled" ToJs_SetAudioInputEnabled Codec.bool
        |> Codec.variant2 "set-input" ToJs_SetInput Codec.bool IdString.codec
        |> Codec.variant1 "set-video-input-enabled" ToJs_SetVideoInputEnabled Codec.bool
        |> Codec.variant2 "set-peer-video-input-enabled" ToJs_SetPeerVideoInputEnabled connectionIdCodec Codec.bool
        |> Codec.variant0 "start-screen-share" ToJs_StartScreenShare
        |> Codec.variant0 "stop-screen-share" ToJs_StopScreenShare
        |> Codec.variant0 "get-media-devices" ToJs_GetMediaDevices
        |> Codec.variant1 "start-local-stream" ToJs_StartLocalStream startLocalStreamDataCodec
        |> Codec.variant0 "stop-local-stream" ToJs_StopLocalStream
        |> Codec.variant2 "set-volume" ToJs_SetVolume connectionIdCodec Codec.float
        |> Codec.variant0 "debug-data-request" ToJs_DebugDataRequest
        |> Codec.variant1 "start-recording" ToJs_StartRecording startRecordingDataCodec
        |> Codec.variant0 "stop-recording" ToJs_StopRecording
        |> Codec.buildCustom


toJs : ToJs -> Command FrontendOnly toMsg msg
toJs msg =
    Command.sendToJs
        "voice_chat_to_js"
        voice_chat_to_js
        (Codec.encoder voiceChatToJsCodec msg)


{-| The room both ends of a DM connect to has to be named the same way by both of
them, so it is the `DmChannelId`, which is derived from the pair of user ids and
doesn't depend on who is asking. `CallId` names the _other_ person, so it would
have named a different room at each end.
-}
startCallCmd : CallId -> Id UserId -> ClientId -> Model -> Command FrontendOnly toMsg msg
startCallCmd roomId userId clientId model =
    { roomId = roomId
    , websocketUrl =
        FileStatus.websocketDomain
            ++ "/file/websocket/"
            ++ Url.percentEncode
                (case roomId of
                    DmRoomId { otherUserId } ->
                        DmChannelId.fromUserIds userId otherUserId |> DmChannelId.toString

                    GuildRoomId id ->
                        "guild-" ++ Id.toString id.guildId ++ "-" ++ Id.toString id.channelId
                )
            ++ "?clientId="
            ++ Url.percentEncode (Lamdera.clientIdToString clientId)
    , selfId = ( userId, clientId )
    , audioInput = model.selectedAudioInputDevice
    , videoInput = model.selectedVideoInputDevice
    , audioInputEnabled = model.remoteCallData.audioInputEnabled
    , videoInputEnabled = model.remoteCallData.videoInputEnabled
    }
        |> ToJs_StartCall
        |> toJs


type MediaDeviceId
    = MediaDeviceId Never


type FromJs
    = FromJs_GotUserMediaDevices (List MediaDevice) (List (IdString MediaDeviceId))
    | FromJs_GotUserMediaDevicesError String
    | FromJs_SpeakingChanged LocalOrConnection Bool
    | FromJs_StartConnectionError String
    | FromJs_DebugData (List DebugSection)
    | FromJs_ScreenShareStarted
    | FromJs_ScreenShareStopped
    | FromJs_RecordingUploadProgress Int Int
    | FromJs_RecordingUploadsStopped


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
        (\cEncoder dEncoder eEncoder fEncoder gEncoder hEncoder iEncoder jEncoder kEncoder value ->
            case value of
                FromJs_GotUserMediaDevices a b ->
                    cEncoder a b

                FromJs_GotUserMediaDevicesError string ->
                    dEncoder string

                FromJs_SpeakingChanged a b ->
                    eEncoder a b

                FromJs_StartConnectionError string ->
                    fEncoder string

                FromJs_DebugData a ->
                    gEncoder a

                FromJs_ScreenShareStarted ->
                    hEncoder

                FromJs_ScreenShareStopped ->
                    iEncoder

                FromJs_RecordingUploadProgress uploaded total ->
                    jEncoder uploaded total

                FromJs_RecordingUploadsStopped ->
                    kEncoder
        )
        |> Codec.variant2 "got-media-devices" FromJs_GotUserMediaDevices (Codec.list mediaDevicesCodec) (Codec.list IdString.codec)
        |> Codec.variant1 "got-media-devices-error" FromJs_GotUserMediaDevicesError Codec.string
        |> Codec.variant2 "is-speaking-changed" FromJs_SpeakingChanged localOrConnectionCodec Codec.bool
        |> Codec.variant1 "start-connection-error" FromJs_StartConnectionError Codec.string
        |> Codec.variant1 "debug-data" FromJs_DebugData (Codec.list debugSectionCodec)
        |> Codec.variant0 "screen-share-started" FromJs_ScreenShareStarted
        |> Codec.variant0 "screen-share-stopped" FromJs_ScreenShareStopped
        |> Codec.variant2 "recording-upload-progress" FromJs_RecordingUploadProgress Codec.int Codec.int
        |> Codec.variant0 "recording-uploads-stopped" FromJs_RecordingUploadsStopped
        |> Codec.buildCustom


{-| Whatever JS knows about the call it is running, as text it has already
formatted. Elm only draws this, so JS can add to it without anything here
changing.
-}
type alias DebugSection =
    { title : String, rows : List DebugRow }


type alias DebugRow =
    { label : String, value : String }


debugSectionCodec : Codec DebugSection
debugSectionCodec =
    Codec.object DebugSection
        |> Codec.field "title" .title Codec.string
        |> Codec.field "rows" .rows (Codec.list debugRowCodec)
        |> Codec.buildObject


debugRowCodec : Codec DebugRow
debugRowCodec =
    Codec.object DebugRow
        |> Codec.field "label" .label Codec.string
        |> Codec.field "value" .value Codec.string
        |> Codec.buildObject


{-| JS has no way to announce that something about the call changed, so seeing
it change means asking again on a timer.
-}
debugDataSubscription : Model -> Subscription FrontendOnly Msg
debugDataSubscription model =
    if model.pollDebugData then
        Time.every (Duration.milliseconds 500) (\_ -> PolledDebugData)

    else
        Subscription.none


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
        DmRoomId { otherUserId } ->
            Id.toString otherUserId

        GuildRoomId { guildId, channelId } ->
            "guild-" ++ Id.toString guildId ++ "-" ++ Id.toString channelId
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
            case String.split "-" text of
                [ "guild", guildId, channelId ] ->
                    case ( Id.fromString guildId, Id.fromString channelId ) of
                        ( Just guildId2, Just channelId2 ) ->
                            Codec.succeed (GuildRoomId { guildId = guildId2, channelId = channelId2 })

                        _ ->
                            Codec.fail ("Invalid roomId: " ++ text)

                _ ->
                    case Id.fromString text of
                        Just id ->
                            Codec.succeed (DmRoomId { otherUserId = id })

                        Nothing ->
                            Codec.fail ("Invalid roomId: " ++ text)
        )
        (\roomId ->
            case roomId of
                DmRoomId { otherUserId } ->
                    Id.toString otherUserId

                GuildRoomId { guildId, channelId } ->
                    "guild-" ++ Id.toString guildId ++ "-" ++ Id.toString channelId
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


mediaDeviceSelectors : Bool -> Model -> Element Msg
mediaDeviceSelectors isMobile model =
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
                [ deviceDropdown
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

        PressedToggleScreenShare ->
            True

        PressedJoinCall _ ->
            True

        PressedLeaveCall ->
            True

        PressedRecord ->
            True

        PressedCancelRecording ->
            True

        PressedAnswerRecording _ ->
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

        PressedToggleDebugData ->
            True

        PolledDebugData ->
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
                , Html.Attributes.style "border" ("1px solid " ++ MyUi.colorToStyle MyUi.inputBorder)
                , Html.Attributes.style "border-radius" "4px"
                , Html.Attributes.style "font-size"
                    (if isMobile then
                        "14px"

                     else
                        "16px"
                    )
                , Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.background2)
                , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.white)
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


{-| The mobile layout is three screens laid out left to right that the offset slides
along: the member column at 0, the conversation view at 1 and the guild's channel list at

1.  Each screen sits where it is until the offset reaches it, then slides off to the right.

-}
memberColumnOffset : ChannelSidebarMode -> { a | windowSize : Coord CssPixels } -> Int
memberColumnOffset sidebarMode model =
    clamp 0 1 (sidebarOffset sidebarMode)
        * toFloat (Coord.xRaw model.windowSize)
        |> round


{-| See `memberColumnOffset`. The conversation view is the middle of the three, so it sits
still until the member column has finished sliding off it.
-}
conversationOffset : ChannelSidebarMode -> { a | windowSize : Coord CssPixels } -> Int
conversationOffset sidebarMode model =
    clamp 0 1 (sidebarOffset sidebarMode - 1)
        * toFloat (Coord.xRaw model.windowSize)
        |> round


sidebarOffset : ChannelSidebarMode -> Float
sidebarOffset sidebarMode =
    case sidebarMode of
        ChannelSidebarNotDragging a ->
            a.offset

        ChannelSidebarDragging a ->
            a.offset
