module FrontendExtra exposing
    ( audio
    , canDropFiles
    , changeUpdate
    , channelGames
    , currentGame
    , currentGamesTab
    , drawingRedo
    , drawingUndo
    , editMessage_gotFiles
    , editMessage_gotPastedText
    , externalLinkWarning
    , fileDecryptedMessages
    , fileDragOverlayOpacity
    , gotFiles
    , gotPastedText
    , handleDecryptedMessage
    , handleEscapeKey
    , handleLocalChange
    , handlePressedArrowUpInEmptyInput
    , handlePressedTextInput
    , handleRedo
    , handleServerSendMessage
    , handleUndo
    , initAdminData
    , isPressMsg
    , layout
    , logout
    , mapEncryptionRequests
    , newPrivateKeyWarning
    , pastedMessageFileName
    , pingUserNameSoFar
    , playNotificationSoundForDiscordMessage
    , routePush
    , routeReplace
    , routeRequest
    , savePrivateKeyTitle
    , setFocus
    , updateLoggedIn
    )

import AiChat
import Array
import Audio exposing (Audio, AudioData)
import Bytes.Encode
import Call exposing (CallId(..))
import ChannelDescription
import ChannelHeader
import ChannelName
import Discord
import DiscordUserData exposing (DiscordUserLoadingData(..))
import DmChannel exposing (DiscordFrontendDmChannel, E2eeStatus(..), FrontendDmChannel)
import DmChannelId
import Drawing
import Duration
import Editable
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Navigation as BrowserNavigation
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.File as File exposing (File)
import Effect.Lamdera as Lamdera
import Effect.Process as Process
import Effect.Task as Task
import Effect.Time as Time
import EmailAddress exposing (EmailAddress)
import Emoji exposing (EmojiOrCustomEmoji)
import Encryption exposing (BytesHash, EncryptedData)
import FileName
import FileStatus exposing (FileData, FileId, FileStatus(..), IsEncrypted(..))
import Game
import Go
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, StickerId, ThreadMessageId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId, Viewing_DmId)
import ImageEditor
import ImageViewer
import Json.Decode
import Json.Decode.Extra
import LinkedAndOtherDiscordUsers
import List.Extra
import List.Nonempty exposing (Nonempty)
import Local
import LocalState exposing (AdminData, AdminStatus(..), DiscordFrontendChannel, DiscordFrontendGuild, FrontendChannel, FrontendGuild, LocalState)
import LoginForm
import MembersAndOwner
import Message exposing (ChangeAttachments(..), ContentAndEmbeds, GameType(..), Message(..), MessageNoReply(..), UserTextMessageDataNoReply)
import MessageArray exposing (MessageArray)
import MessageDropdown
import MessageInput exposing (NameSoFar(..), TimestampData)
import MessageMenu
import MessageView
import MuteSettings exposing (IsMuted)
import MyUi
import NonemptyDict
import NonemptySet
import OneToOne
import Pages.Admin exposing (InitAdminData)
import Pages.Guild
import Pagination
import PersonName
import Ports exposing (RegisterPushSubscription(..))
import Range exposing (Range)
import RecoveryLogin
import RichText exposing (Domain, RichText)
import Route exposing (ChannelRoute(..), ChannelsVisibleOnMobile(..), DiscordChannelRoute(..), Route(..), ShowChannelSettings(..), ThreadRouteWithFriends(..))
import Scroll exposing (ScrollPosition(..))
import SeqDict exposing (SeqDict)
import SeqDictHelper
import SeqSet exposing (SeqSet)
import SheepGame
import Sticker exposing (StickerData)
import String.Nonempty exposing (NonemptyString)
import TextEditor
import Thread exposing (FrontendGenericThread)
import Touch exposing (Drag(..), DragTarget(..))
import TwoFactorAuthentication
import Types exposing (EmojiSelector(..), EncryptionRequests, FileDrag(..), FrontendModel_(..), FrontendMsg_(..), LoadedFrontend, LocalChange(..), LocalMsg(..), LoggedIn2, LoginStatus(..), MessageHover(..), PublicGoMatch(..), ServerChange(..), ToBackend(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Input
import Ui.Prose
import Url exposing (Url)
import User exposing (FrontendCurrentUser, FrontendUser, LocalUser, NotificationLevel(..))
import UserSession exposing (ChannelHeaderTab(..), DiscordFrontendUser, NotificationMode(..), PushSubscription(..), SetViewing(..), ToBeFilledInByBackend(..), UserSession)
import VisibleMessages
import WordSpellingGame
import X25519


savePrivateKeyTitle : String
savePrivateKeyTitle =
    "Save your private key now"


pastedMessageFileName : String
pastedMessageFileName =
    "message.txt"


{-| The messages out of what the backend fills in when a Discord channel or thread is
viewed. The two placeholders carry through rather than being treated as nothing to do, so
that a channel still waiting on its messages is marked as loading.
-}
discordViewMessages :
    ToBeFilledInByBackend (UserSession.ViewDiscordGuildData messageId)
    -> ToBeFilledInByBackend (SeqDict (Id messageId) (Message messageId (Discord.Id Discord.UserId)))
discordViewMessages backendData =
    case backendData of
        FilledInByBackend data ->
            FilledInByBackend data.messages

        EmptyPlaceholder ->
            EmptyPlaceholder


pendingChangesText : LocalChange -> String
pendingChangesText localChange =
    case localChange of
        Local_Invalid ->
            -- We should never have a invalid change in the local msg queue
            "InvalidChange"

        Local_Admin adminChange ->
            Pages.Admin.pendingChangesText adminChange

        Local_SendMessage _ _ _ _ _ _ _ ->
            "Sent a message"

        Local_Discord_SendMessage _ _ _ _ _ _ ->
            "Sent a message"

        Local_NewChannel _ _ _ _ ->
            "Created new channel"

        Local_EditChannel _ _ _ _ ->
            "Edited channel"

        Local_DeleteChannel _ _ ->
            "Deleted channel"

        Local_EditGuildName _ _ ->
            "Edited guild name"

        Local_DeleteGuild _ ->
            "Deleted guild"

        Local_LeaveGuild _ ->
            "Left guild"

        Local_NewInviteLink _ _ _ ->
            "Created invite link"

        Local_DeleteInviteLink _ _ ->
            "Deleted invite link"

        Local_NewGuild _ _ _ ->
            "Created new guild"

        Local_MemberTyping _ _ ->
            "Is typing notification"

        Local_AddReactionEmoji _ _ _ ->
            "Added reaction emoji"

        Local_RemoveReactionEmoji _ _ _ ->
            "Removed reaction emoji"

        Local_SendEditMessage _ _ _ _ _ _ ->
            "Edit message"

        Local_Discord_SendEditGuildMessage _ _ _ _ _ _ _ ->
            "Edit message"

        Local_Discord_SendEditDmMessage _ _ _ _ _ ->
            "Edit message"

        Local_MemberEditTyping _ _ _ ->
            "Editing message"

        Local_SetLastViewed _ _ ->
            "Viewed channel"

        Local_DeleteMessage _ _ ->
            "Delete message"

        Local_CurrentlyViewing _ _ ->
            "Change view"

        Local_SetName _ ->
            "Set display name"

        Local_LoadChannelMessages _ _ _ ->
            "Load channel messages"

        Local_LoadThreadMessages _ _ _ _ ->
            "Load thread messages"

        Local_Discord_LoadChannelMessages _ _ _ ->
            "Load channel messages"

        Local_Discord_LoadThreadMessages _ _ _ _ ->
            "Load thread messages"

        Local_SetGuildNotificationLevel _ notificationLevel ->
            case notificationLevel of
                NotifyOnEveryMessage ->
                    "Enabled notifications for all messages"

                NotifyOnMention ->
                    "Disabled notifications for all messages"

        Local_SetDiscordGuildNotificationLevel _ _ notificationLevel ->
            case notificationLevel of
                NotifyOnEveryMessage ->
                    "Enabled notifications for all messages"

                NotifyOnMention ->
                    "Disabled notifications for all messages"

        Local_SetNotificationMode _ ->
            "Set notification mode"

        Local_ExpandUserOptionSection _ ->
            "Expanded a user options section"

        Local_CollapseUserOptionSection _ ->
            "Collapsed a user options section"

        Local_SetSheepGameQuestions _ ->
            "Saved sheep game questions"

        Local_SetEmailNotifications _ ->
            "Set email notifications"

        Local_RegisterPushSubscription _ _ ->
            "Register push subscription"

        Local_TextEditor _ ->
            "Text editor change"

        Local_UnlinkDiscordUser _ ->
            "Unlink Discord user"

        Local_StartReloadingDiscordUser _ _ ->
            "Reload Discord user"

        Local_LinkDiscordAcknowledgementIsChecked _ ->
            "Checked link Discord account acknowledgement"

        Local_SetDomainWhitelist _ _ ->
            "Whitelist domain"

        Local_SetEmojiSkinTone _ ->
            "Selected emoji skin tone"

        Local_SetUserColor _ ->
            "Picked a colour"

        Local_AddCustomEmojisToUser _ ->
            "Add custom emojis to user"

        Local_VoiceChatChange voiceChatChange ->
            case voiceChatChange of
                Call.Local_Leave _ ->
                    "Left voice chat"

                Call.Local_SetRemoteCallData _ ->
                    "Set audio/video input enabled"

        Local_Game _ change ->
            case change of
                Game.CreatePublicLink _ _ ->
                    "Shared match"

                Game.LoadMatch _ _ ->
                    "Opened match"

                Game.LocalChange_Go _ goChange ->
                    case goChange of
                        Go.StartMatch _ _ ->
                            "Started Go match"

                        Go.Action _ ->
                            "Made a move in Go"

                Game.LocalChange_WordSpellingGame _ _ ->
                    "Word spelling game change"

                Game.LocalChange_SheepGame _ _ ->
                    "Sheep game change"

        Local_Drawing _ _ _ ->
            "Drew on a message"

        Local_SetMuteChannel _ _ _ ->
            "Changed channel notifications"

        Local_SetMuteThread _ _ _ _ ->
            "Changed thread notifications"

        Local_SetMuteDiscordChannel _ _ _ _ ->
            "Changed channel notifications"

        Local_SetMuteDiscordThread _ _ _ _ _ ->
            "Changed thread notifications"

        Local_SetMuteGuild _ _ ->
            "Set mute guild"

        Local_SetMuteDiscordGuild _ _ _ ->
            "Set mute Discord guild"

        Local_RequestE2ee _ ->
            "Asked to start end-to-end encryption"

        Local_DeclineE2eeRequestAsInitiator _ ->
            "Cancelled the end-to-end encryption request"

        Local_DeclineE2eeRequest _ ->
            "Declined the end-to-end encryption request"

        Local_SetPublicKey _ _ ->
            "Added a private key to the account"

        Local_EncryptOldMessages _ _ ->
            "Encrypted the messages written before this conversation was encrypted"

        Local_SetE2eeRisksAccepted _ ->
            "Accepted the end-to-end encryption risks"

        Local_AcceptE2ee _ _ _ ->
            "Started end-to-end encryption"

        Local_SendEncryptedMessage _ _ _ _ _ ->
            "Sent an encrypted message"


layout : LoadedFrontend -> List (Ui.Attribute FrontendMsg_) -> Element FrontendMsg_ -> Html FrontendMsg_
layout model attributes child =
    let
        isMobile =
            MyUi.isMobile model
    in
    Ui.Anim.layout
        { options = []
        , toMsg = ElmUiMsg
        , breakpoints = Nothing
        }
        model.elmUiState
        ((case model.loginStatus of
            LoggedIn loggedIn ->
                let
                    local =
                        Local.model loggedIn.localState

                    maybeMessageId : Maybe ( AnyGuildOrDmId, ThreadRoute )
                    maybeMessageId =
                        Route.toGuildOrDmId local.localUser.session.userId model.route
                in
                [ Html.Events.preventDefaultOn
                    "dragenter"
                    (Json.Decode.map2
                        (\time types ->
                            if List.member "Files" types then
                                ( Duration.milliseconds time |> FileDragEnter, True )

                            else
                                ( FrontendNoOp, False )
                        )
                        (Json.Decode.field "timeStamp" Json.Decode.float)
                        (Json.Decode.at [ "dataTransfer", "types" ] (Json.Decode.list Json.Decode.string))
                    )
                    |> Ui.htmlAttribute
                , Html.Events.preventDefaultOn "dragover" (Json.Decode.succeed ( FrontendNoOp, True )) |> Ui.htmlAttribute
                , Html.Events.preventDefaultOn "dragleave" (Json.Decode.succeed ( FileDragLeave, True )) |> Ui.htmlAttribute
                , Html.Events.preventDefaultOn "drop"
                    (Json.Decode.at [ "dataTransfer", "files" ] (Json.Decode.Extra.collection File.decoder)
                        |> Json.Decode.map (\list -> ( FileDropped list, True ))
                    )
                    |> Ui.htmlAttribute
                , Ui.inFront (fileDragOverlay loggedIn model)
                , Local.networkError
                    (\change ->
                        case change of
                            LocalChange _ localChange ->
                                pendingChangesText localChange

                            ServerChange _ ->
                                ""
                    )
                    model.time
                    loggedIn.localState
                    |> Ui.inFront
                , case maybeMessageId of
                    Just ( guildOrDmId, threadRoute ) ->
                        case loggedIn.textInputFocus of
                            Just textInputFocus ->
                                case
                                    ( pingUserNameSoFar
                                        textInputFocus.htmlId
                                        textInputFocus.selection
                                        guildOrDmId
                                        threadRoute
                                        loggedIn
                                    , textInputFocus.dropdown
                                    )
                                of
                                    ( Just nameSoFar, Just dropdown ) ->
                                        if textInputFocus.htmlId == Pages.Guild.channelTextInputId then
                                            MessageDropdown.view
                                                isMobile
                                                model.time
                                                nameSoFar
                                                guildOrDmId
                                                local.localUser.user.emojiConfig.skinTone
                                                model.emojiData
                                                local
                                                Pages.Guild.dropdownButtonId
                                                dropdown
                                                |> Ui.map (MessageInputMsg guildOrDmId threadRoute)
                                                |> Ui.inFront

                                        else if textInputFocus.htmlId == MessageMenu.editMessageTextInputId then
                                            MessageDropdown.view
                                                isMobile
                                                model.time
                                                nameSoFar
                                                guildOrDmId
                                                local.localUser.user.emojiConfig.skinTone
                                                model.emojiData
                                                local
                                                Pages.Guild.dropdownButtonId
                                                dropdown
                                                |> Ui.map (EditMessage_MessageInputMsg guildOrDmId threadRoute)
                                                |> Ui.inFront

                                        else
                                            Ui.noAttr

                                    _ ->
                                        Ui.noAttr

                            Nothing ->
                                Ui.noAttr

                    _ ->
                        Ui.noAttr
                , case loggedIn.messageHover of
                    MessageMenu extraOptions ->
                        MessageMenu.view model extraOptions local loggedIn
                            |> Ui.inFront

                    MessageHover _ _ ->
                        Ui.noAttr

                    NoMessageHover ->
                        Ui.noAttr
                ]

            NotLoggedIn _ ->
                []
         )
            ++ MyUi.notoSans
            :: Ui.id "elm-ui-root-id"
            :: Ui.height Ui.fill
            :: Ui.behindContent (Ui.html MyUi.css)
            :: Ui.behindContent
                (Ui.html
                    (Html.node
                        "style"
                        []
                        [ Html.text "body { height:100vh !important; }" ]
                    )
                )
            :: Ui.Font.size 16
            :: Ui.Font.color MyUi.font1
            :: Ui.htmlAttribute (Html.Events.onClick PressedBody)
            :: (case model.imageViewer of
                    Just imageViewer ->
                        ImageViewer.view isMobile model.windowSize imageViewer
                            |> Ui.map ImageViewerMsg
                            |> Ui.inFront

                    Nothing ->
                        Ui.noAttr
               )
            :: attributes
            ++ (if MyUi.isMobile model then
                    [ Ui.clip
                    , Html.Events.on "touchstart" (Touch.decodeTouchEvent TouchStart) |> Ui.htmlAttribute
                    , Html.Events.on "touchmove" (Touch.decodeTouchEvent TouchMoved) |> Ui.htmlAttribute
                    , Html.Events.on
                        "touchend"
                        (Json.Decode.field "timeStamp" Json.Decode.float
                            |> Json.Decode.map (\time -> Duration.milliseconds time |> TouchEnd)
                        )
                        |> Ui.htmlAttribute
                    , Html.Events.on
                        "touchcancel"
                        (Json.Decode.field "timeStamp" Json.Decode.float
                            |> Json.Decode.map (\time -> Duration.milliseconds time |> TouchCancel)
                        )
                        |> Ui.htmlAttribute
                    ]

                else
                    [ Html.Events.on "pointerdown" (Touch.decoderPointerEvent TouchStart) |> Ui.htmlAttribute
                    , case model.drag of
                        NoDrag ->
                            Ui.noAttr

                        _ ->
                            Html.Events.on "pointermove" (Touch.decoderPointerEvent TouchMoved) |> Ui.htmlAttribute
                    , Html.Events.on
                        "pointerup"
                        (Json.Decode.field "timeStamp" Json.Decode.float
                            |> Json.Decode.map (\time -> Duration.milliseconds time |> TouchEnd)
                        )
                        |> Ui.htmlAttribute
                    , Html.Events.on
                        "pointercancel"
                        (Json.Decode.field "timeStamp" Json.Decode.float
                            |> Json.Decode.map (\time -> Duration.milliseconds time |> TouchCancel)
                        )
                        |> Ui.htmlAttribute
                    ]
               )
            ++ (if disableTextSelect isMobile model then
                    [ MyUi.htmlStyle "user-select" "none"
                    , MyUi.htmlStyle "-webkit-user-select" "none"
                    ]

                else
                    []
               )
        )
        child


disableTextSelect : Bool -> LoadedFrontend -> Bool
disableTextSelect isMobile model =
    if isMobile then
        True

    else if Route.toChannelHeaderTab model.route == Just ChannelHeaderTab_Draw then
        True

    else
        case model.drag of
            NoDrag ->
                False

            DragStart _ _ ->
                False

            Dragging dragging ->
                case dragging.target of
                    Drag_CallThumbnail ->
                        True

                    Drag_Channel ->
                        False

                    Drag_Game ->
                        True


canDropFiles :
    Bool
    -> Id UserId
    -> Route
    -> Maybe (Nonempty File -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ ))
canDropFiles isMobile currentUserId route =
    case route of
        HomePageRoute ->
            Nothing

        AdminRoute _ ->
            Nothing

        NewGuildRoute ->
            Nothing

        GuildRoute guildId channelRoute channelsVisible ->
            if channelsVisible == ChannelsVisibleOnMobile && isMobile then
                Nothing

            else
                case channelRoute of
                    ChannelRoute channelId threadRoute _ ->
                        let
                            threadRoute2 : ThreadRoute
                            threadRoute2 =
                                case threadRoute of
                                    NoThreadWithFriends _ _ ->
                                        NoThread

                                    ViewThreadWithFriends threadId _ _ ->
                                        ViewThread threadId
                        in
                        canDropFileHelper (GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId })) threadRoute2 |> Just

                    NewChannelRoute ->
                        Nothing

                    GuildSettingsRoute ->
                        Nothing

                    JoinRoute _ ->
                        Nothing

        DiscordGuildRoute routeData ->
            if routeData.channelsVisible == ChannelsVisibleOnMobile && isMobile then
                Nothing

            else
                case routeData.channelRoute of
                    DiscordChannel_ChannelRoute channelId threadRoute _ ->
                        let
                            threadRoute2 : ThreadRoute
                            threadRoute2 =
                                case threadRoute of
                                    NoThreadWithFriends _ _ ->
                                        NoThread

                                    ViewThreadWithFriends threadId _ _ ->
                                        ViewThread threadId
                        in
                        canDropFileHelper
                            (DiscordGuildOrDmId
                                (DiscordGuildOrDmId_Guild { currentUserId = routeData.currentDiscordUserId, guildId = routeData.guildId, channelId = channelId })
                            )
                            threadRoute2
                            |> Just

                    DiscordChannel_NewChannelRoute ->
                        Nothing

                    DiscordChannel_GuildSettingsRoute ->
                        Nothing

        DmRoute routeData ->
            if routeData.channelsVisible == ChannelsVisibleOnMobile && isMobile then
                Nothing

            else
                case DmChannelId.otherUserId currentUserId routeData.channelId of
                    Just otherUserId ->
                        let
                            threadRoute2 : ThreadRoute
                            threadRoute2 =
                                case routeData.threadRoute of
                                    NoThreadWithFriends _ _ ->
                                        NoThread

                                    ViewThreadWithFriends threadId _ _ ->
                                        ViewThread threadId
                        in
                        canDropFileHelper (GuildOrDmId (GuildOrDmId_Dm { otherUserId = otherUserId })) threadRoute2 |> Just

                    Nothing ->
                        Nothing

        DiscordDmRoute routeData ->
            if routeData.channelsVisible == ChannelsVisibleOnMobile && isMobile then
                Nothing

            else
                canDropFileHelper
                    (DiscordGuildOrDmId
                        (DiscordGuildOrDmId_Dm
                            { currentUserId = routeData.currentDiscordUserId, channelId = routeData.channelId }
                        )
                    )
                    NoThread
                    |> Just

        AiChatRoute ->
            Nothing

        SlackOAuthRedirect _ ->
            Nothing

        TextEditorRoute ->
            Nothing

        LinkDiscord _ ->
            Nothing

        PublicGoMatchRoute _ ->
            Nothing


canDropFileHelper :
    AnyGuildOrDmId
    -> ThreadRoute
    -> Nonempty File
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
canDropFileHelper guildOrDmId threadRoute2 files model =
    case model.loginStatus of
        LoggedIn loggedIn ->
            if SeqDict.member ( guildOrDmId, threadRoute2 ) loggedIn.editMessage then
                editMessage_gotFiles ( guildOrDmId, threadRoute2 ) files model

            else
                gotFiles guildOrDmId threadRoute2 files model

        NotLoggedIn _ ->
            ( model, Command.none )


fileDragOverlay : LoggedIn2 -> LoadedFrontend -> Element FrontendMsg_
fileDragOverlay loggedIn model =
    let
        opacity =
            fileDragOverlayOpacity loggedIn model
    in
    if opacity <= 0 then
        Ui.none

    else
        let
            canDrop : Bool
            canDrop =
                canDropFiles
                    (MyUi.isMobile model)
                    (Local.model loggedIn.localState |> .localUser |> .session |> .userId)
                    model.route
                    /= Nothing

            accentColor : Ui.Color
            accentColor =
                if canDrop then
                    MyUi.font1

                else
                    MyUi.deleteButtonBackground
        in
        Ui.el
            [ Ui.height Ui.fill
            , Ui.contentCenterX
            , Ui.contentCenterY
            , Ui.Font.size 32
            , Ui.Font.bold
            , MyUi.htmlStyle "border" "8px dashed"
            , MyUi.htmlStyle "box-sizing"
                "border-box"
            , MyUi.noPointerEvents
            , Ui.background (Ui.rgba 0 0 0 0.6)
            , Ui.Font.color accentColor
            , Ui.borderColor accentColor
            , Ui.opacity opacity
            ]
            (if canDrop then
                Ui.text "Drop files anywhere to upload"

             else
                Ui.text "You can't drop the file here"
            )


fileDragOverlayOpacity : LoggedIn2 -> LoadedFrontend -> Float
fileDragOverlayOpacity loggedIn model =
    case loggedIn.fileDragOverCount of
        FileDragging dragStart _ ->
            Duration.from dragStart model.time
                |> Duration.inSeconds
                |> (*) 10
                -- AnimationFrame sub doesn't start until opacity is greater than 0 so we make sure it's always greater than 0
                |> clamp 0.01 1

        NoFileDrag (Just lastDrag) ->
            1 - (Duration.inSeconds (Duration.from lastDrag model.time) * 10) |> clamp 0 1

        NoFileDrag Nothing ->
            0


gotFiles :
    AnyGuildOrDmId
    -> ThreadRoute
    -> Nonempty File
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
gotFiles guildOrDmId threadRoute files model =
    updateLoggedIn
        (\loggedIn ->
            let
                ( fileText, cmds, dict ) =
                    case SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.filesToUpload of
                        Just dict2 ->
                            List.Nonempty.foldl
                                (\file2 ( fileText2, cmds2, dict3 ) ->
                                    let
                                        id =
                                            Id.nextId (NonemptyDict.toSeqDict dict3)
                                    in
                                    ( fileText2
                                        ++ [ RichText.attachedFilePrefix
                                                ++ Id.toString id
                                                ++ RichText.attachedFileSuffix
                                           ]
                                    , FileStatus.uploadFile
                                        (GotFileHashName ( guildOrDmId, threadRoute ) id)
                                        ( guildOrDmId, threadRoute )
                                        id
                                        file2
                                        :: cmds2
                                    , NonemptyDict.insert
                                        id
                                        (FileUploading
                                            (File.name file2 |> FileName.fromString)
                                            { sent = 0, size = File.size file2 }
                                            (File.mime file2 |> FileStatus.contentType)
                                            IsNotEncrypted
                                        )
                                        dict3
                                    )
                                )
                                ( [], [], dict2 )
                                files

                        Nothing ->
                            ( List.indexedMap
                                (\index _ ->
                                    RichText.attachedFilePrefix
                                        ++ Id.toString (Id.fromInt (index + 1))
                                        ++ RichText.attachedFileSuffix
                                )
                                (List.Nonempty.toList files)
                            , List.indexedMap
                                (\index file2 ->
                                    let
                                        id : Id FileId
                                        id =
                                            Id.fromInt (index + 1)
                                    in
                                    FileStatus.uploadFile
                                        (GotFileHashName ( guildOrDmId, threadRoute ) id)
                                        ( guildOrDmId, threadRoute )
                                        id
                                        file2
                                )
                                (List.Nonempty.toList files)
                            , List.Nonempty.indexedMap
                                (\index file2 ->
                                    ( Id.fromInt (index + 1)
                                    , FileUploading
                                        (File.name file2 |> FileName.fromString)
                                        { sent = 0, size = File.size file2 }
                                        (File.mime file2 |> FileStatus.contentType)
                                        IsNotEncrypted
                                    )
                                )
                                files
                                |> NonemptyDict.fromNonemptyList
                            )
            in
            ( { loggedIn
                | filesToUpload =
                    SeqDict.insert ( guildOrDmId, threadRoute ) dict loggedIn.filesToUpload
                , drafts =
                    case String.join " " fileText |> String.Nonempty.fromString of
                        Just fileText2 ->
                            SeqDict.update
                                ( guildOrDmId, threadRoute )
                                (\maybe ->
                                    case maybe of
                                        Just draft ->
                                            String.Nonempty.append_ draft (" " ++ String.Nonempty.toString fileText2)
                                                |> Just

                                        Nothing ->
                                            Just fileText2
                                )
                                loggedIn.drafts

                        Nothing ->
                            loggedIn.drafts
              }
            , Command.batch cmds
            )
        )
        model


{-| Pasted text that is too long to fit in a message is attached as a text file instead of being inserted into the text input.
-}
gotPastedText :
    AnyGuildOrDmId
    -> ThreadRoute
    -> { textBeforePaste : String, pastedText : String, textAfterPaste : String }
    -> LoggedIn2
    -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg_ )
gotPastedText guildOrDmId threadRoute { textBeforePaste, pastedText, textAfterPaste } loggedIn =
    let
        fileId : Id FileId
        fileId =
            case SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.filesToUpload of
                Just dict ->
                    Id.nextId (NonemptyDict.toSeqDict dict)

                Nothing ->
                    Id.fromInt 1

        draft : String
        draft =
            textBeforePaste
                ++ RichText.attachedFilePrefix
                ++ Id.toString fileId
                ++ RichText.attachedFileSuffix
                ++ textAfterPaste
    in
    ( { loggedIn
        | filesToUpload =
            SeqDict.update
                ( guildOrDmId, threadRoute )
                (\maybe ->
                    case maybe of
                        Just dict ->
                            NonemptyDict.insert fileId (pastedTextFileStatus pastedText) dict |> Just

                        Nothing ->
                            NonemptyDict.singleton fileId (pastedTextFileStatus pastedText) |> Just
                )
                loggedIn.filesToUpload
        , drafts =
            case String.Nonempty.fromString draft of
                Just nonempty ->
                    SeqDict.insert ( guildOrDmId, threadRoute ) nonempty loggedIn.drafts

                Nothing ->
                    loggedIn.drafts
      }
    , FileStatus.uploadString
        (GotFileHashName ( guildOrDmId, threadRoute ) fileId)
        ( guildOrDmId, threadRoute )
        fileId
        pastedText
    )


editMessage_gotPastedText :
    ( AnyGuildOrDmId, ThreadRoute )
    -> { textBeforePaste : String, pastedText : String, textAfterPaste : String }
    -> LoggedIn2
    -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg_ )
editMessage_gotPastedText guildOrDmId { textBeforePaste, pastedText, textAfterPaste } loggedIn =
    case SeqDict.get guildOrDmId loggedIn.editMessage of
        Just edit ->
            let
                fileId : Id FileId
                fileId =
                    Id.nextId edit.attachedFiles
            in
            ( { loggedIn
                | editMessage =
                    SeqDict.insert
                        guildOrDmId
                        { edit
                            | text =
                                textBeforePaste
                                    ++ RichText.attachedFilePrefix
                                    ++ Id.toString fileId
                                    ++ RichText.attachedFileSuffix
                                    ++ textAfterPaste
                            , attachedFiles =
                                SeqDict.insert fileId (pastedTextFileStatus pastedText) edit.attachedFiles
                        }
                        loggedIn.editMessage
                , typedTextCounter = loggedIn.typedTextCounter + 1
              }
            , FileStatus.uploadString
                (EditMessage_GotFileHashName guildOrDmId edit.messageIndex fileId)
                guildOrDmId
                fileId
                pastedText
            )

        Nothing ->
            ( loggedIn, Command.none )


pastedTextFileStatus : String -> FileStatus
pastedTextFileStatus pastedText =
    FileUploading
        (FileName.fromString pastedMessageFileName)
        { sent = 0, size = Bytes.Encode.getStringWidth pastedText }
        (FileStatus.contentType "text/plain")
        IsNotEncrypted


editMessage_gotFiles :
    ( AnyGuildOrDmId, ThreadRoute )
    -> Nonempty File
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
editMessage_gotFiles guildOrDmId files model =
    updateLoggedIn
        (\loggedIn ->
            case SeqDict.get guildOrDmId loggedIn.editMessage of
                Just edit ->
                    let
                        ( fileText, cmds, dict ) =
                            List.Nonempty.foldl
                                (\file2 ( fileText2, cmds2, dict3 ) ->
                                    let
                                        fileId : Id FileId
                                        fileId =
                                            Id.nextId dict3
                                    in
                                    ( fileText2
                                        ++ [ " "
                                                ++ RichText.attachedFilePrefix
                                                ++ Id.toString fileId
                                                ++ RichText.attachedFileSuffix
                                           ]
                                    , FileStatus.uploadFile
                                        (EditMessage_GotFileHashName guildOrDmId edit.messageIndex fileId)
                                        guildOrDmId
                                        fileId
                                        file2
                                        :: cmds2
                                    , SeqDict.insert
                                        fileId
                                        (FileUploading
                                            (File.name file2 |> FileName.fromString)
                                            { sent = 0, size = File.size file2 }
                                            (File.mime file2 |> FileStatus.contentType)
                                            IsNotEncrypted
                                        )
                                        dict3
                                    )
                                )
                                ( [], [], edit.attachedFiles )
                                files
                    in
                    ( { loggedIn
                        | editMessage =
                            SeqDict.insert
                                guildOrDmId
                                { edit
                                    | text = edit.text ++ String.concat fileText
                                    , attachedFiles = dict
                                }
                                loggedIn.editMessage
                      }
                    , Command.batch cmds
                    )

                Nothing ->
                    ( loggedIn, Command.none )
        )
        model


{-| The one and only showing of a freshly generated private key.

The key is not stored on the server, and the frontend forgets it as soon as this is
closed, so if it is not copied out now it is gone and anything encrypted to it with it.
That is the whole point of the warning being this loud.

The key sits in a password field with the account's email in a username field above it, so
the page looks to a password manager like any other place a new login was just made and it
offers to save the pair. That offer is the easiest way for this to end well, so it is
worth laying the popup out around it.

-}
newPrivateKeyWarning :
    Bool
    -> { a | lastCopied : Maybe MyUi.LastCopy }
    -> EmailAddress
    -> X25519.PrivateKey
    -> Element FrontendMsg_
newPrivateKeyWarning isMobile loaded email privateKey =
    let
        accountLabel : { element : Element FrontendMsg_, id : Ui.Input.Label }
        accountLabel =
            Ui.Input.label
                "frontend_newPrivateKeyAccount"
                [ Ui.Font.size 14, Ui.Font.color MyUi.font3, Ui.Font.bold ]
                (Ui.text "Account")
    in
    Ui.el
        [ Ui.behindContent
            (Ui.el [ Ui.background MyUi.scrim, Ui.height Ui.fill ] Ui.none)
        , Ui.height Ui.fill
        ]
        (Ui.column
            [ Ui.centerX
            , if isMobile then
                Ui.alignBottom

              else
                Ui.centerY
            , Ui.attrIf (not isMobile) (Ui.rounded 16)
            , if isMobile then
                Ui.paddingXY 16 16

              else
                Ui.paddingXY 24 24
            , Ui.background MyUi.background3
            , if isMobile then
                Ui.width Ui.fill

              else
                Ui.widthMax 600
            , Ui.width Ui.shrink
            , Ui.spacing 24
            , Ui.borderColor MyUi.border1
            , Ui.border 1
            ]
            [ Ui.column
                [ Ui.spacing 8 ]
                [ Ui.row
                    [ Ui.Font.color MyUi.font3, Ui.spacing 16, Ui.contentCenterY, Ui.Font.bold ]
                    [ Ui.html (Icons.warning 36), Ui.text savePrivateKeyTitle ]
                , Ui.Prose.paragraph
                    []
                    [ Ui.text "Put this in a password manager. It is not stored anywhere else, so this is the only chance you have to save it. Without it your encrypted messages can't be decrypted." ]
                ]
            , Ui.column
                [ Ui.spacing 12 ]
                [ Ui.column
                    [ Ui.spacing 2 ]
                    [ accountLabel.element
                    , Ui.Input.username
                        [ Ui.paddingWith { left = 8, right = 8, top = 2, bottom = 2 }
                        , Ui.htmlAttribute (Html.Attributes.readonly True)
                        , Ui.background (Ui.rgba 0 0 0 0.2)
                        , Ui.border 1
                        , Ui.borderColor MyUi.inputBorder
                        , Ui.rounded 4
                        , Ui.height (Ui.px 40)
                        ]
                        { onChange = \_ -> FrontendNoOp
                        , text = EmailAddress.toString email
                        , placeholder = Nothing
                        , label = accountLabel.id
                        }
                    ]
                , MyUi.newPasswordCopyBox
                    (Dom.id "frontend_newPrivateKey")
                    "Private key"
                    PressedCopyText
                    FrontendNoOp
                    loaded
                    (X25519.privateKeyToString privateKey)
                ]
            , MyUi.secondaryButton
                (Dom.id "frontend_closeNewPrivateKey")
                PressedCloseNewPrivateKey
                "I've saved it"
            ]
        )


externalLinkWarning : SeqSet Domain -> Bool -> Url -> Element FrontendMsg_
externalLinkWarning domainWhitelist isMobile url =
    let
        urlText =
            Url.toString url

        label =
            Ui.Input.label
                "frontend_addDomainToWhitelist"
                [ MyUi.htmlStyle "cursor" "pointer", Ui.paddingLeft 12 ]
                (Ui.Prose.paragraph
                    [ Ui.paddingXY 0 4 ]
                    [ Ui.el [ Ui.Font.color MyUi.font3 ] (Ui.text "Don't ask again about links to ")
                    , Ui.el [ Ui.Font.noWrap ] (Ui.text url.host)
                    ]
                )
    in
    Ui.el
        [ Ui.behindContent
            (Ui.el
                [ Ui.background MyUi.scrim
                , Ui.height Ui.fill
                , Ui.Events.onClick PressedCloseExternalLinkWarning
                ]
                Ui.none
            )
        , Ui.height Ui.fill
        ]
        (Ui.column
            [ Ui.centerX
            , if isMobile then
                Ui.alignBottom

              else
                Ui.centerY
            , Ui.attrIf (not isMobile) (Ui.rounded 16)
            , if isMobile then
                Ui.paddingXY 16 16

              else
                Ui.paddingXY 24 24
            , Ui.background MyUi.background3
            , if isMobile then
                Ui.width Ui.fill

              else
                Ui.widthMax 600
            , Ui.width Ui.shrink
            , Ui.spacing 24
            , Ui.borderColor MyUi.border1
            , Ui.border 1
            ]
            [ Ui.column
                [ Ui.spacing 8 ]
                [ Ui.row
                    [ Ui.Font.color MyUi.font3, Ui.spacing 16, Ui.contentCenterY, Ui.Font.bold ]
                    [ Ui.html (Icons.warning 36), Ui.text "Heads up, you are leaving at-chat and going to:" ]
                , Ui.el [ MyUi.htmlStyle "word-break" "break-all" ] (Ui.text urlText)
                ]
            , Ui.row
                []
                [ Ui.Input.checkbox
                    [ Ui.Font.size 14 ]
                    { onChange = PressedAddDomainToWhitelist
                    , icon = Nothing
                    , checked = SeqSet.member (RichText.urlToDomain url) domainWhitelist
                    , label = label.id
                    }
                , label.element
                ]
            , Ui.row
                []
                [ MyUi.secondaryButtonTall
                    (Dom.id "frontend_cancelLeaveExternal")
                    PressedCloseExternalLinkWarning
                    "Back"
                , Ui.el
                    [ Ui.linkNewTab urlText
                    , Ui.Events.onClick PressedContinueToSite
                    , Ui.borderColor MyUi.buttonBorder
                    , Ui.border 1
                    , Ui.background MyUi.buttonBackground
                    , Ui.rounded 4
                    , Ui.width Ui.shrink
                    , Ui.paddingXY 16 8
                    , Ui.Font.weight 500
                    , Ui.Font.color MyUi.white
                    , MyUi.htmlStyle "text-decoration" "none"
                    , Ui.alignRight
                    ]
                    (Ui.text "Continue to site")
                ]
            ]
        )


logout : LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
logout model =
    case model.loginStatus of
        LoggedIn _ ->
            let
                model2 : LoadedFrontend
                model2 =
                    { model
                        | loginStatus =
                            NotLoggedIn
                                { loginForm = Nothing
                                , recoveryLogin = RecoveryLogin.init
                                , useInviteAfterLoggedIn = Nothing
                                , textInputFocus = Nothing
                                }
                    }
            in
            if Route.requiresLogin model2.route then
                routePush model2 HomePageRoute

            else
                ( model2, Command.none )

        NotLoggedIn _ ->
            ( model, Command.none )


isViewing : AnyGuildOrDmId -> ThreadRoute -> LocalState -> Bool
isViewing guildOrDmId threadRoute local =
    UserSession.isViewing guildOrDmId threadRoute local.localUser.currentlyViewing
        || List.any
            (\otherSession ->
                List.any
                    (UserSession.isViewing guildOrDmId threadRoute)
                    (SeqDict.values otherSession.currentlyViewing)
            )
            (SeqDict.values local.otherSessions)


playNotificationSound :
    Id UserId
    -> GuildOrDmId
    -> ThreadRouteWithMaybeMessage
    ->
        { a
            | messages : MessageArray ChannelMessageId (Id UserId)
            , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread (Id UserId))
        }
    -> LocalState
    -> Nonempty (RichText (Id UserId))
    -> LoadedFrontend
    -> Command FrontendOnly toMsg msg
playNotificationSound senderId guildOrDmId threadRouteWithRepliedTo channel local content model =
    case local.localUser.session.notificationMode of
        NoNotifications ->
            Command.none

        NotifyWhenRunning ->
            let
                alwaysNotify : Bool
                alwaysNotify =
                    case guildOrDmId of
                        GuildOrDmId_Guild { guildId } ->
                            SeqSet.member guildId local.localUser.user.notifyOnAllMessages

                        GuildOrDmId_Dm _ ->
                            False

                isMentionedOrRepliedTo : Bool
                isMentionedOrRepliedTo =
                    LocalState.usersMentionedOrRepliedToFrontend threadRouteWithRepliedTo content channel
                        |> SeqSet.member local.localUser.session.userId
            in
            if not model.pageHasFocus && (alwaysNotify || isMentionedOrRepliedTo) then
                Command.batch
                    [ Ports.setFavicon "/favicon-red.ico"
                    , case model.startupData.notificationPermission of
                        Ports.Granted ->
                            let
                                users : SeqDict (Id UserId) FrontendUser
                                users =
                                    User.allUsers local.localUser
                            in
                            Ports.showNotification (User.toString senderId users) (RichText.toString local.localUser.timezone True users content)

                        _ ->
                            Command.none
                    ]

            else
                Command.none

        PushNotifications ->
            Command.none


playNotificationSoundForDiscordMessage :
    Discord.Id Discord.UserId
    -> DiscordGuildOrDmId
    -> ThreadRouteWithMaybeMessage
    ->
        { a
            | messages : MessageArray ChannelMessageId (Discord.Id Discord.UserId)
            , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread (Discord.Id Discord.UserId))
        }
    -> LocalState
    -> Nonempty (RichText (Discord.Id Discord.UserId))
    -> LoadedFrontend
    -> Command FrontendOnly toMsg msg
playNotificationSoundForDiscordMessage senderId guildOrDmId threadRouteWithRepliedTo channel local content model =
    case local.localUser.session.notificationMode of
        NoNotifications ->
            Command.none

        NotifyWhenRunning ->
            let
                alwaysNotify : Bool
                alwaysNotify =
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild { guildId } ->
                            SeqSet.member guildId local.localUser.user.discordNotifyOnAllMessages

                        DiscordGuildOrDmId_Dm _ ->
                            False

                isMentionedOrRepliedTo : Bool
                isMentionedOrRepliedTo =
                    LocalState.usersMentionedOrRepliedToFrontend threadRouteWithRepliedTo content channel
                        |> SeqSet.intersect
                            (SeqDict.keys (LinkedAndOtherDiscordUsers.linkedUsers local.localUser.discordUsers)
                                |> SeqSet.fromList
                            )
                        |> SeqSet.isEmpty
                        |> not

                allUsers =
                    LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers
            in
            if not model.pageHasFocus && (alwaysNotify || isMentionedOrRepliedTo) then
                Command.batch
                    [ Ports.setFavicon "/favicon-red.ico"
                    , case model.startupData.notificationPermission of
                        Ports.Granted ->
                            Ports.showNotification
                                (User.toString senderId allUsers)
                                (RichText.toString local.localUser.timezone True allUsers content)

                        _ ->
                            Command.none
                    ]

            else
                Command.none

        PushNotifications ->
            Command.none


routePush : LoadedFrontend -> Route -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
routePush model route =
    if MyUi.isMobile model then
        routeRequest (Just model.route) route model

    else
        ( model, BrowserNavigation.pushUrl model.navigationKey (Route.encode route) )


routeReplace : LoadedFrontend -> Route -> Command FrontendOnly ToBackend FrontendMsg_
routeReplace model route =
    BrowserNavigation.replaceUrl model.navigationKey (Route.encode route)


handleLocalChange :
    Time.Posix
    -> Maybe LocalChange
    -> LoggedIn2
    -> Command FrontendOnly ToBackend msg
    -> ( LoggedIn2, Command FrontendOnly ToBackend msg )
handleLocalChange time maybeLocalChange loggedIn cmds =
    case maybeLocalChange of
        Just localChange ->
            let
                ( changeId, localState2 ) =
                    Local.update
                        changeUpdate
                        time
                        (LocalChange (Local.model loggedIn.localState).localUser.session.userId localChange)
                        loggedIn.localState
            in
            ( { loggedIn | localState = localState2 }
            , Command.batch
                [ cmds
                , LocalModelChangeRequest changeId localChange |> Lamdera.sendToBackend
                ]
            )

        Nothing ->
            ( loggedIn, cmds )


routeViewingLocalChange : Bool -> Bool -> LocalState -> Route -> Maybe LocalChange
routeViewingLocalChange isMobile markMessagesAsViewed local route =
    let
        localChange : SetViewing
        localChange =
            LocalState.routeToViewing isMobile route local
    in
    if UserSession.setViewingToCurrentlyViewing localChange == local.localUser.currentlyViewing then
        Nothing

    else
        Just (Local_CurrentlyViewing { markMessagesAsViewed = markMessagesAsViewed } localChange)


clearRevealedSpoilers : LoadedFrontend -> LoadedFrontend
clearRevealedSpoilers model =
    { model
        | loginStatus =
            case model.loginStatus of
                LoggedIn loggedIn ->
                    LoggedIn { loggedIn | revealedSpoilers = SeqDict.empty }

                NotLoggedIn _ ->
                    model.loginStatus
    }


enterChannelRoute :
    AnyGuildOrDmId
    -> Maybe ChannelHeaderTab
    -> ThreadRouteWithFriends
    -> Bool
    -> Command FrontendOnly ToBackend FrontendMsg_
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
enterChannelRoute guildOrDmId tab threadRoute sameChannel viewCmd model =
    updateLoggedIn
        (\loggedIn ->
            routeRequestChannelHelper
                sameChannel
                guildOrDmId
                tab
                threadRoute
                (Local.model loggedIn.localState)
                loggedIn
                model
                |> Tuple.mapSecond (\cmd -> Command.batch [ viewCmd, cmd ])
        )
        model


routeRequest : Maybe Route -> Route -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
routeRequest previousRoute newRoute model =
    let
        markMessagesAsViewed : Bool
        markMessagesAsViewed =
            case previousRoute of
                Just oldRoute ->
                    Route.routeChangeCountsAsMessageView oldRoute newRoute

                Nothing ->
                    False

        ( model2, viewCmd ) =
            updateLoggedIn
                (\loggedIn ->
                    handleLocalChange
                        model.time
                        (routeViewingLocalChange
                            (MyUi.isMobile model)
                            markMessagesAsViewed
                            (Local.model loggedIn.localState)
                            newRoute
                        )
                        { loggedIn
                            | drawingMode =
                                if Route.toChannelHeaderTab newRoute == Just ChannelHeaderTab_Draw then
                                    loggedIn.drawingMode

                                else
                                    Drawing.init
                            , newMessagesWhileNotScrolledToBottom = 0
                        }
                        Command.none
                )
                { model | route = newRoute }
    in
    (case newRoute of
        HomePageRoute ->
            ( { model2
                | loginStatus =
                    case model2.loginStatus of
                        NotLoggedIn notLoggedIn ->
                            NotLoggedIn { notLoggedIn | loginForm = Nothing }

                        LoggedIn _ ->
                            model2.loginStatus
              }
            , Command.none
            )

        AdminRoute { highlightLog } ->
            updateLoggedIn
                (\loggedIn ->
                    let
                        admin : Pages.Admin.Model
                        admin =
                            loggedIn.admin
                    in
                    ( { loggedIn | admin = { admin | highlightLog = highlightLog }, userOptions = Nothing }
                    , case (Local.model loggedIn.localState).adminData of
                        IsAdminButDataNotLoaded ->
                            (case highlightLog of
                                Just highlightLog2 ->
                                    Pagination.itemToPageId highlightLog2 |> .pageId |> Just |> AdminDataRequest

                                Nothing ->
                                    AdminDataRequest Nothing
                            )
                                |> Lamdera.sendToBackend

                        IsAdmin _ ->
                            Command.none

                        IsNotAdmin ->
                            Command.none
                    )
                )
                model2

        NewGuildRoute ->
            -- Opening the create guild page always starts with a blank form
            updateLoggedIn (\loggedIn -> ( { loggedIn | newGuildForm = Nothing }, Command.none )) model2

        GuildRoute guildId channelRoute _ ->
            let
                model3 : LoadedFrontend
                model3 =
                    clearRevealedSpoilers model2
            in
            case channelRoute of
                ChannelRoute channelId threadRoute tab ->
                    enterChannelRoute
                        (GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId }))
                        tab
                        threadRoute
                        (case previousRoute of
                            Just (GuildRoute previousGuildId (ChannelRoute previousChannelId previousThreadRoute _) _) ->
                                (guildId == previousGuildId)
                                    && (channelId == previousChannelId)
                                    && Route.sameThread threadRoute previousThreadRoute

                            _ ->
                                False
                        )
                        Command.none
                        model3

                NewChannelRoute ->
                    ( model3, Command.none )

                GuildSettingsRoute ->
                    ( model3, Command.none )

                JoinRoute inviteLinkId ->
                    case model3.loginStatus of
                        NotLoggedIn notLoggedIn ->
                            ( { model3
                                | loginStatus =
                                    { notLoggedIn | useInviteAfterLoggedIn = Just inviteLinkId }
                                        |> NotLoggedIn
                              }
                            , Command.none
                            )

                        LoggedIn loggedIn ->
                            let
                                local =
                                    Local.model loggedIn.localState
                            in
                            ( model3
                            , Command.batch
                                [ JoinGuildByInviteRequest guildId inviteLinkId |> Lamdera.sendToBackend
                                , case SeqDict.get guildId local.guilds of
                                    Just guild ->
                                        routeReplace
                                            model3
                                            (GuildRoute
                                                guildId
                                                (ChannelRoute
                                                    (LocalState.announcementChannel guild)
                                                    (NoThreadWithFriends Nothing HideChannelSettings)
                                                    Nothing
                                                )
                                                ChannelsVisibleOnMobile
                                            )

                                    Nothing ->
                                        Command.none
                                ]
                            )

        DiscordGuildRoute { currentDiscordUserId, guildId, channelRoute } ->
            let
                model3 : LoadedFrontend
                model3 =
                    clearRevealedSpoilers model2
            in
            case channelRoute of
                DiscordChannel_ChannelRoute channelId threadRoute _ ->
                    enterChannelRoute
                        (DiscordGuildOrDmId (DiscordGuildOrDmId_Guild { currentUserId = currentDiscordUserId, guildId = guildId, channelId = channelId }))
                        Nothing
                        threadRoute
                        (case previousRoute of
                            Just (DiscordGuildRoute guildData) ->
                                case guildData.channelRoute of
                                    DiscordChannel_ChannelRoute previousChannelId previousThreadRoute _ ->
                                        (currentDiscordUserId == guildData.currentDiscordUserId)
                                            && (guildId == guildData.guildId)
                                            && (channelId == previousChannelId)
                                            && Route.sameThread threadRoute previousThreadRoute

                                    _ ->
                                        False

                            _ ->
                                False
                        )
                        Command.none
                        model3

                DiscordChannel_NewChannelRoute ->
                    ( model3, Command.none )

                DiscordChannel_GuildSettingsRoute ->
                    ( model3, Command.none )

        AiChatRoute ->
            ( model2, Command.map AiChatToBackend AiChatMsg AiChat.getModels )

        DmRoute dmRoute ->
            let
                sameDmRoute =
                    case previousRoute of
                        Just (DmRoute previousDmRoute) ->
                            dmRoute.channelId == previousDmRoute.channelId

                        _ ->
                            False

                model3 : LoadedFrontend
                model3 =
                    if sameDmRoute then
                        model2

                    else
                        clearRevealedSpoilers model2
            in
            updateLoggedIn
                (\loggedIn ->
                    let
                        local =
                            Local.model loggedIn.localState
                    in
                    case DmChannelId.otherUserId local.localUser.session.userId dmRoute.channelId of
                        Just otherUserId ->
                            routeRequestChannelHelper
                                sameDmRoute
                                (GuildOrDmId_Dm { otherUserId = otherUserId } |> GuildOrDmId)
                                dmRoute.tab
                                dmRoute.threadRoute
                                local
                                loggedIn
                                model3

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model3

        DiscordDmRoute routeData ->
            let
                sameDmRoute =
                    case previousRoute of
                        Just (DiscordDmRoute previousDmRoute) ->
                            routeData.channelId == previousDmRoute.channelId

                        _ ->
                            False

                model3 : LoadedFrontend
                model3 =
                    if sameDmRoute then
                        model2

                    else
                        clearRevealedSpoilers model2
            in
            updateLoggedIn
                (\loggedIn ->
                    routeRequestChannelHelper
                        sameDmRoute
                        (DiscordGuildOrDmId
                            (DiscordGuildOrDmId_Dm
                                { currentUserId = routeData.currentDiscordUserId
                                , channelId = routeData.channelId
                                }
                            )
                        )
                        Nothing
                        (NoThreadWithFriends routeData.viewingMessage routeData.showMembersTab)
                        (Local.model loggedIn.localState)
                        loggedIn
                        model3
                )
                model3

        SlackOAuthRedirect result ->
            ( model2
            , case result of
                Ok ( code, sessionId ) ->
                    Lamdera.sendToBackend (LinkSlackOAuthCode code sessionId)

                Err () ->
                    Command.none
            )

        TextEditorRoute ->
            ( model2, Command.none )

        LinkDiscord result ->
            ( model2
            , case ( model2.loginStatus, result ) of
                ( LoggedIn _, Ok userData ) ->
                    LinkDiscordRequest userData |> Lamdera.sendToBackend

                _ ->
                    Command.none
            )

        PublicGoMatchRoute publicGoMatchId ->
            ( { model2 | publicGoMatch = PublicGoMatch_Loading }
            , Lamdera.sendToBackend (GetPublicGoMatchRequest publicGoMatchId)
            )
    )
        |> Tuple.mapSecond (\a -> Command.batch [ viewCmd, a ])


mapEncryptionRequests : (EncryptionRequests -> EncryptionRequests) -> LoggedIn2 -> LoggedIn2
mapEncryptionRequests func loggedIn =
    { loggedIn | encryptionRequests = func loggedIn.encryptionRequests }


updateLoggedIn :
    (LoggedIn2 -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg_ ))
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
updateLoggedIn updateFunc model =
    case model.loginStatus of
        LoggedIn loggedIn ->
            updateFunc loggedIn |> Tuple.mapFirst (\a -> { model | loginStatus = LoggedIn a })

        NotLoggedIn _ ->
            ( model, Command.none )


{-| The channel's games and selected match id, if the user is looking at the games tab of a
DM or guild channel.
-}
currentGamesTab :
    LocalState
    -> Route
    ->
        Maybe
            { guildOrDmId : GuildOrDmId
            , maybeMatchId : Maybe (Id ChannelMessageId)
            , channelGames : SeqDict (Id ChannelMessageId) Game.MatchData
            , newMatchId : Id ChannelMessageId
            }
currentGamesTab local route =
    case route of
        DmRoute dmRoute ->
            case ( dmRoute.tab, DmChannelId.otherUserId local.localUser.session.userId dmRoute.channelId ) of
                ( Just (ChannelHeaderTab_Games maybeMatchId), Just otherUserId ) ->
                    let
                        dmChannel : FrontendDmChannel
                        dmChannel =
                            SeqDict.get otherUserId local.dmChannels |> Maybe.withDefault DmChannel.frontendInit
                    in
                    Just
                        { guildOrDmId = GuildOrDmId_Dm { otherUserId = otherUserId }
                        , maybeMatchId = maybeMatchId
                        , channelGames = dmChannel.games
                        , newMatchId = DmChannel.latestFrontendMessageId dmChannel |> Id.increment
                        }

                _ ->
                    Nothing

        GuildRoute guildId (ChannelRoute channelId _ (Just (ChannelHeaderTab_Games maybeMatchId))) _ ->
            case LocalState.getGuildAndChannel { guildId = guildId, channelId = channelId } local of
                Just ( _, channel ) ->
                    Just
                        { guildOrDmId = GuildOrDmId_Guild { guildId = guildId, channelId = channelId }
                        , maybeMatchId = maybeMatchId
                        , channelGames = channel.games
                        , newMatchId = DmChannel.latestFrontendMessageId channel |> Id.increment
                        }

                Nothing ->
                    Nothing

        _ ->
            Nothing


{-| The match currently being viewed, if the user is looking at the games tab of a channel.
-}
currentGame : LocalState -> LoadedFrontend -> Maybe { guildOrDmId : GuildOrDmId, matchId : Id ChannelMessageId, match : Game.MatchData }
currentGame local model =
    case currentGamesTab local model.route of
        Just gamesTab ->
            case gamesTab.maybeMatchId of
                Just matchId ->
                    case SeqDict.get matchId gamesTab.channelGames of
                        Just match ->
                            Just { guildOrDmId = gamesTab.guildOrDmId, matchId = matchId, match = match }

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


routeRequestChannelHelper :
    Bool
    -> AnyGuildOrDmId
    -> Maybe ChannelHeaderTab
    -> ThreadRouteWithFriends
    -> LocalState
    -> LoggedIn2
    -> LoadedFrontend
    -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg_ )
routeRequestChannelHelper sameChannel guildOrDmId tab threadRoute local loggedIn model3 =
    (case ( guildOrDmId, tab ) of
        ( GuildOrDmId guildOrDmId2, Just (ChannelHeaderTab_Games (Just messageId)) ) ->
            let
                games : SeqDict (Id ChannelMessageId) Game.MatchData
                games =
                    channelGames guildOrDmId2 local
            in
            handleLocalChange
                model3.time
                (case SeqDict.get messageId games of
                    Just match ->
                        -- The backend only told us this match exists, so ask it for the rest.
                        if Game.isNotLoaded match then
                            Game.LoadMatch messageId EmptyPlaceholder
                                |> Local_Game guildOrDmId2
                                |> Just

                        else
                            Nothing

                    Nothing ->
                        Nothing
                )
                { loggedIn
                    | games =
                        Game.routeRequest
                            model3.time
                            local.localUser
                            guildOrDmId2
                            messageId
                            games
                            loggedIn.games
                }
                Command.none

        _ ->
            ( loggedIn, Command.none )
    )
        |> Tuple.mapSecond
            (\loadCmd ->
                Command.batch
                    [ loadCmd
                    , Command.batch
                        [ if sameChannel then
                            -- Staying in the same channel but pointing at a message means the user followed a
                            -- reply header or a link to it, so bring that message into view instead of sticking
                            -- to the bottom of the conversation.
                            case threadRoute of
                                ViewThreadWithFriends _ (Just messageIndex) _ ->
                                    Scroll.smoothScrollTo
                                        Pages.Guild.conversationContainerId
                                        (Pages.Guild.threadMessageHtmlId messageIndex)
                                        |> Task.attempt (\_ -> ScrolledToMessage)

                                ViewThreadWithFriends _ Nothing _ ->
                                    Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn.channelScrollPosition

                                NoThreadWithFriends (Just messageIndex) _ ->
                                    Scroll.smoothScrollTo
                                        Pages.Guild.conversationContainerId
                                        (Pages.Guild.channelMessageHtmlId messageIndex)
                                        |> Task.attempt (\_ -> ScrolledToMessage)

                                NoThreadWithFriends Nothing _ ->
                                    Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn.channelScrollPosition

                          else
                            let
                                scrollToBottom : Command FrontendOnly ToBackend FrontendMsg_
                                scrollToBottom =
                                    Process.sleep Duration.millisecond
                                        |> Task.andThen (\() -> Dom.setViewportOf Pages.Guild.conversationContainerId 0 9999999)
                                        |> Task.attempt (\_ -> SetScrollToBottom)
                            in
                            Command.batch
                                [ setFocus model3 Pages.Guild.channelTextInputId
                                , case threadRoute of
                                    ViewThreadWithFriends _ maybeMessageIndex _ ->
                                        case maybeMessageIndex of
                                            Just messageIndex ->
                                                Scroll.smoothScroll
                                                    Pages.Guild.conversationContainerId
                                                    (Pages.Guild.threadMessageHtmlId messageIndex)
                                                    |> Task.attempt (\_ -> ScrolledToMessage)

                                            Nothing ->
                                                scrollToBottom

                                    NoThreadWithFriends maybeMessageIndex _ ->
                                        case maybeMessageIndex of
                                            Just messageIndex ->
                                                Scroll.smoothScroll
                                                    Pages.Guild.conversationContainerId
                                                    (Pages.Guild.channelMessageHtmlId messageIndex)
                                                    |> Task.attempt (\_ -> ScrolledToMessage)

                                            Nothing ->
                                                scrollToBottom
                                ]
                        , case tab of
                            Just (ChannelHeaderTab_Games _) ->
                                Dom.setViewportOf WordSpellingGame.pastWordsContainerId 0 9999999
                                    |> Task.attempt (\_ -> SetScrollToBottom)

                            _ ->
                                Command.none
                        ]
                    ]
            )


{-| The matches in a channel, whichever kind of channel it is.
-}
channelGames : GuildOrDmId -> LocalState -> SeqDict (Id ChannelMessageId) Game.MatchData
channelGames guildOrDmId local =
    case guildOrDmId of
        GuildOrDmId_Dm { otherUserId } ->
            case SeqDict.get otherUserId local.dmChannels of
                Just dmChannel ->
                    dmChannel.games

                Nothing ->
                    SeqDict.empty

        GuildOrDmId_Guild id ->
            case LocalState.getGuildAndChannel id local of
                Just ( _, channel ) ->
                    channel.games

                Nothing ->
                    SeqDict.empty


isPressMsg : FrontendMsg_ -> Bool
isPressMsg msg =
    case msg of
        UrlClicked _ ->
            False

        UrlChanged _ ->
            False

        GotTime _ ->
            False

        GotWindowSize _ _ ->
            False

        LoginFormMsg loginFormMsg ->
            LoginForm.isPressMsg loginFormMsg

        RecoveryLoginMsg recoveryLoginMsg ->
            RecoveryLogin.isPressMsg recoveryLoginMsg

        PressedShowLogin ->
            True

        AdminPageMsg _ ->
            False

        PressedLogOut _ ->
            True

        ElmUiMsg _ ->
            False

        ScrolledToLogSection ->
            False

        PressedLink _ ->
            True

        NewChannelFormChanged _ _ ->
            False

        PressedSubmitNewChannel _ _ ->
            False

        EditChannelFormChanged _ _ _ ->
            False

        PressedResetEditChannelChanges _ _ ->
            True

        PressedSubmitEditChannelChanges _ _ _ ->
            True

        PressedDeleteChannel _ _ ->
            True

        EditGuildFormChanged _ _ ->
            False

        PressedResetEditGuildChanges _ ->
            True

        PressedSubmitEditGuildChanges _ _ ->
            True

        PressedDeleteGuild _ ->
            True

        PressedLeaveGuild _ ->
            True

        PressedCreateInviteLink _ ->
            True

        PressedDeleteInviteLink _ _ ->
            True

        PressedToggleInviteLinkQrCode _ ->
            True

        FrontendNoOp ->
            False

        PressedCopyText _ ->
            True

        PressedCopyImage _ ->
            True

        NewGuildFormChanged _ ->
            False

        PressedSubmitNewGuild _ ->
            True

        DebouncedTyping ->
            False

        GotPingUserPosition _ _ ->
            False

        SetFocus ->
            False

        RemoveFocus ->
            False

        KeyDown _ ->
            False

        MessageMenu_PressedShowReactionEmojiSelector _ _ _ ->
            True

        MessageMenu_PressedEditMessage _ _ ->
            True

        EmojiSelectorMsg emojiMsg ->
            Emoji.isPressed emojiMsg

        MessageMenu_PressedReply _ ->
            True

        PressedCloseReplyTo _ ->
            True

        VisibilityChanged _ ->
            False

        CheckedNotificationPermission _ ->
            False

        TouchStart _ _ ->
            False

        TouchMoved _ _ ->
            False

        TouchEnd _ ->
            False

        TouchCancel _ ->
            False

        ChannelSidebarAnimated _ ->
            False

        MessageMenuAnimated _ ->
            False

        SetScrollToBottom ->
            False

        PressedChannelHeaderBackButton ->
            True

        UserScrolled _ _ _ ->
            False

        PressedBody ->
            True

        MessageMenu_PressedDeleteMessage _ _ ->
            True

        MessageMenu_PressedMarkAsUnread _ _ ->
            True

        MessageMenu_PressedAddCustomEmojisToUser _ ->
            True

        ScrolledToMessage ->
            False

        MessageMenu_PressedClose ->
            True

        MessageMenu_PressedContainer ->
            True

        PressedCancelMessageEdit _ ->
            True

        CheckMessageAltPress _ _ _ _ _ _ ->
            False

        PressedShowUserOption ->
            True

        PressedCloseUserOptions ->
            True

        TwoFactorMsg twoFactorMsg ->
            TwoFactorAuthentication.isPressMsg twoFactorMsg

        AiChatMsg aiChatMsg ->
            AiChat.isPressMsg aiChatMsg

        GameMsg _ ->
            True

        UserNameEditableMsg editableMsg ->
            Editable.isPressMsg editableMsg

        ProfilePictureEditorMsg imageEditorMsg ->
            ImageEditor.isPressMsg imageEditorMsg

        GuildIconEditorMsg _ imageEditorMsg ->
            ImageEditor.isPressMsg imageEditorMsg

        OneFrameAfterDragEnd ->
            False

        SelectedFilesToAttach _ _ _ ->
            False

        GotFileHashName _ _ _ ->
            False

        PressedDeleteAttachedFile _ _ ->
            True

        EditMessage_PressedDeleteAttachedFile _ _ ->
            True

        EditMessage_SelectedFilesToAttach _ _ _ ->
            False

        EditMessage_GotFileHashName _ _ _ _ ->
            False

        FileUploadProgress _ _ _ ->
            False

        MessageMenu_PressedOpenThread _ ->
            True

        MessageViewMsg _ _ messageViewMsg ->
            MessageView.isPressMsg messageViewMsg

        ImageViewerMsg imageViewerMsg ->
            ImageViewer.isPressMsg imageViewerMsg

        GotRegisterPushSubscription _ ->
            False

        SelectedNotificationMode _ ->
            True

        SelectedEmailNotifications _ ->
            True

        PressedGuildNotificationLevel _ _ ->
            True

        GotStartupData _ ->
            False

        GotDevicePixelRatio _ ->
            False

        PressedViewAttachedFileInfo _ _ ->
            True

        EditMessage_PressedViewAttachedFileInfo _ _ ->
            True

        PressedCloseImageInfo ->
            True

        PressedShowMembers ->
            True

        PressedHideMembers ->
            True

        PressedMemberListBack ->
            True

        PressedExportChannel _ ->
            True

        EncryptionFromJs _ ->
            False

        PressedAddPrivateKeyToAccount ->
            True

        PressedCloseNewPrivateKey ->
            True

        PressedExpandE2eeSection _ ->
            True

        PressedE2eeRisksAccepted _ ->
            True

        PressedEnableE2ee _ ->
            True

        PressedCancelE2eeRequest _ ->
            True

        PressedDeclineE2eeRequest _ ->
            True

        TypedPrivateKey _ _ ->
            False

        PageHasFocusChanged _ ->
            False

        GotServiceWorkerMessage _ ->
            False

        VisualViewportResized _ ->
            False

        TextEditorMsg textEditorMsg ->
            TextEditor.isPress textEditorMsg

        PressedDiscordAcknowledgment _ ->
            True

        PressedReloadDiscordUser _ ->
            True

        PressedUnlinkDiscordUser _ ->
            True

        PressedDiscordGuildMemberLabel _ ->
            True

        TypedDiscordLinkBookmarklet ->
            False

        GotVersionNumber _ _ ->
            False

        PressedDiscordGuildNotificationLevel _ _ _ ->
            True

        PressedCloseExternalLinkWarning ->
            True

        PressedAddDomainToWhitelist _ ->
            True

        TypedDomainWhitelist _ ->
            False

        -- Dragging the brightness slider is a drag, so counting this as a press would make
        -- the slider unusable on mobile. Brushing past a swatch only changes which colour is
        -- highlighted, which is cheap to undo.
        PressedSelectNewColor ->
            True

        SelectedUserColor _ ->
            False

        PressedSubmitUserColor ->
            True

        PressedResetUserColor ->
            True

        PressedSaveDomainWhitelist ->
            True

        PressedResetDomainWhitelist ->
            True

        PressedContinueToSite ->
            True

        EditMessage_MessageInputMsg _ _ messageInputMsg ->
            MessageInput.isPress messageInputMsg

        MessageInputMsg _ _ messageInputMsg ->
            MessageInput.isPress messageInputMsg

        GotEmojiData _ ->
            False

        GotPositionForEmojiSelector_EditMessage _ ->
            False

        MessageMenu_PressedReactionEmoji _ ->
            True

        EnableToFrontendLogging ->
            False

        TextSelectionChanged _ ->
            False

        DomFocusChanged _ ->
            False

        PressedToggleAttachedFileSpoiler _ _ ->
            True

        EditMessage_PressedToggleAttachedFileSpoiler _ _ ->
            True

        PageUpGotViewport _ ->
            False

        GotVoiceChatSignalFromJs _ ->
            False

        VoiceChatMsg voiceChatMsg ->
            Call.isPressMsg voiceChatMsg

        PressedChannelHeaderTab _ ->
            True

        FileDragEnter _ ->
            False

        FileDragLeave ->
            False

        FileDropped _ ->
            False

        GoSpectatorMsg spectatorMsg ->
            case spectatorMsg of
                Go.PressedArrowLeft ->
                    True

                Go.PressedArrowRight ->
                    True

                Go.ChangedViewingMove _ ->
                    False

                Go.Spectator_PressedCell _ ->
                    True

        PressedUnregisterServiceWorkers ->
            True

        PressedLoadDebugData ->
            True

        GotServiceWorkerData _ ->
            False

        DrawingMsg drawingMsg ->
            case drawingMsg of
                Drawing.PressedUndo ->
                    True

                Drawing.PressedRedo ->
                    True

                _ ->
                    False

        PressedNewMessagesWarning ->
            True

        LoadedPopSound _ ->
            False

        TypedFriendsSearch _ ->
            False

        PressedClearFriendsSearch ->
            True

        TypedChannelSearch _ ->
            False

        PressedClearChannelSearch ->
            True

        PressedExpandContainer _ ->
            True

        MessageMenu_PressedOpenDm _ ->
            True

        PressedMuteChannel _ _ _ ->
            True

        MessageMenu_PressedOpenDiscordDm _ _ ->
            True

        PressedMuteThread _ _ _ _ ->
            True

        PressedMuteDiscordChannel _ _ _ _ ->
            True

        PressedMuteDiscordThread _ _ _ _ _ ->
            True

        PressedMarkChannelAsRead _ _ ->
            True

        PressedMarkAllChannelsAsRead _ ->
            True

        PressedMuteGuild _ _ ->
            True

        PressedMuteDiscordGuild _ _ _ ->
            True

        UnreadOverviewChannelMsg _ _ messageViewMsg ->
            MessageView.isPressMsg messageViewMsg

        UnreadOverviewThreadMsg _ _ _ messageViewMsg ->
            MessageView.isPressMsg messageViewMsg

        GotPositionForEmojiSelector_SheepGameInput _ _ ->
            False

        ValidatedE2eePrivateKey _ _ ->
            False


setFocus : LoadedFrontend -> HtmlId -> Command FrontendOnly toMsg FrontendMsg_
setFocus model htmlId =
    if MyUi.isMobile model then
        Command.none

    else
        Dom.focus htmlId |> Task.attempt (\_ -> SetFocus)


textToRichText :
    NonemptyString
    -> List (Id UserId)
    -> LocalState
    -> Nonempty (RichText (Id UserId))
textToRichText text memberIds local =
    let
        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            User.allUsers local.localUser
    in
    RichText.fromNonemptyString
        local.localUser.timezone
        (List.foldl
            (\memberId dict ->
                case SeqDict.get memberId allUsers of
                    Just member ->
                        SeqDict.insert memberId member dict

                    Nothing ->
                        dict
            )
            SeqDict.empty
            memberIds
        )
        text


textToDiscordRichText :
    NonemptyString
    -> List (Discord.Id Discord.UserId)
    -> LocalState
    -> Nonempty (RichText (Discord.Id Discord.UserId))
textToDiscordRichText text memberIds local =
    let
        allUsers : SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
        allUsers =
            LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers
    in
    RichText.fromNonemptyString
        local.localUser.timezone
        (List.foldl
            (\memberId dict ->
                case SeqDict.get memberId allUsers of
                    Just member ->
                        SeqDict.insert memberId member dict

                    Nothing ->
                        dict
            )
            SeqDict.empty
            memberIds
        )
        text


{-| Where the message a DM channel just took sits. The channel it is read off has the
message in it already, so this is the newest one rather than the one after it.
-}
latestMessageThreadRoute : ThreadRouteWithMaybeMessage -> FrontendDmChannel -> ThreadRouteWithMessage
latestMessageThreadRoute threadRouteWithRepliedTo dmChannel =
    case threadRouteWithRepliedTo of
        ViewThreadWithMaybeMessage threadId _ ->
            SeqDict.get threadId dmChannel.threads
                |> Maybe.withDefault Thread.frontendInit
                |> DmChannel.latestFrontendThreadMessageId
                |> ViewThreadWithMessage threadId

        NoThreadWithMaybeMessage _ ->
            DmChannel.latestFrontendMessageId dmChannel |> NoThreadWithMessage


{-| Where a message that has just arrived sits, worked out from the channel as it was
before the message was added, since that is what the message handlers have on hand.
-}
newMessageThreadRoute :
    ThreadRouteWithMaybeMessage
    -> { a | messages : MessageArray ChannelMessageId c, threads : SeqDict (Id ChannelMessageId) { d | messages : MessageArray ThreadMessageId e } }
    -> ThreadRouteWithMessage
newMessageThreadRoute threadRouteWithRepliedTo channel =
    case threadRouteWithRepliedTo of
        ViewThreadWithMaybeMessage threadId _ ->
            SeqDict.get threadId channel.threads
                |> Maybe.map (\thread -> MessageArray.length thread.messages)
                |> Maybe.withDefault 0
                |> Id.fromInt
                |> ViewThreadWithMessage threadId

        NoThreadWithMaybeMessage _ ->
            MessageArray.length channel.messages |> Id.fromInt |> NoThreadWithMessage


changeUpdate : LocalMsg -> LocalState -> LocalState
changeUpdate localMsg local =
    case localMsg of
        LocalChange changedBy localChange ->
            case localChange of
                Local_Invalid ->
                    local

                Local_Admin adminChange ->
                    case local.adminData of
                        IsAdmin adminData ->
                            Pages.Admin.updateAdmin changedBy adminChange adminData local

                        IsAdminButDataNotLoaded ->
                            local

                        IsNotAdmin ->
                            local

                Local_SendMessage createdAt _ guildOrDmId text threadRouteWithRepliedTo attachedFiles emojis ->
                    case guildOrDmId of
                        GuildOrDmId_Guild id ->
                            case LocalState.getGuildAndChannel id local of
                                Just ( guild, channel ) ->
                                    let
                                        user =
                                            local.localUser.user

                                        localUser =
                                            local.localUser

                                        ( currentlyViewing2, user2 ) =
                                            LocalState.ownMessageIsReadFrontend
                                                (GuildOrDmId guildOrDmId)
                                                (newMessageThreadRoute threadRouteWithRepliedTo channel)
                                                ( localUser.currentlyViewing, user )
                                    in
                                    { local
                                        | guilds =
                                            guildSendMessage
                                                id.guildId
                                                guild
                                                id.channelId
                                                channel
                                                threadRouteWithRepliedTo
                                                createdAt
                                                localUser.session.userId
                                                (textToRichText text (MembersAndOwner.membersAndOwner guild.membersAndOwner) local)
                                                attachedFiles
                                                local
                                        , localUser =
                                            { localUser
                                                | currentlyViewing = currentlyViewing2
                                                , user =
                                                    User.addRecentlyUsedEmojis emojis user2
                                            }
                                    }

                                Nothing ->
                                    local

                        GuildOrDmId_Dm { otherUserId } ->
                            let
                                user =
                                    local.localUser.user

                                localUser =
                                    local.localUser

                                dmChannel : FrontendDmChannel
                                dmChannel =
                                    SeqDict.get otherUserId local.dmChannels
                                        |> Maybe.withDefault DmChannel.frontendInit

                                dmChannel2 : FrontendDmChannel
                                dmChannel2 =
                                    case threadRouteWithRepliedTo of
                                        ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                                            LocalState.createThreadMessageFrontend
                                                threadId
                                                (Message.userTextMessageFrontend
                                                    createdAt
                                                    localUser.session.userId
                                                    (textToRichText text [ localUser.session.userId, otherUserId ] local)
                                                    maybeReplyTo
                                                    attachedFiles
                                                )
                                                dmChannel

                                        NoThreadWithMaybeMessage maybeReplyTo ->
                                            LocalState.createChannelMessageFrontend
                                                (Message.userTextMessageFrontend
                                                    createdAt
                                                    localUser.session.userId
                                                    (textToRichText text [ localUser.session.userId, otherUserId ] local)
                                                    maybeReplyTo
                                                    attachedFiles
                                                )
                                                dmChannel

                                ( currentlyViewing2, user2 ) =
                                    LocalState.ownMessageIsReadFrontend
                                        (GuildOrDmId guildOrDmId)
                                        (latestMessageThreadRoute threadRouteWithRepliedTo dmChannel2)
                                        ( localUser.currentlyViewing, user )
                            in
                            { local
                                | dmChannels = SeqDict.insert otherUserId dmChannel2 local.dmChannels
                                , localUser =
                                    { localUser
                                        | currentlyViewing = currentlyViewing2
                                        , user = User.addRecentlyUsedEmojis emojis user2
                                    }
                            }

                Local_Discord_SendMessage createdAt _ guildOrDmId text threadRouteWithRepliedTo attachedFiles ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild { currentUserId, guildId, channelId } ->
                            case LocalState.getDiscordGuildAndChannel guildId channelId local of
                                Just ( guild, channel ) ->
                                    let
                                        user =
                                            local.localUser.user

                                        localUser =
                                            local.localUser

                                        ( currentlyViewing2, user2 ) =
                                            LocalState.ownMessageIsReadFrontend
                                                (DiscordGuildOrDmId guildOrDmId)
                                                (newMessageThreadRoute threadRouteWithRepliedTo channel)
                                                ( localUser.currentlyViewing, user )
                                    in
                                    { local
                                        | discordGuilds =
                                            discordGuildSendMessage
                                                guildId
                                                guild
                                                channelId
                                                channel
                                                threadRouteWithRepliedTo
                                                createdAt
                                                currentUserId
                                                (textToDiscordRichText text (MembersAndOwner.membersAndOwner guild.membersAndOwner) local)
                                                attachedFiles
                                                local
                                        , localUser =
                                            { localUser | user = user2, currentlyViewing = currentlyViewing2 }
                                    }

                                Nothing ->
                                    local

                        DiscordGuildOrDmId_Dm { currentUserId, channelId } ->
                            case SeqDict.get channelId local.discordDmChannels of
                                Just dmChannel ->
                                    let
                                        user =
                                            local.localUser.user

                                        localUser =
                                            local.localUser

                                        ( currentlyViewing2, user2 ) =
                                            LocalState.ownMessageIsReadFrontend
                                                (DiscordGuildOrDmId guildOrDmId)
                                                (MessageArray.length dmChannel.messages
                                                    |> Id.fromInt
                                                    |> NoThreadWithMessage
                                                )
                                                ( localUser.currentlyViewing, user )
                                    in
                                    { local
                                        | discordDmChannels =
                                            SeqDict.insert
                                                channelId
                                                (case threadRouteWithRepliedTo of
                                                    ViewThreadWithMaybeMessage _ _ ->
                                                        -- Not supported for a Discord DM channel
                                                        dmChannel

                                                    NoThreadWithMaybeMessage maybeReplyTo ->
                                                        LocalState.createChannelMessageFrontend
                                                            (Message.userTextMessageFrontend
                                                                createdAt
                                                                currentUserId
                                                                (textToDiscordRichText
                                                                    text
                                                                    (NonemptyDict.keys dmChannel.members |> List.Nonempty.toList)
                                                                    local
                                                                )
                                                                maybeReplyTo
                                                                attachedFiles
                                                            )
                                                            dmChannel
                                                )
                                                local.discordDmChannels
                                        , localUser =
                                            { localUser | user = user2, currentlyViewing = currentlyViewing2 }
                                    }

                                Nothing ->
                                    local

                Local_NewChannel time guildId channelName channelDescription ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.createChannelFrontend time local.localUser.session.userId channelName channelDescription)
                                local.guilds
                    }

                Local_EditChannel guildId channelId channelName channelDescription ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.editChannel channelName channelDescription channelId)
                                local.guilds
                    }

                Local_DeleteChannel guildId channelId ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.deleteChannelFrontend channelId)
                                local.guilds
                    }

                Local_EditGuildName guildId guildName ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.editGuildName guildName)
                                local.guilds
                    }

                Local_DeleteGuild guildId ->
                    { local | guilds = SeqDict.remove guildId local.guilds }

                Local_LeaveGuild guildId ->
                    { local | guilds = SeqDict.remove guildId local.guilds }

                Local_NewInviteLink time guildId inviteLinkId ->
                    case inviteLinkId of
                        EmptyPlaceholder ->
                            local

                        FilledInByBackend inviteLinkId2 ->
                            { local
                                | guilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.addInvite inviteLinkId2 local.localUser.session.userId time)
                                        local.guilds
                            }

                Local_DeleteInviteLink guildId inviteLinkId ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.removeInvite inviteLinkId)
                                local.guilds
                    }

                Local_NewGuild time guildName guildIdPlaceholder ->
                    case guildIdPlaceholder of
                        EmptyPlaceholder ->
                            local

                        FilledInByBackend guildId ->
                            let
                                guild =
                                    LocalState.createGuild time local.localUser.session.userId guildName
                            in
                            { local
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.guildToFrontend
                                            guildId
                                            (Just ( LocalState.announcementChannel guild, ( NoThread, Nothing ) ))
                                            OneToOne.empty
                                            guild
                                        )
                                        local.guilds
                            }

                Local_MemberTyping time ( guildOrDmId, threadRoute ) ->
                    case guildOrDmId of
                        GuildOrDmId guildOrDmId2 ->
                            memberTyping time local.localUser.session.userId guildOrDmId2 threadRoute local

                        DiscordGuildOrDmId guildOrDmId2 ->
                            case guildOrDmId2 of
                                DiscordGuildOrDmId_Guild { currentUserId, guildId, channelId } ->
                                    discordGuildMemberTyping time currentUserId guildId channelId threadRoute local

                                DiscordGuildOrDmId_Dm data ->
                                    discordDmMemberTyping time data.currentUserId data.channelId local

                Local_AddReactionEmoji guildOrDmId threadRoute emoji ->
                    addReactionEmoji local.localUser.session.userId guildOrDmId threadRoute emoji local

                Local_RemoveReactionEmoji guildOrDmId threadRoute emoji ->
                    removeReactionEmoji local.localUser.session.userId guildOrDmId threadRoute emoji local

                Local_SendEditMessage time _ guildOrDmId threadRoute newContent attachedFiles ->
                    editMessage time local.localUser.session.userId guildOrDmId newContent attachedFiles threadRoute local

                Local_Discord_SendEditGuildMessage time _ currentUserId guildId channelId threadRoute newContent ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (\guild ->
                                    LocalState.updateChannel
                                        (\channel ->
                                            LocalState.editMessageFrontendHelper
                                                time
                                                currentUserId
                                                (textToDiscordRichText
                                                    newContent
                                                    (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                                                    local
                                                )
                                                DoNotChangeAttachments
                                                threadRoute
                                                channel
                                                |> Result.withDefault channel
                                        )
                                        channelId
                                        guild
                                )
                                local.discordGuilds
                    }

                Local_Discord_SendEditDmMessage time _ dmData messageId newContent ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                dmData.channelId
                                (\dmChannel ->
                                    LocalState.editMessageFrontendHelperNoThread
                                        time
                                        dmData.currentUserId
                                        (textToDiscordRichText
                                            newContent
                                            (NonemptyDict.keys dmChannel.members |> List.Nonempty.toList)
                                            local
                                        )
                                        DoNotChangeAttachments
                                        messageId
                                        dmChannel
                                        |> Result.withDefault dmChannel
                                )
                                local.discordDmChannels
                    }

                Local_MemberEditTyping time guildOrDmId threadRoute ->
                    memberEditTyping time local.localUser.session.userId guildOrDmId threadRoute local

                Local_SetLastViewed guildOrDmId threadRoute ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | user = User.setLastViewedMessage guildOrDmId threadRoute local.localUser.user

                                -- Marking a message as unread happens in the conversation being
                                -- looked at, and the divider of that conversation is drawn from
                                -- the session rather than from lastViewedMessage. Marking some
                                -- other conversation as read from the unread overview leaves the
                                -- divider of the one being looked at where it is.
                                , currentlyViewing =
                                    if UserSession.isViewing guildOrDmId (Id.threadRouteWithoutMessage threadRoute) localUser.currentlyViewing then
                                        case threadRoute of
                                            NoThreadWithMessage messageId ->
                                                UserSession.setPreviouslyLastViewedChannelMessage messageId localUser.currentlyViewing

                                            ViewThreadWithMessage _ messageId ->
                                                UserSession.setPreviouslyLastViewedThreadMessage messageId localUser.currentlyViewing

                                    else
                                        localUser.currentlyViewing
                            }
                    }

                Local_DeleteMessage guildOrDmId threadRoute ->
                    deleteMessage guildOrDmId threadRoute local

                Local_CurrentlyViewing { markMessagesAsViewed } viewing ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    case viewing of
                        ViewDm data messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            User.setLastDmViewed
                                                data.id
                                                (NoThreadWithMaybeMessage
                                                    (if markMessagesAsViewed then
                                                        SeqDict.get data.id.otherUserId local.dmChannels
                                                            |> Maybe.map DmChannel.latestFrontendMessageId

                                                     else
                                                        Nothing
                                                    )
                                                )
                                                localUser.user
                                        , currentlyViewing = UserSession.setViewingToCurrentlyViewing viewing
                                    }
                                , dmChannels =
                                    SeqDict.updateIfExists
                                        data.id.otherUserId
                                        (DmChannel.loadMessages messagesLoaded)
                                        local.dmChannels
                            }

                        ViewDmThread data messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            User.setLastDmViewed
                                                { otherUserId = data.id.otherUserId }
                                                (ViewThreadWithMaybeMessage
                                                    data.id.threadId
                                                    (if markMessagesAsViewed then
                                                        SeqDict.get data.id.otherUserId local.dmChannels
                                                            |> Maybe.andThen
                                                                (\dmChannel -> SeqDict.get data.id.threadId dmChannel.threads)
                                                            |> Maybe.map DmChannel.latestFrontendThreadMessageId

                                                     else
                                                        Nothing
                                                    )
                                                )
                                                localUser.user
                                        , currentlyViewing = UserSession.setViewingToCurrentlyViewing viewing
                                    }
                                , dmChannels =
                                    SeqDict.updateIfExists
                                        data.id.otherUserId
                                        (\dmChannel ->
                                            { dmChannel
                                                | threads =
                                                    SeqDict.updateIfExists
                                                        data.id.threadId
                                                        (DmChannel.loadMessages messagesLoaded)
                                                        dmChannel.threads
                                            }
                                        )
                                        local.dmChannels
                            }

                        ViewDiscordDm data messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            User.setLastDiscordDmViewed
                                                data.id.currentUserId
                                                data.id.channelId
                                                (if markMessagesAsViewed then
                                                    SeqDict.get data.id.channelId local.discordDmChannels
                                                        |> Maybe.map DmChannel.latestFrontendMessageId

                                                 else
                                                    Nothing
                                                )
                                                localUser.user
                                        , currentlyViewing = UserSession.setViewingToCurrentlyViewing viewing
                                    }
                                , discordDmChannels =
                                    SeqDict.updateIfExists
                                        data.id.channelId
                                        (DmChannel.loadMessages messagesLoaded)
                                        local.discordDmChannels
                            }

                        ViewChannel data messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            User.setLastChannelViewed
                                                data.id
                                                (NoThreadWithMaybeMessage
                                                    (if markMessagesAsViewed then
                                                        LocalState.getGuildAndChannel data.id local
                                                            |> Maybe.map (\( _, channel ) -> DmChannel.latestFrontendMessageId channel)

                                                     else
                                                        Nothing
                                                    )
                                                )
                                                localUser.user
                                        , currentlyViewing = UserSession.setViewingToCurrentlyViewing viewing
                                    }
                                , guilds =
                                    SeqDict.updateIfExists
                                        data.id.guildId
                                        (LocalState.updateChannel (DmChannel.loadMessages messagesLoaded) data.id.channelId)
                                        local.guilds
                            }

                        ViewChannelThread data messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            User.setLastChannelViewed
                                                { guildId = data.id.guildId, channelId = data.id.channelId }
                                                (ViewThreadWithMaybeMessage
                                                    data.id.threadId
                                                    (if markMessagesAsViewed then
                                                        LocalState.getGuildAndChannel { guildId = data.id.guildId, channelId = data.id.channelId } local
                                                            |> Maybe.andThen
                                                                (\( _, channel ) -> SeqDict.get data.id.threadId channel.threads)
                                                            |> Maybe.map DmChannel.latestFrontendThreadMessageId

                                                     else
                                                        Nothing
                                                    )
                                                )
                                                localUser.user
                                        , currentlyViewing = UserSession.setViewingToCurrentlyViewing viewing
                                    }
                                , guilds =
                                    SeqDict.updateIfExists
                                        data.id.guildId
                                        (LocalState.updateChannel
                                            (\channel ->
                                                { channel
                                                    | threads =
                                                        SeqDict.updateIfExists
                                                            data.id.threadId
                                                            (DmChannel.loadMessages messagesLoaded)
                                                            channel.threads
                                                }
                                            )
                                            data.id.channelId
                                        )
                                        local.guilds
                            }

                        StopViewingChannel ->
                            { local | localUser = { localUser | currentlyViewing = UserSession.setViewingToCurrentlyViewing viewing } }

                        ViewDiscordChannel data backendData ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            User.setLastDiscordChannelViewed
                                                data.id
                                                (NoThreadWithMaybeMessage
                                                    (if markMessagesAsViewed then
                                                        LocalState.getDiscordGuildAndChannel data.id.guildId data.id.channelId local
                                                            |> Maybe.map (\( _, channel ) -> DmChannel.latestFrontendMessageId channel)

                                                     else
                                                        Nothing
                                                    )
                                                )
                                                localUser.user
                                        , currentlyViewing = UserSession.setViewingToCurrentlyViewing viewing
                                        , discordUsers =
                                            case backendData of
                                                FilledInByBackend backendData2 ->
                                                    SeqDict.foldl
                                                        LinkedAndOtherDiscordUsers.addOtherUser
                                                        localUser.discordUsers
                                                        backendData2.newUsers

                                                EmptyPlaceholder ->
                                                    localUser.discordUsers
                                    }
                                , discordGuilds =
                                    SeqDict.updateIfExists
                                        data.id.guildId
                                        (LocalState.updateChannel
                                            (DmChannel.loadMessages (discordViewMessages backendData))
                                            data.id.channelId
                                        )
                                        local.discordGuilds
                            }

                        ViewDiscordChannelThread data backendData ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            User.setLastDiscordChannelViewed
                                                { guildId = data.id.guildId, channelId = data.id.channelId, currentUserId = data.id.currentUserId }
                                                (ViewThreadWithMaybeMessage
                                                    data.id.threadId
                                                    (if markMessagesAsViewed then
                                                        LocalState.getDiscordGuildAndChannel data.id.guildId data.id.channelId local
                                                            |> Maybe.andThen
                                                                (\( _, channel ) -> SeqDict.get data.id.threadId channel.threads)
                                                            |> Maybe.map DmChannel.latestFrontendThreadMessageId

                                                     else
                                                        Nothing
                                                    )
                                                )
                                                localUser.user
                                        , currentlyViewing = UserSession.setViewingToCurrentlyViewing viewing
                                        , discordUsers =
                                            case backendData of
                                                FilledInByBackend backendData2 ->
                                                    SeqDict.foldl
                                                        LinkedAndOtherDiscordUsers.addOtherUser
                                                        localUser.discordUsers
                                                        backendData2.newUsers

                                                EmptyPlaceholder ->
                                                    localUser.discordUsers
                                    }
                                , discordGuilds =
                                    SeqDict.updateIfExists
                                        data.id.guildId
                                        (LocalState.updateChannel
                                            (\channel ->
                                                { channel
                                                    | threads =
                                                        SeqDict.updateIfExists
                                                            data.id.threadId
                                                            (DmChannel.loadMessages (discordViewMessages backendData))
                                                            channel.threads
                                                }
                                            )
                                            data.id.channelId
                                        )
                                        local.discordGuilds
                            }

                        ViewOverview overviewData ->
                            let
                                localUser2 : LocalUser
                                localUser2 =
                                    { localUser | currentlyViewing = UserSession.setViewingToCurrentlyViewing viewing }
                            in
                            case overviewData of
                                FilledInByBackend overviewData2 ->
                                    let
                                        guilds : SeqDict (Id GuildId) FrontendGuild
                                        guilds =
                                            SeqDict.foldl
                                                (\( guildId, channelId ) messages guilds2 ->
                                                    SeqDict.updateIfExists
                                                        guildId
                                                        (LocalState.updateChannel (DmChannel.loadUnreadMessages messages) channelId)
                                                        guilds2
                                                )
                                                local.guilds
                                                overviewData2.guildChannels

                                        dmChannels : SeqDict (Id UserId) FrontendDmChannel
                                        dmChannels =
                                            SeqDict.foldl
                                                (\otherUserId messages dmChannels2 ->
                                                    SeqDict.updateIfExists
                                                        otherUserId
                                                        (DmChannel.loadUnreadMessages messages)
                                                        dmChannels2
                                                )
                                                local.dmChannels
                                                overviewData2.dmChannels

                                        discordGuilds : SeqDict (Discord.Id Discord.GuildId) DiscordFrontendGuild
                                        discordGuilds =
                                            SeqDict.foldl
                                                (\( guildId, channelId ) messages discordGuilds2 ->
                                                    SeqDict.updateIfExists
                                                        guildId
                                                        (LocalState.updateChannel (DmChannel.loadUnreadMessages messages) channelId)
                                                        discordGuilds2
                                                )
                                                local.discordGuilds
                                                overviewData2.discordGuildChannels
                                    in
                                    { local
                                        | localUser =
                                            { localUser2
                                                | discordUsers =
                                                    SeqDict.foldl
                                                        LinkedAndOtherDiscordUsers.addOtherUser
                                                        localUser2.discordUsers
                                                        overviewData2.discordUsers
                                            }
                                        , guilds =
                                            SeqDict.foldl
                                                (\( guildId, channelId, threadId ) messages guilds2 ->
                                                    SeqDict.updateIfExists
                                                        guildId
                                                        (LocalState.updateChannel
                                                            (\channel ->
                                                                { channel
                                                                    | threads =
                                                                        SeqDict.updateIfExists
                                                                            threadId
                                                                            (DmChannel.loadUnreadMessages messages)
                                                                            channel.threads
                                                                }
                                                            )
                                                            channelId
                                                        )
                                                        guilds2
                                                )
                                                guilds
                                                overviewData2.guildThreads
                                        , dmChannels =
                                            SeqDict.foldl
                                                (\( otherUserId, threadId ) messages dmChannels2 ->
                                                    SeqDict.updateIfExists
                                                        otherUserId
                                                        (\dmChannel ->
                                                            { dmChannel
                                                                | threads =
                                                                    SeqDict.updateIfExists
                                                                        threadId
                                                                        (DmChannel.loadUnreadMessages messages)
                                                                        dmChannel.threads
                                                            }
                                                        )
                                                        dmChannels2
                                                )
                                                dmChannels
                                                overviewData2.dmThreads
                                        , discordGuilds =
                                            SeqDict.foldl
                                                (\( guildId, channelId, threadId ) messages discordGuilds2 ->
                                                    SeqDict.updateIfExists
                                                        guildId
                                                        (LocalState.updateChannel
                                                            (\channel ->
                                                                { channel
                                                                    | threads =
                                                                        SeqDict.updateIfExists
                                                                            threadId
                                                                            (DmChannel.loadUnreadMessages messages)
                                                                            channel.threads
                                                                }
                                                            )
                                                            channelId
                                                        )
                                                        discordGuilds2
                                                )
                                                discordGuilds
                                                overviewData2.discordGuildThreads
                                        , discordDmChannels =
                                            SeqDict.foldl
                                                (\channelId messages discordDmChannels ->
                                                    SeqDict.updateIfExists
                                                        channelId
                                                        (DmChannel.loadUnreadMessages messages)
                                                        discordDmChannels
                                                )
                                                local.discordDmChannels
                                                overviewData2.discordDmChannels
                                    }

                                EmptyPlaceholder ->
                                    { local | localUser = localUser2 }

                Local_SetName name ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local | localUser = { localUser | user = User.setName name localUser.user } }

                Local_LoadChannelMessages guildOrDmId previousOldestVisibleMessage messagesLoaded ->
                    case guildOrDmId of
                        GuildOrDmId_Guild { guildId, channelId } ->
                            { local
                                | guilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel
                                            (DmChannel.loadOlderMessages previousOldestVisibleMessage messagesLoaded)
                                            channelId
                                        )
                                        local.guilds
                            }

                        GuildOrDmId_Dm { otherUserId } ->
                            { local
                                | dmChannels =
                                    SeqDict.updateIfExists
                                        otherUserId
                                        (DmChannel.loadOlderMessages previousOldestVisibleMessage messagesLoaded)
                                        local.dmChannels
                            }

                Local_LoadThreadMessages guildOrDmId threadId previousOldestVisibleMessage messagesLoaded ->
                    case guildOrDmId of
                        GuildOrDmId_Guild { guildId, channelId } ->
                            { local
                                | guilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel
                                            (\channel ->
                                                { channel
                                                    | threads =
                                                        SeqDict.updateIfExists
                                                            threadId
                                                            (DmChannel.loadOlderMessages
                                                                previousOldestVisibleMessage
                                                                messagesLoaded
                                                            )
                                                            channel.threads
                                                }
                                            )
                                            channelId
                                        )
                                        local.guilds
                            }

                        GuildOrDmId_Dm { otherUserId } ->
                            { local
                                | dmChannels =
                                    SeqDict.updateIfExists
                                        otherUserId
                                        (\dmChannel ->
                                            { dmChannel
                                                | threads =
                                                    SeqDict.updateIfExists
                                                        threadId
                                                        (DmChannel.loadOlderMessages
                                                            previousOldestVisibleMessage
                                                            messagesLoaded
                                                        )
                                                        dmChannel.threads
                                            }
                                        )
                                        local.dmChannels
                            }

                Local_Discord_LoadChannelMessages guildOrDmId previousOldestVisibleMessage messagesLoaded ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild { guildId, channelId } ->
                            { local
                                | discordGuilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel
                                            (DmChannel.loadOlderMessages previousOldestVisibleMessage messagesLoaded)
                                            channelId
                                        )
                                        local.discordGuilds
                            }

                        DiscordGuildOrDmId_Dm data ->
                            { local
                                | discordDmChannels =
                                    SeqDict.updateIfExists
                                        data.channelId
                                        (DmChannel.loadOlderMessages previousOldestVisibleMessage messagesLoaded)
                                        local.discordDmChannels
                            }

                Local_Discord_LoadThreadMessages guildOrDmId threadId previousOldestVisibleMessage messagesLoaded ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild { guildId, channelId } ->
                            { local
                                | discordGuilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel
                                            (\channel ->
                                                { channel
                                                    | threads =
                                                        SeqDict.updateIfExists
                                                            threadId
                                                            (DmChannel.loadOlderMessages
                                                                previousOldestVisibleMessage
                                                                messagesLoaded
                                                            )
                                                            channel.threads
                                                }
                                            )
                                            channelId
                                        )
                                        local.discordGuilds
                            }

                        DiscordGuildOrDmId_Dm _ ->
                            local

                Local_SetGuildNotificationLevel guildId notificationLevel ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | user = User.setGuildNotificationLevel guildId notificationLevel localUser.user
                            }
                    }

                Local_SetDiscordGuildNotificationLevel _ guildId notificationLevel ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | user = User.setDiscordGuildNotificationLevel guildId notificationLevel localUser.user
                            }
                    }

                Local_SetNotificationMode notificationMode ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser

                        session : UserSession
                        session =
                            localUser.session
                    in
                    { local | localUser = { localUser | session = { session | notificationMode = notificationMode } } }

                Local_ExpandUserOptionSection section ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser | session = UserSession.expandUserOptionSection section localUser.session }
                    }

                Local_CollapseUserOptionSection section ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser | session = UserSession.collapseUserOptionSection section localUser.session }
                    }

                Local_SetSheepGameQuestions questions ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser | session = UserSession.setSheepGameQuestions questions localUser.session }
                    }

                Local_SetEmailNotifications emailNotifications ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local | localUser = { localUser | user = User.setEmailNotifications emailNotifications localUser.user } }

                Local_RegisterPushSubscription time pushSubscription ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser

                        session : UserSession
                        session =
                            localUser.session
                    in
                    { local
                        | localUser =
                            { localUser
                                | session =
                                    { session
                                        | pushSubscription =
                                            case pushSubscription of
                                                GotSubscribeData subscribeData ->
                                                    Subscribed subscribeData time

                                                SubscribeJsException jsError ->
                                                    SubscriptionJsException jsError time
                                    }
                            }
                    }

                Local_TextEditor localChange2 ->
                    { local
                        | textEditor =
                            TextEditor.localChangeUpdate local.localUser.session.userId localChange2 local.textEditor
                    }

                Local_UnlinkDiscordUser userId ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser | discordUsers = LinkedAndOtherDiscordUsers.unlinkUser userId localUser.discordUsers }
                    }

                Local_StartReloadingDiscordUser time discordUserId ->
                    startReloadingDiscordUser time discordUserId local

                Local_LinkDiscordAcknowledgementIsChecked isChecked ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser

                        user : FrontendCurrentUser
                        user =
                            localUser.user
                    in
                    { local
                        | localUser =
                            { localUser | user = { user | linkDiscordAcknowledgementIsChecked = isChecked } }
                    }

                Local_SetDomainWhitelist enable domain ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local | localUser = { localUser | user = User.setDomainWhitelist enable domain localUser.user } }

                Local_SetEmojiSkinTone maybeSkinTone ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local | localUser = { localUser | user = User.setEmojiSkinTone maybeSkinTone localUser.user } }

                Local_SetUserColor color ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local | localUser = { localUser | user = User.setColor color localUser.user } }

                Local_AddCustomEmojisToUser customEmojiIds ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser

                        user =
                            localUser.user
                    in
                    { local
                        | localUser =
                            { localUser
                                | user =
                                    { user
                                        | availableCustomEmojis =
                                            SeqSet.union (NonemptySet.toSeqSet customEmojiIds) user.availableCustomEmojis
                                    }
                            }
                    }

                Local_VoiceChatChange voiceChatChange ->
                    case voiceChatChange of
                        Call.Local_Leave time ->
                            leaveCall time local

                        Call.Local_SetRemoteCallData _ ->
                            local

                Local_Game guildOrDmId gameChange ->
                    gameChangeUpdate
                        local.localUser.session.userId
                        guildOrDmId
                        gameChange
                        local

                Local_Drawing guildOrDmId threadRoute drawingChange ->
                    LocalState.drawingHandleChangeFrontend guildOrDmId threadRoute changedBy drawingChange local

                Local_SetMuteChannel guildId channelId isMuted ->
                    setMuteChannel guildId channelId isMuted local

                Local_SetMuteThread guildId channelId threadId isMuted ->
                    setMuteThread guildId channelId threadId isMuted local

                Local_SetMuteDiscordChannel _ guildId channelId isMuted ->
                    setMuteDiscordChannel guildId channelId isMuted local

                Local_SetMuteDiscordThread _ guildId channelId threadId isMuted ->
                    setMuteDiscordThread guildId channelId threadId isMuted local

                Local_SetMuteGuild guildId isMuted ->
                    setMuteGuild guildId isMuted local

                Local_SetMuteDiscordGuild _ guildId isMuted ->
                    setMuteDiscordGuild guildId isMuted local

                Local_RequestE2ee { otherUserId } ->
                    LocalState.setDmE2ee
                        otherUserId
                        (DmChannel.E2eeRequestedBy ( local.localUser.session.userId, local.localUser.session.sessionIdHash ))
                        local

                Local_DeclineE2eeRequestAsInitiator { otherUserId } ->
                    LocalState.setDmE2ee otherUserId DmChannel.E2eeDisabled local

                Local_DeclineE2eeRequest { otherUserId } ->
                    LocalState.setDmE2ee
                        otherUserId
                        (DmChannel.E2eeDeclinedBy local.localUser.session.userId)
                        local

                Local_SendEncryptedMessage createdAt { otherUserId } content threadRouteWithRepliedTo attachedFiles ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser

                        local2 : LocalState
                        local2 =
                            addEncryptedDmMessage
                                createdAt
                                localUser.session.userId
                                otherUserId
                                content
                                threadRouteWithRepliedTo
                                attachedFiles
                                local

                        ( currentlyViewing2, user2 ) =
                            LocalState.ownMessageIsReadFrontend
                                (GuildOrDmId (GuildOrDmId_Dm { otherUserId = otherUserId }))
                                (latestMessageThreadRoute
                                    threadRouteWithRepliedTo
                                    (SeqDict.get otherUserId local2.dmChannels
                                        |> Maybe.withDefault DmChannel.frontendInit
                                    )
                                )
                                ( localUser.currentlyViewing, localUser.user )
                    in
                    { local2
                        | localUser =
                            { localUser | currentlyViewing = currentlyViewing2, user = user2 }
                    }

                Local_AcceptE2ee { otherUserId } time _ ->
                    case SeqDict.get otherUserId local.dmChannels of
                        Just dmChannel ->
                            case dmChannel.e2ee of
                                E2eeRequestedBy requestedBy ->
                                    LocalState.setDmE2ee
                                        otherUserId
                                        (DmChannel.E2eeEnabled { enabledAt = time, requestedBy = requestedBy })
                                        local

                                E2eeDisabled ->
                                    local

                                E2eeDeclinedBy _ ->
                                    local

                                E2eeEnabled _ ->
                                    local

                        Nothing ->
                            local

                Local_SetE2eeRisksAccepted isAccepted ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser

                        user : FrontendCurrentUser
                        user =
                            localUser.user
                    in
                    { local | localUser = { localUser | user = { user | e2eeRisksAccepted = isAccepted } } }

                Local_EncryptOldMessages { otherUserId } messages ->
                    { local
                        | dmChannels =
                            SeqDict.updateIfExists
                                otherUserId
                                (encryptOldMessages messages)
                                local.dmChannels
                    }

                Local_SetPublicKey publicKey _ ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser

                        user : FrontendCurrentUser
                        user =
                            localUser.user
                    in
                    { local | localUser = { localUser | user = { user | publicKey = Just publicKey } } }

        ServerChange serverChange ->
            case serverChange of
                Server_SendMessage createdBy createdByUser createdAt guildOrDmId text threadRouteWithRepliedTo attachedFiles stickers ->
                    case guildOrDmId of
                        GuildOrDmId_Guild id ->
                            case LocalState.getGuildAndChannel id local of
                                Just ( guild, channel ) ->
                                    let
                                        localUser : LocalUser
                                        localUser =
                                            local.localUser

                                        user : FrontendCurrentUser
                                        user =
                                            localUser.user

                                        threadRouteNoReply : ThreadRoute
                                        threadRouteNoReply =
                                            case threadRouteWithRepliedTo of
                                                ViewThreadWithMaybeMessage threadId _ ->
                                                    ViewThread threadId

                                                NoThreadWithMaybeMessage _ ->
                                                    NoThread

                                        isViewing2 : Bool
                                        isViewing2 =
                                            isViewing (GuildOrDmId guildOrDmId) threadRouteNoReply local

                                        ( currentlyViewing2, user2 ) =
                                            case ( isViewing2, createdBy == localUser.session.userId ) of
                                                ( _, True ) ->
                                                    LocalState.ownMessageIsReadFrontend
                                                        (GuildOrDmId guildOrDmId)
                                                        (newMessageThreadRoute threadRouteWithRepliedTo channel)
                                                        ( localUser.currentlyViewing, user )

                                                ( True, _ ) ->
                                                    LocalState.incrementLastViewedMessageFrontend
                                                        (GuildOrDmId guildOrDmId)
                                                        (newMessageThreadRoute threadRouteWithRepliedTo channel)
                                                        ( localUser.currentlyViewing, user )

                                                ( False, _ ) ->
                                                    ( localUser.currentlyViewing
                                                    , if
                                                        LocalState.usersMentionedOrRepliedToFrontend
                                                            threadRouteWithRepliedTo
                                                            text
                                                            channel
                                                            |> SeqSet.member localUser.session.userId
                                                      then
                                                        User.addDirectMention
                                                            id.guildId
                                                            id.channelId
                                                            threadRouteNoReply
                                                            user

                                                      else
                                                        user
                                                    )
                                    in
                                    { local
                                        | guilds =
                                            guildSendMessage
                                                id.guildId
                                                guild
                                                id.channelId
                                                channel
                                                threadRouteWithRepliedTo
                                                createdAt
                                                createdBy
                                                text
                                                attachedFiles
                                                local
                                        , localUser =
                                            { localUser
                                                | user = user2
                                                , currentlyViewing = currentlyViewing2
                                                , otherUsers = addMessageSender createdBy createdByUser localUser
                                                , stickers = SeqDict.union stickers localUser.stickers
                                            }
                                    }

                                Nothing ->
                                    local

                        GuildOrDmId_Dm id ->
                            handleServerSendDmMessage
                                id
                                createdBy
                                createdByUser
                                stickers
                                (\maybeReplyTo ->
                                    Message.userTextMessageFrontend
                                        createdAt
                                        createdBy
                                        text
                                        maybeReplyTo
                                        attachedFiles
                                )
                                (\maybeReplyTo ->
                                    Message.userTextMessageFrontend
                                        createdAt
                                        createdBy
                                        text
                                        maybeReplyTo
                                        attachedFiles
                                )
                                threadRouteWithRepliedTo
                                local

                Server_Discord_SendMessage createdAt guildOrDmId createdByUser text threadRouteWithRepliedTo attachedFiles stickers ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild { currentUserId, guildId, channelId } ->
                            case LocalState.getDiscordGuildAndChannel guildId channelId local of
                                Just ( guild, channel ) ->
                                    let
                                        localUser : LocalUser
                                        localUser =
                                            local.localUser

                                        user : FrontendCurrentUser
                                        user =
                                            localUser.user

                                        threadRouteNoReply : ThreadRoute
                                        threadRouteNoReply =
                                            case threadRouteWithRepliedTo of
                                                ViewThreadWithMaybeMessage threadId _ ->
                                                    ViewThread threadId

                                                NoThreadWithMaybeMessage _ ->
                                                    NoThread

                                        {- A Discord channel keeps its unread state under the
                                           reader's own Discord account, not the account that
                                           wrote the message, so the id has to come from what
                                           they are looking at rather than from the message.
                                        -}
                                        readingItNow : Maybe AnyGuildOrDmId
                                        readingItNow =
                                            case ( localUser.currentlyViewing, threadRouteNoReply ) of
                                                ( UserSession.Viewing_DiscordChannel data, NoThread ) ->
                                                    if data.id.guildId == guildId && data.id.channelId == channelId then
                                                        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild data.id) |> Just

                                                    else
                                                        Nothing

                                                ( UserSession.Viewing_DiscordChannelThread data, ViewThread threadId ) ->
                                                    if
                                                        data.id.guildId
                                                            == guildId
                                                            && (data.id.channelId == channelId)
                                                            && (data.id.threadId == threadId)
                                                    then
                                                        DiscordGuildOrDmId
                                                            (DiscordGuildOrDmId_Guild
                                                                { guildId = data.id.guildId
                                                                , channelId = data.id.channelId
                                                                , currentUserId = data.id.currentUserId
                                                                }
                                                            )
                                                            |> Just

                                                    else
                                                        Nothing

                                                _ ->
                                                    Nothing

                                        ( currentlyViewing2, user2 ) =
                                            if LinkedAndOtherDiscordUsers.isLinkedUser currentUserId localUser.discordUsers then
                                                LocalState.ownMessageIsReadFrontend
                                                    (DiscordGuildOrDmId guildOrDmId)
                                                    (newMessageThreadRoute threadRouteWithRepliedTo channel)
                                                    ( localUser.currentlyViewing, user )

                                            else
                                                case readingItNow of
                                                    Just guildOrDmId2 ->
                                                        LocalState.incrementLastViewedMessageFrontend
                                                            guildOrDmId2
                                                            (newMessageThreadRoute threadRouteWithRepliedTo channel)
                                                            ( localUser.currentlyViewing, user )

                                                    Nothing ->
                                                        ( localUser.currentlyViewing
                                                        , if
                                                            LocalState.usersMentionedOrRepliedToFrontend
                                                                threadRouteWithRepliedTo
                                                                text
                                                                channel
                                                                |> SeqSet.intersect
                                                                    (SeqDict.keys (LinkedAndOtherDiscordUsers.linkedUsers localUser.discordUsers)
                                                                        |> SeqSet.fromList
                                                                    )
                                                                |> SeqSet.isEmpty
                                                                |> not
                                                          then
                                                            User.addDiscordDirectMention
                                                                guildId
                                                                channelId
                                                                threadRouteNoReply
                                                                user

                                                          else
                                                            user
                                                        )
                                    in
                                    { local
                                        | discordGuilds =
                                            discordGuildSendMessage
                                                guildId
                                                guild
                                                channelId
                                                channel
                                                threadRouteWithRepliedTo
                                                createdAt
                                                currentUserId
                                                text
                                                attachedFiles
                                                local
                                        , localUser =
                                            { localUser
                                                | user = user2
                                                , currentlyViewing = currentlyViewing2
                                                , discordUsers =
                                                    LinkedAndOtherDiscordUsers.addOtherUser
                                                        currentUserId
                                                        createdByUser
                                                        localUser.discordUsers
                                                , stickers = SeqDict.union stickers localUser.stickers
                                            }
                                    }

                                Nothing ->
                                    local

                        DiscordGuildOrDmId_Dm data ->
                            case SeqDict.get data.channelId local.discordDmChannels of
                                Just dmChannel ->
                                    let
                                        localUser : LocalUser
                                        localUser =
                                            local.localUser

                                        user : FrontendCurrentUser
                                        user =
                                            localUser.user

                                        dmChannel2 : DiscordFrontendDmChannel
                                        dmChannel2 =
                                            LocalState.createChannelMessageFrontend
                                                (Message.userTextMessageFrontend
                                                    createdAt
                                                    data.currentUserId
                                                    text
                                                    (case threadRouteWithRepliedTo of
                                                        NoThreadWithMaybeMessage maybeReplyTo ->
                                                            maybeReplyTo

                                                        ViewThreadWithMaybeMessage _ _ ->
                                                            Nothing
                                                    )
                                                    attachedFiles
                                                )
                                                dmChannel

                                        {- The reader's own Discord account is the one this DM
                                           keeps its unread state under, so the id comes from
                                           what they are looking at rather than from the
                                           account that wrote the message.
                                        -}
                                        readingItNow : Maybe AnyGuildOrDmId
                                        readingItNow =
                                            case localUser.currentlyViewing of
                                                UserSession.Viewing_DiscordDm viewingData ->
                                                    if viewingData.id.channelId == data.channelId then
                                                        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm viewingData.id) |> Just

                                                    else
                                                        Nothing

                                                _ ->
                                                    Nothing

                                        ( currentlyViewing2, user2 ) =
                                            if LinkedAndOtherDiscordUsers.isLinkedUser data.currentUserId localUser.discordUsers then
                                                LocalState.ownMessageIsReadFrontend
                                                    (DiscordGuildOrDmId guildOrDmId)
                                                    (DmChannel.latestFrontendMessageId dmChannel2
                                                        |> NoThreadWithMessage
                                                    )
                                                    ( localUser.currentlyViewing, user )

                                            else
                                                case readingItNow of
                                                    Just guildOrDmId2 ->
                                                        LocalState.incrementLastViewedMessageFrontend
                                                            guildOrDmId2
                                                            (DmChannel.latestFrontendMessageId dmChannel2
                                                                |> NoThreadWithMessage
                                                            )
                                                            ( localUser.currentlyViewing, user )

                                                    Nothing ->
                                                        ( localUser.currentlyViewing, user )
                                    in
                                    { local
                                        | discordDmChannels = SeqDict.insert data.channelId dmChannel2 local.discordDmChannels
                                        , localUser =
                                            { localUser
                                                | user = user2
                                                , currentlyViewing = currentlyViewing2
                                                , discordUsers =
                                                    LinkedAndOtherDiscordUsers.addOtherUser
                                                        data.currentUserId
                                                        createdByUser
                                                        localUser.discordUsers
                                                , stickers = SeqDict.union stickers localUser.stickers
                                            }
                                    }

                                Nothing ->
                                    local

                Server_NewChannel time guildId channelName channelDescription ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.createChannelFrontend time local.localUser.session.userId channelName channelDescription)
                                local.guilds
                    }

                Server_EditChannel guildId channelId channelName channelDescription ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.editChannel channelName channelDescription channelId)
                                local.guilds
                    }

                Server_DeleteChannel guildId channelId ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.deleteChannelFrontend channelId)
                                local.guilds
                    }

                Server_EditGuildName guildId guildName ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.editGuildName guildName)
                                local.guilds
                    }

                Server_DeleteGuild guildId ->
                    { local | guilds = SeqDict.remove guildId local.guilds }

                Server_NewInviteLink time userId guildId inviteLinkId ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.addInvite inviteLinkId userId time)
                                local.guilds
                    }

                Server_DeleteInviteLink guildId inviteLinkId ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.removeInvite inviteLinkId)
                                local.guilds
                    }

                Server_MemberJoined time userId guildId user ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (\guild -> LocalState.addMemberFrontend time userId guild |> Result.withDefault guild)
                                local.guilds
                        , localUser = { localUser | otherUsers = SeqDict.insert userId user localUser.otherUsers }
                    }

                Server_MemberLeft userId guildId ->
                    if userId == local.localUser.session.userId then
                        { local | guilds = SeqDict.remove guildId local.guilds }

                    else
                        { local
                            | guilds =
                                SeqDict.updateIfExists
                                    guildId
                                    (\guild ->
                                        { guild
                                            | membersAndOwner =
                                                MembersAndOwner.removeMember userId guild.membersAndOwner
                                        }
                                    )
                                    local.guilds
                        }

                Server_YouJoinedGuildByInvite result ->
                    case result of
                        Ok ok ->
                            let
                                localUser =
                                    local.localUser
                            in
                            { local
                                | guilds =
                                    SeqDict.insert ok.guildId ok.guild local.guilds
                                , localUser =
                                    { localUser
                                        | otherUsers =
                                            SeqDict.insert
                                                (MembersAndOwner.owner ok.guild.membersAndOwner)
                                                ok.owner
                                                localUser.otherUsers
                                                |> SeqDict.union ok.members
                                        , user =
                                            LocalState.markAllChannelsAndThreadsAsViewedFrontend
                                                ok.guildId
                                                ok.guild
                                                localUser.user
                                    }
                            }

                        Err error ->
                            { local | joinGuildError = Just error }

                Server_MemberTyping time userId guildOrDmId threadRoute ->
                    memberTyping time userId guildOrDmId threadRoute local

                Server_DiscordGuildMemberTyping time userId guildId channelId threadRoute ->
                    discordGuildMemberTyping time userId guildId channelId threadRoute local

                Server_DiscordDmMemberTyping time userId channelId ->
                    discordDmMemberTyping time userId channelId local

                Server_AddReactionEmoji userId guildOrDmId messageIndex emoji ->
                    addReactionEmoji userId (GuildOrDmId guildOrDmId) messageIndex emoji local

                Server_RemoveReactionEmoji userId guildOrDmId messageIndex emoji ->
                    removeReactionEmoji userId (GuildOrDmId guildOrDmId) messageIndex emoji local

                Server_DiscordAddReactionGuildEmoji userId guildId channelId threadRoute emoji ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.updateChannel
                                    (LocalState.addReactionEmojiFrontend emoji userId threadRoute)
                                    channelId
                                )
                                local.discordGuilds
                    }

                Server_DiscordAddReactionDmEmoji userId channelId messageId emoji ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                channelId
                                (LocalState.addReactionEmojiFrontendHelper emoji userId messageId)
                                local.discordDmChannels
                    }

                Server_DiscordRemoveReactionGuildEmoji userId guildId channelId threadRoute emoji ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.updateChannel
                                    (LocalState.removeReactionEmojiFrontend emoji userId threadRoute)
                                    channelId
                                )
                                local.discordGuilds
                    }

                Server_DiscordRemoveReactionDmEmoji userId channelId messageId emoji ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                channelId
                                (LocalState.removeReactionEmojiFrontendHelper emoji userId messageId)
                                local.discordDmChannels
                    }

                Server_SendEditMessage time userId guildOrDmId threadRoute newContent attachedFiles ->
                    case guildOrDmId of
                        GuildOrDmId_Guild { guildId, channelId } ->
                            { local
                                | guilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (\guild ->
                                            LocalState.updateChannel
                                                (\channel ->
                                                    LocalState.editMessageFrontendHelper
                                                        time
                                                        userId
                                                        newContent
                                                        (ChangeAttachments attachedFiles)
                                                        threadRoute
                                                        channel
                                                        |> Result.withDefault channel
                                                )
                                                channelId
                                                guild
                                        )
                                        local.guilds
                            }

                        GuildOrDmId_Dm { otherUserId } ->
                            { local
                                | dmChannels =
                                    SeqDict.updateIfExists
                                        otherUserId
                                        (\dmChannel ->
                                            LocalState.editMessageFrontendHelper
                                                time
                                                userId
                                                newContent
                                                (ChangeAttachments attachedFiles)
                                                threadRoute
                                                dmChannel
                                                |> Result.withDefault dmChannel
                                        )
                                        local.dmChannels
                            }

                Server_DiscordSendEditGuildMessage time editedBy guildId channelId threadRoute newContent ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.updateChannel
                                    (\channel ->
                                        LocalState.editMessageFrontendHelper
                                            time
                                            editedBy
                                            newContent
                                            DoNotChangeAttachments
                                            threadRoute
                                            channel
                                            |> Result.withDefault channel
                                    )
                                    channelId
                                )
                                local.discordGuilds
                    }

                Server_DiscordSendEditDmMessage time data messageId newContent ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                data.channelId
                                (\dmChannel ->
                                    LocalState.editMessageFrontendHelperNoThread
                                        time
                                        data.currentUserId
                                        newContent
                                        DoNotChangeAttachments
                                        messageId
                                        dmChannel
                                        |> Result.withDefault dmChannel
                                )
                                local.discordDmChannels
                    }

                Server_MemberEditTyping time userId guildOrDmId messageIndex ->
                    memberEditTyping time userId guildOrDmId messageIndex local

                Server_DeleteMessage guildOrDmId messageIndex ->
                    deleteMessage guildOrDmId messageIndex local

                Server_DiscordDeleteGuildMessage guildId channelId threadRoute ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.deleteMessageFrontend channelId threadRoute)
                                local.discordGuilds
                    }

                Server_DiscordForumPostDeleted guildId forumId messageId ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.deleteForumPostFrontend forumId messageId)
                                local.discordGuilds
                    }

                Server_DiscordDeleteDmMessage channelId messageId ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                channelId
                                (LocalState.deleteMessageFrontendNoThread messageId)
                                local.discordDmChannels
                    }

                Server_SetName userId name ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | otherUsers =
                                    SeqDict.updateIfExists userId (User.setName name) localUser.otherUsers
                            }
                    }

                Server_SetUserColor userId color ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | otherUsers =
                                    SeqDict.updateIfExists userId (User.setColor color) localUser.otherUsers
                            }
                    }

                Server_SetUserIcon userId icon ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | user =
                                    if localUser.session.userId == userId then
                                        User.setIcon icon localUser.user

                                    else
                                        localUser.user
                                , otherUsers =
                                    SeqDict.updateIfExists userId (User.setIcon icon) localUser.otherUsers
                            }
                    }

                Server_SetGuildIcon guildId icon ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists guildId (\guild -> { guild | icon = icon }) local.guilds
                    }

                Server_PushNotificationsReset publicVapidKey ->
                    { local | publicVapidKey = publicVapidKey }

                Server_SetGuildNotificationLevel guildId notificationLevel ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | user = User.setGuildNotificationLevel guildId notificationLevel localUser.user
                            }
                    }

                Server_SetDiscordGuildNotificationLevel guildId notificationLevel ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | user = User.setDiscordGuildNotificationLevel guildId notificationLevel localUser.user
                            }
                    }

                Server_PushNotificationFailed subscribeData error ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser

                        session : UserSession
                        session =
                            localUser.session
                    in
                    { local
                        | localUser =
                            { localUser | session = { session | pushSubscription = SubscriptionError subscribeData error } }
                    }

                Server_NewSession sessionId session ->
                    { local | otherSessions = SeqDict.insert sessionId session local.otherSessions }

                Server_LoggedOut sessionId ->
                    { local | otherSessions = SeqDict.remove sessionId local.otherSessions }

                Server_CurrentlyViewing sessionIdHash clientId currentlyViewing ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    if sessionIdHash == localUser.session.sessionIdHash then
                        { local
                            | localUser =
                                { localUser | currentlyViewing = currentlyViewing }
                        }

                    else
                        { local
                            | otherSessions =
                                SeqDict.updateIfExists
                                    sessionIdHash
                                    (\session ->
                                        { session
                                            | currentlyViewing =
                                                SeqDict.insert clientId currentlyViewing session.currentlyViewing
                                        }
                                    )
                                    local.otherSessions
                        }

                Server_ClientDisconnected sessionId clientId disconnectedAt ->
                    { local
                        | otherSessions =
                            SeqDict.updateIfExists
                                sessionId
                                (\session ->
                                    { session
                                        | currentlyViewing = SeqDict.remove clientId session.currentlyViewing
                                        , lastActiveAt = disconnectedAt
                                    }
                                )
                                local.otherSessions
                    }

                Server_TextEditor serverChange2 ->
                    { local | textEditor = TextEditor.changeUpdate serverChange2 local.textEditor }

                Server_LinkDiscordUser userId user ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | discordUsers =
                                    LinkedAndOtherDiscordUsers.addLinkedUser userId user localUser.discordUsers
                            }
                    }

                Server_UnlinkDiscordUser userId ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser | discordUsers = LinkedAndOtherDiscordUsers.unlinkUser userId localUser.discordUsers }
                    }

                Server_DiscordChannelCreated guildId channelId isForum channelName topic permissionOverwrites ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (\guild ->
                                    { guild
                                        | channels =
                                            SeqDict.update
                                                channelId
                                                (\maybeChannel ->
                                                    case maybeChannel of
                                                        Just channel ->
                                                            { channel
                                                                | name = channelName
                                                                , description =
                                                                    LocalState.discordTopicToDescription
                                                                        topic
                                                                        ChannelDescription.empty
                                                                , isForum = isForum
                                                                , permissionOverwrites = permissionOverwrites
                                                            }
                                                                |> Just

                                                        Nothing ->
                                                            { name = channelName
                                                            , description =
                                                                LocalState.discordTopicToDescription
                                                                    topic
                                                                    ChannelDescription.empty
                                                            , isForum = isForum
                                                            , messages = MessageArray.empty
                                                            , visibleMessages = VisibleMessages.empty
                                                            , lastTypedAt = SeqDict.empty
                                                            , threads = SeqDict.empty
                                                            , dateDividerDrawings = SeqDict.empty
                                                            , permissionOverwrites = permissionOverwrites
                                                            }
                                                                |> Just
                                                )
                                                guild.channels
                                    }
                                )
                                local.discordGuilds
                    }

                Server_DiscordDmChannelCreated channelId members ->
                    { local
                        | discordDmChannels =
                            SeqDict.update
                                channelId
                                (\maybeChannel ->
                                    case maybeChannel of
                                        Just _ ->
                                            maybeChannel

                                        Nothing ->
                                            { messages = MessageArray.empty
                                            , visibleMessages = VisibleMessages.empty
                                            , lastTypedAt = SeqDict.empty
                                            , members = members
                                            , dateDividerDrawings = SeqDict.empty
                                            }
                                                |> Just
                                )
                                local.discordDmChannels
                    }

                Server_DiscordDmChannelRecipientRemoved channelId removedUserId ->
                    { local
                        | discordDmChannels =
                            SeqDict.update
                                channelId
                                (\maybe ->
                                    case maybe of
                                        Just channel ->
                                            case NonemptyDict.remove removedUserId channel.members |> NonemptyDict.fromSeqDict of
                                                Just members ->
                                                    Just { channel | members = members }

                                                Nothing ->
                                                    Just channel

                                        Nothing ->
                                            Nothing
                                )
                                local.discordDmChannels
                    }

                Server_DiscordNeedsAuthAgain userId ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | discordUsers =
                                    LinkedAndOtherDiscordUsers.updateLinkedUser
                                        userId
                                        (\user -> { user | needsAuthAgain = True })
                                        localUser.discordUsers
                            }
                    }

                Server_DiscordUserLoadingDataIsDone discordUserId result ->
                    let
                        localUser =
                            local.localUser
                    in
                    case result of
                        Ok data ->
                            let
                                local2 : LocalState
                                local2 =
                                    { local
                                        | localUser =
                                            { localUser
                                                | discordUsers =
                                                    SeqDict.foldl LinkedAndOtherDiscordUsers.addOtherUser localUser.discordUsers data.discordUsers
                                                        |> LinkedAndOtherDiscordUsers.updateLinkedUser
                                                            discordUserId
                                                            (\user -> { user | isLoadingData = DiscordUserLoadedSuccessfully })
                                            }
                                        , discordGuilds = SeqDict.foldl SeqDict.insert local.discordGuilds data.discordGuilds
                                        , discordDmChannels = SeqDict.foldl SeqDict.insert local.discordDmChannels data.discordDms
                                    }
                            in
                            if data.markEverythingAsViewed then
                                markDiscordDataAsViewed discordUserId local2

                            else
                                local2

                        Err time ->
                            { local
                                | localUser =
                                    { localUser
                                        | discordUsers =
                                            LinkedAndOtherDiscordUsers.updateLinkedUser
                                                discordUserId
                                                (\user -> { user | isLoadingData = DiscordUserLoadingFailed time })
                                                localUser.discordUsers
                                    }
                            }

                Server_StartReloadingDiscordUser time discordUserId ->
                    startReloadingDiscordUser time discordUserId local

                Server_LoadingDiscordChannelChanged userIdToLoadWith maybeLoading ->
                    case local.adminData of
                        IsAdmin adminData ->
                            { local
                                | adminData =
                                    { adminData
                                        | loadingDiscordChannels =
                                            case maybeLoading of
                                                Just loading ->
                                                    SeqDict.insert userIdToLoadWith loading adminData.loadingDiscordChannels

                                                Nothing ->
                                                    SeqDict.remove userIdToLoadWith adminData.loadingDiscordChannels
                                    }
                                        |> IsAdmin
                            }

                        IsAdminButDataNotLoaded ->
                            local

                        IsNotAdmin ->
                            local

                Server_LoadAdminData adminData ->
                    { local | adminData = initAdminData adminData |> IsAdmin }

                Server_BackupGenerated backup ->
                    { local
                        | adminData =
                            case local.adminData of
                                IsAdmin adminData ->
                                    IsAdmin { adminData | lastBackup = Just backup }

                                IsAdminButDataNotLoaded ->
                                    local.adminData

                                IsNotAdmin ->
                                    local.adminData
                    }

                Server_NewLog time log ->
                    { local
                        | adminData =
                            case local.adminData of
                                IsAdmin adminData ->
                                    IsAdmin
                                        { adminData
                                            | logs =
                                                Pagination.addItem
                                                    { time = time, log = log, isHidden = False }
                                                    adminData.logs
                                        }

                                IsAdminButDataNotLoaded ->
                                    local.adminData

                                IsNotAdmin ->
                                    local.adminData
                    }

                Server_GotGuildMessageEmbed guildId channelId threadRouteWithMessage result ->
                    case LocalState.getGuildAndChannel { guildId = guildId, channelId = channelId } local of
                        Just ( guild, channel ) ->
                            { local
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        { guild
                                            | channels =
                                                SeqDict.insert
                                                    channelId
                                                    (case threadRouteWithMessage of
                                                        NoThreadWithMessage messageId ->
                                                            LocalState.addEmbedFrontend messageId result channel

                                                        ViewThreadWithMessage threadId messageId ->
                                                            { channel
                                                                | threads =
                                                                    SeqDict.updateIfExists
                                                                        threadId
                                                                        (LocalState.addEmbedFrontend messageId result)
                                                                        channel.threads
                                                            }
                                                    )
                                                    guild.channels
                                        }
                                        local.guilds
                            }

                        Nothing ->
                            local

                Server_GotDmMessageEmbed channelId threadRouteWithMessage result ->
                    case SeqDict.get channelId local.dmChannels of
                        Just channel ->
                            { local
                                | dmChannels =
                                    SeqDict.insert
                                        channelId
                                        (case threadRouteWithMessage of
                                            NoThreadWithMessage messageId ->
                                                LocalState.addEmbedFrontend messageId result channel

                                            ViewThreadWithMessage threadId messageId ->
                                                { channel
                                                    | threads =
                                                        SeqDict.updateIfExists
                                                            threadId
                                                            (LocalState.addEmbedFrontend messageId result)
                                                            channel.threads
                                                }
                                        )
                                        local.dmChannels
                            }

                        Nothing ->
                            local

                Server_GotDiscordGuildMessageEmbed guildId channelId threadRouteWithMessage result ->
                    case LocalState.getDiscordGuildAndChannel guildId channelId local of
                        Just ( guild, channel ) ->
                            { local
                                | discordGuilds =
                                    SeqDict.insert
                                        guildId
                                        { guild
                                            | channels =
                                                SeqDict.insert
                                                    channelId
                                                    (case threadRouteWithMessage of
                                                        NoThreadWithMessage messageId ->
                                                            LocalState.addEmbedFrontend messageId result channel

                                                        ViewThreadWithMessage threadId messageId ->
                                                            { channel
                                                                | threads =
                                                                    SeqDict.updateIfExists
                                                                        threadId
                                                                        (LocalState.addEmbedFrontend messageId result)
                                                                        channel.threads
                                                            }
                                                    )
                                                    guild.channels
                                        }
                                        local.discordGuilds
                            }

                        Nothing ->
                            local

                Server_GotDiscordDmMessageEmbed channelId messageId result ->
                    case SeqDict.get channelId local.discordDmChannels of
                        Just channel ->
                            { local
                                | discordDmChannels =
                                    SeqDict.insert
                                        channelId
                                        (LocalState.addEmbedFrontend messageId result channel)
                                        local.discordDmChannels
                            }

                        Nothing ->
                            local

                Server_DiscordGuildJoinedOrCreated discordUserId guildId guild ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | discordGuilds =
                            SeqDict.update
                                guildId
                                (\maybe ->
                                    case maybe of
                                        Just _ ->
                                            maybe

                                        Nothing ->
                                            Just guild
                                )
                                local.discordGuilds
                        , localUser =
                            { localUser
                                | user =
                                    LocalState.markAllDiscordChannelsAndThreadsAsViewedFrontend
                                        discordUserId
                                        guildId
                                        guild
                                        localUser.user
                            }
                    }

                Server_DiscordUpdateChannel guildId channelId name topic permissionOverwrites ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.updateChannel
                                    (\channel ->
                                        { channel
                                            | name =
                                                case name of
                                                    Discord.Included (Just name2) ->
                                                        ChannelName.fromStringLossy name2

                                                    _ ->
                                                        channel.name
                                            , description =
                                                LocalState.discordTopicToDescription topic channel.description
                                            , permissionOverwrites = permissionOverwrites
                                        }
                                    )
                                    channelId
                                )
                                local.discordGuilds
                    }

                Server_DiscordUpdateRole guildId roleId role ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (\guild -> { guild | roles = SeqDict.insert roleId role guild.roles })
                                local.discordGuilds
                    }

                Server_DiscordUpdateGuildCustomEmojis guildId customEmojis ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (\guild -> { guild | customEmojis = customEmojis })
                                local.discordGuilds
                    }

                Server_UpdateDiscordMembers guildId members ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (\guild -> { guild | membersAndOwner = members })
                                local.discordGuilds
                    }

                Server_DiscordGuildMemberJoined time guildId channelId userJoinedId name color ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (\guild ->
                                    { guild
                                        | membersAndOwner =
                                            MembersAndOwner.addMember
                                                userJoinedId
                                                { joinedAt = Just time, roles = SeqSet.empty }
                                                guild.membersAndOwner
                                                |> Result.withDefault guild.membersAndOwner
                                        , channels =
                                            SeqDict.updateIfExists
                                                channelId
                                                (LocalState.createChannelMessageFrontend
                                                    (UserJoinedMessage
                                                        time
                                                        userJoinedId
                                                        SeqDict.empty
                                                        Drawing.emptyDrawing
                                                    )
                                                )
                                                guild.channels
                                    }
                                )
                                local.discordGuilds
                        , localUser =
                            { localUser
                                | discordUsers =
                                    LinkedAndOtherDiscordUsers.updateOtherUser
                                        userJoinedId
                                        (\maybe ->
                                            case maybe of
                                                Just user ->
                                                    { user | name = name }

                                                Nothing ->
                                                    { name = name, icon = Nothing, color = color }
                                        )
                                        localUser.discordUsers
                            }
                    }

                Server_LinkedDiscordUserStickersLoaded newStickers ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | stickers = SeqDict.union newStickers localUser.stickers
                                , user = User.addNewStickers newStickers localUser.user
                            }
                    }

                Server_LinkedDiscordUserCustomEmojisLoaded newCustomEmojis ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | customEmojis = SeqDict.union newCustomEmojis localUser.customEmojis
                                , user = User.addNewCustomEmojis newCustomEmojis localUser.user
                            }
                    }

                Server_VoiceChatChange voiceChatChange ->
                    let
                        calls : Call.Local
                        calls =
                            local.calls
                    in
                    case voiceChatChange of
                        Call.Server_YouJoined time roomId ->
                            joinCallHelper
                                local.localUser.session.userId
                                time
                                ((calls.currentRoom == Just roomId) || SeqDict.member roomId calls.voiceChats)
                                roomId
                                { calls | currentRoom = Just roomId }
                                local

                        Call.Server_OtherJoined time { roomId, otherClientId } ->
                            joinCallHelper
                                (Tuple.first otherClientId)
                                time
                                ((calls.currentRoom == Just roomId) || SeqDict.member roomId calls.voiceChats)
                                roomId
                                { calls
                                    | voiceChats =
                                        SeqDictHelper.addToDict
                                            roomId
                                            otherClientId
                                            Call.defaultRemoteCallData
                                            calls.voiceChats
                                }
                                local

                        Call.Server_Left time connectionId ->
                            otherUserLeaveCall time connectionId local

                        Call.Server_SetRemoteCallData connectionId remoteCallData ->
                            { local
                                | calls =
                                    { calls
                                        | voiceChats =
                                            SeqDict.updateIfExists
                                                connectionId.roomId
                                                (NonemptyDict.insert connectionId.otherClientId remoteCallData)
                                                calls.voiceChats
                                    }
                            }

                Server_Game changeBy guildOrDmId gameChange ->
                    gameChangeUpdate changeBy guildOrDmId gameChange local

                Server_Drawing changeBy guildOrDmId threadRoute drawingChange ->
                    LocalState.drawingHandleChangeFrontend guildOrDmId threadRoute changeBy drawingChange local

                Server_SetMuteChannel guildId channelId isMuted ->
                    setMuteChannel guildId channelId isMuted local

                Server_SetMuteThread guildId channelId threadId isMuted ->
                    setMuteThread guildId channelId threadId isMuted local

                Server_SetMuteDiscordChannel guildId channelId isMuted ->
                    setMuteDiscordChannel guildId channelId isMuted local

                Server_SetMuteDiscordThread guildId channelId threadId isMuted ->
                    setMuteDiscordThread guildId channelId threadId isMuted local

                Server_SetMuteGuild guildId isMuted ->
                    setMuteGuild guildId isMuted local

                Server_SetMuteDiscordGuild guildId isMuted ->
                    setMuteDiscordGuild guildId isMuted local

                Server_E2eeRequested { otherUserId } requestedBy ->
                    LocalState.setDmE2ee otherUserId (DmChannel.E2eeRequestedBy requestedBy) local

                Server_E2eeRequestCancelled { otherUserId } ->
                    LocalState.setDmE2ee otherUserId DmChannel.E2eeDisabled local

                Server_E2eeRequestDeclined { otherUserId } declinedBy ->
                    LocalState.setDmE2ee otherUserId (DmChannel.E2eeDeclinedBy declinedBy) local

                Server_SetPublicKey userId publicKey ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | otherUsers =
                                    SeqDict.updateIfExists
                                        userId
                                        (\otherUser -> { otherUser | publicKey = Just publicKey })
                                        localUser.otherUsers
                            }
                    }

                Server_E2eeAccepted { otherUserId } time ->
                    LocalState.setDmE2ee
                        otherUserId
                        (DmChannel.E2eeEnabled
                            { enabledAt = time
                            , requestedBy = ( local.localUser.session.userId, local.localUser.session.sessionIdHash )
                            }
                        )
                        local

                Server_SendEncryptedMessage createdBy createdByUser createdAt id content threadRouteWithRepliedTo attachedFiles ->
                    handleServerSendDmMessage
                        id
                        createdBy
                        createdByUser
                        -- TODO, solve stickers
                        SeqDict.empty
                        (\maybeReplyTo ->
                            Message.encryptedUserTextMessageFrontend createdAt createdBy content maybeReplyTo attachedFiles
                        )
                        (\maybeReplyTo ->
                            Message.encryptedUserTextMessageFrontend createdAt createdBy content maybeReplyTo attachedFiles
                        )
                        threadRouteWithRepliedTo
                        local

                Server_DiscordAvatarsLoaded discordUserId discordUser ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | discordUsers =
                                    LinkedAndOtherDiscordUsers.addOtherUser
                                        discordUserId
                                        discordUser
                                        localUser.discordUsers
                                        |> LinkedAndOtherDiscordUsers.updateLinkedUser
                                            discordUserId
                                            (\linkedUser ->
                                                { linkedUser | name = discordUser.name, icon = discordUser.icon }
                                            )
                            }
                    }


callStartedMessage : Time.Posix -> Id UserId -> Message ChannelMessageId (Id UserId)
callStartedMessage time startedBy =
    CallStarted
        { startedAt = time
        , endedAt = Nothing
        , startedBy = startedBy
        , reactions = SeqDict.empty
        , timestampDrawings = Drawing.emptyDrawing
        , cardDrawings = Drawing.emptyDrawing
        }


{-| The first person into a call leaves a card behind in the conversation it was started
from. It is their own doing, so it doesn't leave them with something unread.
-}
joinCallHelper : Id UserId -> Time.Posix -> Bool -> CallId -> Call.Local -> LocalState -> LocalState
joinCallHelper userId time alreadyInCall roomId calls2 local =
    if alreadyInCall then
        { local | calls = calls2 }

    else
        case roomId of
            DmRoomId { otherUserId } ->
                let
                    localUser : LocalUser
                    localUser =
                        local.localUser

                    dmChannel : FrontendDmChannel
                    dmChannel =
                        SeqDict.get otherUserId local.dmChannels
                            |> Maybe.withDefault DmChannel.frontendInit

                    ( currentlyViewing2, user2 ) =
                        if userId == localUser.session.userId then
                            LocalState.ownMessageIsReadFrontend
                                (GuildOrDmId (GuildOrDmId_Dm { otherUserId = otherUserId }))
                                (MessageArray.length dmChannel.messages |> Id.fromInt |> NoThreadWithMessage)
                                ( localUser.currentlyViewing, localUser.user )

                        else
                            ( localUser.currentlyViewing, localUser.user )
                in
                { local
                    | calls = calls2
                    , dmChannels =
                        SeqDict.insert
                            otherUserId
                            (LocalState.createChannelMessageFrontend (callStartedMessage time userId) dmChannel)
                            local.dmChannels
                    , localUser = { localUser | user = user2, currentlyViewing = currentlyViewing2 }
                }

            GuildRoomId id ->
                let
                    localUser : LocalUser
                    localUser =
                        local.localUser

                    ( currentlyViewing2, user2 ) =
                        case ( userId == localUser.session.userId, LocalState.getGuildAndChannel id local ) of
                            ( True, Just ( _, channel ) ) ->
                                LocalState.ownMessageIsReadFrontend
                                    (GuildOrDmId (GuildOrDmId_Guild id))
                                    (MessageArray.length channel.messages |> Id.fromInt |> NoThreadWithMessage)
                                    ( localUser.currentlyViewing, localUser.user )

                            _ ->
                                ( localUser.currentlyViewing, localUser.user )
                in
                { local
                    | calls = calls2
                    , guilds =
                        SeqDict.updateIfExists
                            id.guildId
                            (LocalState.updateChannel
                                (LocalState.createChannelMessageFrontend (callStartedMessage time userId))
                                id.channelId
                            )
                            local.guilds
                    , localUser = { localUser | user = user2, currentlyViewing = currentlyViewing2 }
                }


setMuteGuild : Id GuildId -> IsMuted -> LocalState -> LocalState
setMuteGuild guildId isMuted local =
    let
        localUser : LocalUser
        localUser =
            local.localUser

        user : FrontendCurrentUser
        user =
            localUser.user
    in
    { local
        | localUser =
            { localUser
                | user = { user | muteSettings = MuteSettings.setMuteGuild guildId isMuted user.muteSettings }
            }
    }


setMuteChannel : Id GuildId -> Id ChannelId -> IsMuted -> LocalState -> LocalState
setMuteChannel guildId channelId isMuted local =
    let
        localUser : LocalUser
        localUser =
            local.localUser

        user : FrontendCurrentUser
        user =
            localUser.user
    in
    { local
        | localUser =
            { localUser
                | user =
                    { user
                        | muteSettings = MuteSettings.setMuteChannel guildId channelId isMuted user.muteSettings
                    }
            }
    }


setMuteThread : Id GuildId -> Id ChannelId -> Id ChannelMessageId -> IsMuted -> LocalState -> LocalState
setMuteThread guildId channelId threadId isMuted local =
    let
        localUser : LocalUser
        localUser =
            local.localUser

        user : FrontendCurrentUser
        user =
            localUser.user
    in
    { local
        | localUser =
            { localUser
                | user =
                    { user
                        | muteSettings =
                            MuteSettings.setMuteThread guildId channelId threadId isMuted user.muteSettings
                    }
            }
    }


setMuteDiscordGuild : Discord.Id Discord.GuildId -> IsMuted -> LocalState -> LocalState
setMuteDiscordGuild guildId isMuted local =
    let
        localUser : LocalUser
        localUser =
            local.localUser

        user : FrontendCurrentUser
        user =
            localUser.user
    in
    { local
        | localUser =
            { localUser
                | user = { user | muteSettings = MuteSettings.setMuteDiscordGuild guildId isMuted user.muteSettings }
            }
    }


setMuteDiscordChannel : Discord.Id Discord.GuildId -> Discord.Id Discord.ChannelId -> IsMuted -> LocalState -> LocalState
setMuteDiscordChannel guildId channelId isMuted local =
    let
        localUser : LocalUser
        localUser =
            local.localUser

        user : FrontendCurrentUser
        user =
            localUser.user
    in
    { local
        | localUser =
            { localUser
                | user =
                    { user
                        | muteSettings = MuteSettings.setMuteDiscordChannel guildId channelId isMuted user.muteSettings
                    }
            }
    }


setMuteDiscordThread :
    Discord.Id Discord.GuildId
    -> Discord.Id Discord.ChannelId
    -> Id ChannelMessageId
    -> IsMuted
    -> LocalState
    -> LocalState
setMuteDiscordThread guildId channelId threadId isMuted local =
    let
        localUser : LocalUser
        localUser =
            local.localUser

        user : FrontendCurrentUser
        user =
            localUser.user
    in
    { local
        | localUser =
            { localUser
                | user =
                    { user
                        | muteSettings =
                            MuteSettings.setMuteDiscordThread guildId channelId threadId isMuted user.muteSettings
                    }
            }
    }


{-| Starting a game leaves a card behind in the conversation it was started from. It is the
starter's own doing, so it doesn't leave them with something unread.
-}
gameChangeUpdate : Id UserId -> GuildOrDmId -> Game.LocalChange -> LocalState -> LocalState
gameChangeUpdate changeBy guildOrDmId gameChange local =
    case guildOrDmId of
        GuildOrDmId_Dm { otherUserId } ->
            let
                localUser : LocalUser
                localUser =
                    local.localUser

                dmChannel : FrontendDmChannel
                dmChannel =
                    SeqDict.get otherUserId local.dmChannels
                        |> Maybe.withDefault DmChannel.frontendInit

                ( currentlyViewing2, user2 ) =
                    if gameStartsMatch gameChange && changeBy == localUser.session.userId then
                        LocalState.ownMessageIsReadFrontend
                            (GuildOrDmId (GuildOrDmId_Dm { otherUserId = otherUserId }))
                            (MessageArray.length dmChannel.messages |> Id.fromInt |> NoThreadWithMessage)
                            ( localUser.currentlyViewing, localUser.user )

                    else
                        ( localUser.currentlyViewing, localUser.user )
            in
            { local
                | dmChannels =
                    SeqDict.insert
                        otherUserId
                        (gameChangeUpdateChannel changeBy gameChange dmChannel)
                        local.dmChannels
                , localUser = { localUser | user = user2, currentlyViewing = currentlyViewing2 }
            }

        GuildOrDmId_Guild id ->
            case LocalState.getGuildAndChannel id local of
                Just ( guild, channel ) ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser

                        ( currentlyViewing2, user2 ) =
                            if gameStartsMatch gameChange && changeBy == localUser.session.userId then
                                LocalState.ownMessageIsReadFrontend
                                    (GuildOrDmId (GuildOrDmId_Guild id))
                                    (MessageArray.length channel.messages |> Id.fromInt |> NoThreadWithMessage)
                                    ( localUser.currentlyViewing, localUser.user )

                            else
                                ( localUser.currentlyViewing, localUser.user )
                    in
                    { local
                        | guilds =
                            SeqDict.insert
                                id.guildId
                                { guild
                                    | channels =
                                        SeqDict.insert
                                            id.channelId
                                            (gameChangeUpdateChannel changeBy gameChange channel)
                                            guild.channels
                                }
                                local.guilds
                        , localUser = { localUser | user = user2, currentlyViewing = currentlyViewing2 }
                    }

                Nothing ->
                    local


{-| Only starting a match adds a message to the conversation. The moves that follow it are
folded into the card that is already there.
-}
gameStartsMatch : Game.LocalChange -> Bool
gameStartsMatch gameChange =
    case gameChange of
        Game.LocalChange_Go _ (Go.StartMatch _ _) ->
            True

        Game.LocalChange_WordSpellingGame _ (WordSpellingGame.StartMatch _ _) ->
            True

        _ ->
            False


gameChangeUpdateChannel :
    Id UserId
    -> Game.LocalChange
    ->
        { c
            | messages : MessageArray ChannelMessageId (Id UserId)
            , visibleMessages : VisibleMessages.VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict (Id UserId) (Thread.LastTypedAt ChannelMessageId)
            , games : SeqDict (Id ChannelMessageId) Game.MatchData
        }
    ->
        { c
            | messages : MessageArray ChannelMessageId (Id UserId)
            , visibleMessages : VisibleMessages.VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict (Id UserId) (Thread.LastTypedAt ChannelMessageId)
            , games : SeqDict (Id ChannelMessageId) Game.MatchData
        }
gameChangeUpdateChannel changeBy gameChange channel =
    case gameChange of
        Game.LocalChange_Go matchId goChange ->
            case goChange of
                Go.StartMatch createdAt setup ->
                    let
                        channel2 =
                            LocalState.createChannelMessageFrontend
                                (GameStarted
                                    { startedAt = createdAt
                                    , startedBy = changeBy
                                    , reactions = SeqDict.empty
                                    , gameType = GameType_Go
                                    , timestampDrawings = Drawing.emptyDrawing
                                    , cardDrawings = Drawing.emptyDrawing
                                    }
                                )
                                channel

                        newMatchId : Id ChannelMessageId
                        newMatchId =
                            DmChannel.latestFrontendMessageId channel2
                    in
                    { channel2
                        | games =
                            SeqDict.insert
                                newMatchId
                                (Game.initMatchData (Game.GameData_Go setup Array.empty) Nothing)
                                channel2.games
                    }

                Go.Action action ->
                    { channel
                        | games =
                            SeqDict.updateIfExists matchId (Game.addGoAction action) channel.games
                    }

        Game.CreatePublicLink matchId data ->
            case data of
                FilledInByBackend publicId ->
                    { channel
                        | games =
                            SeqDict.updateIfExists
                                matchId
                                (Game.addPublicLink publicId)
                                channel.games
                    }

                EmptyPlaceholder ->
                    channel

        Game.LoadMatch matchId data ->
            case data of
                FilledInByBackend loaded ->
                    { channel
                        | games =
                            SeqDict.updateIfExists
                                matchId
                                (\_ -> Game.initMatchData loaded.gameData loaded.publicLink)
                                channel.games
                    }

                -- Nothing has arrived yet, so the match stays as the placeholder it was.
                EmptyPlaceholder ->
                    channel

        Game.LocalChange_WordSpellingGame matchId wsChange ->
            case wsChange of
                WordSpellingGame.StartMatch createdAt setup ->
                    let
                        channel2 =
                            LocalState.createChannelMessageFrontend
                                (GameStarted
                                    { startedAt = createdAt
                                    , startedBy = changeBy
                                    , reactions = SeqDict.empty
                                    , gameType = GameType_WordSpellingGame
                                    , timestampDrawings = Drawing.emptyDrawing
                                    , cardDrawings = Drawing.emptyDrawing
                                    }
                                )
                                channel

                        newMatchId : Id ChannelMessageId
                        newMatchId =
                            DmChannel.latestFrontendMessageId channel2
                    in
                    { channel2
                        | games =
                            SeqDict.insert
                                newMatchId
                                (Game.initMatchData
                                    (Game.GameData_WordSpellingGame setup Array.empty (WordSpellingGame.initShared setup))
                                    Nothing
                                )
                                channel2.games
                    }

                WordSpellingGame.Action action ->
                    { channel
                        | games =
                            SeqDict.updateIfExists matchId (Game.addWordSpellingGameAction action) channel.games
                    }

        Game.LocalChange_SheepGame matchId sheepChange ->
            case sheepChange of
                SheepGame.StartMatch createdAt setup ->
                    let
                        channel2 =
                            LocalState.createChannelMessageFrontend
                                (GameStarted
                                    { startedAt = createdAt
                                    , startedBy = changeBy
                                    , reactions = SeqDict.empty
                                    , gameType = GameType_SheepGame
                                    , timestampDrawings = Drawing.emptyDrawing
                                    , cardDrawings = Drawing.emptyDrawing
                                    }
                                )
                                channel

                        newMatchId : Id ChannelMessageId
                        newMatchId =
                            DmChannel.latestFrontendMessageId channel2
                    in
                    { channel2
                        | games =
                            SeqDict.insert
                                newMatchId
                                (Game.initMatchData
                                    (Game.GameData_SheepGame setup Array.empty SheepGame.initShared)
                                    Nothing
                                )
                                channel2.games
                    }

                SheepGame.Action action ->
                    { channel
                        | games =
                            SeqDict.updateIfExists matchId (Game.addSheepGameAction action) channel.games
                    }


otherUserLeaveCall : Time.Posix -> Call.ConnectionId -> LocalState -> LocalState
otherUserLeaveCall time { roomId, otherClientId } local =
    let
        calls =
            local.calls
    in
    case SeqDict.get roomId calls.voiceChats of
        Just dmVoiceChat ->
            let
                voiceChats : SeqDict CallId (NonemptyDict.NonemptyDict ( Id UserId, Lamdera.ClientId ) Call.RemoteCallData)
                voiceChats =
                    SeqDict.update
                        roomId
                        (\_ -> NonemptyDict.remove otherClientId dmVoiceChat |> NonemptyDict.fromSeqDict)
                        calls.voiceChats
            in
            case roomId of
                DmRoomId { otherUserId } ->
                    { local
                        | calls = { calls | voiceChats = voiceChats }
                        , dmChannels =
                            case ( calls.currentRoom == Just roomId, SeqDict.member roomId voiceChats ) of
                                ( False, False ) ->
                                    SeqDict.updateIfExists
                                        otherUserId
                                        (LocalState.markCallMessageAsEndedFrontend time)
                                        local.dmChannels

                                _ ->
                                    local.dmChannels
                    }

                GuildRoomId { guildId, channelId } ->
                    { local
                        | calls = { calls | voiceChats = voiceChats }
                        , guilds =
                            case ( calls.currentRoom == Just roomId, SeqDict.member roomId voiceChats ) of
                                ( False, False ) ->
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel
                                            (LocalState.markCallMessageAsEndedFrontend time)
                                            channelId
                                        )
                                        local.guilds

                                _ ->
                                    local.guilds
                    }

        Nothing ->
            local


leaveCall : Time.Posix -> LocalState -> LocalState
leaveCall time local =
    let
        calls =
            local.calls
    in
    case calls.currentRoom of
        Just roomId ->
            case roomId of
                DmRoomId { otherUserId } ->
                    { local
                        | calls = { calls | currentRoom = Nothing }
                        , dmChannels =
                            if SeqDict.member roomId calls.voiceChats then
                                local.dmChannels

                            else
                                SeqDict.updateIfExists
                                    otherUserId
                                    (LocalState.markCallMessageAsEndedFrontend time)
                                    local.dmChannels
                    }

                GuildRoomId { guildId, channelId } ->
                    { local
                        | calls = { calls | currentRoom = Nothing }
                        , guilds =
                            if SeqDict.member roomId calls.voiceChats then
                                local.guilds

                            else
                                SeqDict.updateIfExists
                                    guildId
                                    (LocalState.updateChannel
                                        (LocalState.markCallMessageAsEndedFrontend time)
                                        channelId
                                    )
                                    local.guilds
                    }

        Nothing ->
            local


guildSendMessage :
    Id GuildId
    -> FrontendGuild
    -> Id ChannelId
    -> FrontendChannel
    -> ThreadRouteWithMaybeMessage
    -> Time.Posix
    -> Id UserId
    -> Nonempty (RichText (Id UserId))
    -> SeqDict (Id FileId) FileData
    -> LocalState
    -> SeqDict (Id GuildId) FrontendGuild
guildSendMessage guildId guild channelId channel threadRouteWithRepliedTo createdAt userId text attachedFiles local =
    SeqDict.insert
        guildId
        { guild
            | channels =
                SeqDict.insert
                    channelId
                    (case threadRouteWithRepliedTo of
                        ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                            LocalState.createThreadMessageFrontend
                                threadId
                                (Message.userTextMessageFrontend
                                    createdAt
                                    userId
                                    text
                                    maybeReplyTo
                                    attachedFiles
                                )
                                channel

                        NoThreadWithMaybeMessage maybeReplyTo ->
                            LocalState.createChannelMessageFrontend
                                (Message.userTextMessageFrontend
                                    createdAt
                                    userId
                                    text
                                    maybeReplyTo
                                    attachedFiles
                                )
                                channel
                    )
                    guild.channels
        }
        local.guilds


discordGuildSendMessage :
    Discord.Id Discord.GuildId
    -> DiscordFrontendGuild
    -> Discord.Id Discord.ChannelId
    -> DiscordFrontendChannel
    -> ThreadRouteWithMaybeMessage
    -> Time.Posix
    -> Discord.Id Discord.UserId
    -> Nonempty (RichText (Discord.Id Discord.UserId))
    -> SeqDict (Id FileId) FileData
    -> LocalState
    -> SeqDict (Discord.Id Discord.GuildId) DiscordFrontendGuild
discordGuildSendMessage guildId guild channelId channel threadRouteWithRepliedTo createdAt discordUserId text attachedFiles local =
    SeqDict.insert
        guildId
        { guild
            | channels =
                SeqDict.insert
                    channelId
                    (case threadRouteWithRepliedTo of
                        ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                            LocalState.createThreadMessageFrontend
                                threadId
                                (Message.userTextMessageFrontend
                                    createdAt
                                    discordUserId
                                    text
                                    maybeReplyTo
                                    attachedFiles
                                )
                                channel

                        NoThreadWithMaybeMessage maybeReplyTo ->
                            LocalState.createChannelMessageFrontend
                                (Message.userTextMessageFrontend
                                    createdAt
                                    discordUserId
                                    text
                                    maybeReplyTo
                                    attachedFiles
                                )
                                channel
                    )
                    guild.channels
        }
        local.discordGuilds


initAdminData : InitAdminData -> AdminData
initAdminData adminData =
    { users = adminData.users
    , emailNotificationsEnabled = adminData.emailNotificationsEnabled
    , twoFactorAuthentication = adminData.twoFactorAuthentication
    , privateVapidKey = adminData.privateVapidKey
    , slackClientSecret = adminData.slackClientSecret
    , openRouterKey = adminData.openRouterKey
    , postmarkKey = adminData.postmarkApiKey
    , dmChannels = adminData.dmChannels
    , discordDmChannels = adminData.discordDmChannels
    , discordUsers = adminData.discordUsers
    , discordGuilds = adminData.discordGuilds
    , guilds = adminData.guilds
    , deletedGuilds = adminData.deletedGuilds
    , loadingDiscordChannels = adminData.loadingDiscordChannels
    , signupsEnabled = adminData.signupsEnabled
    , discordLinkingEnabled = adminData.discordLinkingEnabled
    , logs = adminData.logs
    , connections = adminData.connections
    , filesCount = adminData.filesCount
    , toBackendLogs = adminData.toBackendLogs
    , vulnerabilityChecks = adminData.vulnerabilityChecks
    , serverSecretRefreshedAt = LocalState.NotBeingRegenerated adminData.serverSecretRegeneratedAt
    , lastBackup = adminData.lastBackup
    , websocketCloseEvents = adminData.websocketCloseEvents
    , sessions = adminData.sessions
    , wordSpellingGameEnglish = adminData.wordSpellingGameEnglish
    , wordSpellingGameSwedish = adminData.wordSpellingGameSwedish
    }


{-| Everything a newly linked Discord account brings with it starts out read. The
messages were written before the user could see them here, so treating them as unread
would bury the app in notifications the moment an account is linked.
-}
markDiscordDataAsViewed : Discord.Id Discord.UserId -> LocalState -> LocalState
markDiscordDataAsViewed discordUserId local =
    let
        localUser : LocalUser
        localUser =
            local.localUser

        guildsViewed : FrontendCurrentUser
        guildsViewed =
            SeqDict.foldl
                (\guildId guild state ->
                    case MembersAndOwner.isMember discordUserId guild.membersAndOwner of
                        MembersAndOwner.IsNotMember ->
                            state

                        _ ->
                            LocalState.markAllDiscordChannelsAndThreadsAsViewedFrontend
                                discordUserId
                                guildId
                                guild
                                state
                )
                localUser.user
                local.discordGuilds
    in
    { local
        | localUser =
            { localUser
                | user =
                    SeqDict.foldl
                        (\channelId dmChannel state ->
                            if NonemptyDict.member discordUserId dmChannel.members then
                                LocalState.markDiscordDmAsViewedFrontend discordUserId channelId dmChannel state

                            else
                                state
                        )
                        guildsViewed
                        local.discordDmChannels
            }
    }


startReloadingDiscordUser : Time.Posix -> Discord.Id Discord.UserId -> LocalState -> LocalState
startReloadingDiscordUser time discordUserId local =
    let
        localUser : LocalUser
        localUser =
            local.localUser
    in
    { local
        | localUser =
            { localUser
                | discordUsers =
                    LinkedAndOtherDiscordUsers.updateLinkedUser
                        discordUserId
                        (\user -> { user | isLoadingData = DiscordUserLoadingData time })
                        localUser.discordUsers
            }
    }


{-| Add the user that wrote a message to the users we know about. We might not have heard
of them yet, for example when an account created after we connected joins a guild we're in
and writes a message before we're told about them joining.
-}
addMessageSender : Id UserId -> FrontendUser -> LocalUser -> SeqDict (Id UserId) FrontendUser
addMessageSender userId user localUser =
    if userId == localUser.session.userId then
        localUser.otherUsers

    else
        SeqDict.insert userId user localUser.otherUsers


memberTyping : Time.Posix -> Id UserId -> GuildOrDmId -> ThreadRoute -> LocalState -> LocalState
memberTyping time userId guildOrDmId threadRoute local =
    case guildOrDmId of
        GuildOrDmId_Guild { guildId, channelId } ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel (LocalState.memberIsTyping userId time threadRoute) channelId)
                        local.guilds
            }

        GuildOrDmId_Dm { otherUserId } ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (LocalState.memberIsTyping userId time threadRoute)
                        local.dmChannels
            }


discordGuildMemberTyping :
    Time.Posix
    -> Discord.Id Discord.UserId
    -> Discord.Id Discord.GuildId
    -> Discord.Id Discord.ChannelId
    -> ThreadRoute
    -> LocalState
    -> LocalState
discordGuildMemberTyping time userId guildId channelId threadRoute local =
    { local
        | discordGuilds =
            SeqDict.updateIfExists
                guildId
                (LocalState.updateChannel (LocalState.memberIsTyping userId time threadRoute) channelId)
                local.discordGuilds
    }


discordDmMemberTyping :
    Time.Posix
    -> Discord.Id Discord.UserId
    -> Discord.Id Discord.PrivateChannelId
    -> LocalState
    -> LocalState
discordDmMemberTyping time userId channelId local =
    { local
        | discordDmChannels =
            SeqDict.updateIfExists channelId (LocalState.memberIsTypingHelper userId time) local.discordDmChannels
    }


addReactionEmoji : Id UserId -> AnyGuildOrDmId -> ThreadRouteWithMessage -> EmojiOrCustomEmoji -> LocalState -> LocalState
addReactionEmoji userId guildOrDmId threadRoute emoji local =
    let
        localUser : LocalUser
        localUser =
            local.localUser

        localUser2 : LocalUser
        localUser2 =
            if userId == localUser.session.userId then
                { localUser | user = User.addRecentlyUsedEmoji emoji localUser.user }

            else
                localUser
    in
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild { guildId, channelId }) ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel
                            (LocalState.addReactionEmojiFrontend emoji userId threadRoute)
                            channelId
                        )
                        local.guilds
                , localUser = localUser2
            }

        GuildOrDmId (GuildOrDmId_Dm { otherUserId }) ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (LocalState.addReactionEmojiFrontend emoji userId threadRoute)
                        local.dmChannels
                , localUser = localUser2
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild { currentUserId, guildId, channelId }) ->
            { local
                | discordGuilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel
                            (LocalState.addReactionEmojiFrontend emoji currentUserId threadRoute)
                            channelId
                        )
                        local.discordGuilds
                , localUser = localUser2
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId, channelId }) ->
            case threadRoute of
                ViewThreadWithMessage _ _ ->
                    local

                NoThreadWithMessage messageId ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                channelId
                                (LocalState.addReactionEmojiFrontendHelper emoji currentUserId messageId)
                                local.discordDmChannels
                        , localUser = localUser2
                    }


removeReactionEmoji :
    Id UserId
    -> AnyGuildOrDmId
    -> ThreadRouteWithMessage
    -> EmojiOrCustomEmoji
    -> LocalState
    -> LocalState
removeReactionEmoji userId guildOrDmId threadRoute emoji local =
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild { guildId, channelId }) ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel
                            (LocalState.removeReactionEmojiFrontend emoji userId threadRoute)
                            channelId
                        )
                        local.guilds
            }

        GuildOrDmId (GuildOrDmId_Dm { otherUserId }) ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (LocalState.removeReactionEmojiFrontend emoji userId threadRoute)
                        local.dmChannels
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild { currentUserId, guildId, channelId }) ->
            { local
                | discordGuilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel
                            (LocalState.removeReactionEmojiFrontend emoji currentUserId threadRoute)
                            channelId
                        )
                        local.discordGuilds
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId, channelId }) ->
            case threadRoute of
                ViewThreadWithMessage _ _ ->
                    local

                NoThreadWithMessage messageId ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                channelId
                                (LocalState.removeReactionEmojiFrontendHelper emoji currentUserId messageId)
                                local.discordDmChannels
                    }


memberEditTyping : Time.Posix -> Id UserId -> AnyGuildOrDmId -> ThreadRouteWithMessage -> LocalState -> LocalState
memberEditTyping time userId guildOrDmId threadRoute local =
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild { guildId, channelId }) ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (\guild ->
                            LocalState.memberIsEditTypingFrontend userId time channelId threadRoute guild
                                |> Result.withDefault guild
                        )
                        local.guilds
            }

        GuildOrDmId (GuildOrDmId_Dm { otherUserId }) ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (\dmChannel ->
                            LocalState.memberIsEditTypingFrontendHelper time userId threadRoute dmChannel
                                |> Result.withDefault dmChannel
                        )
                        local.dmChannels
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild { currentUserId, guildId, channelId }) ->
            { local
                | discordGuilds =
                    SeqDict.updateIfExists
                        guildId
                        (\guild ->
                            LocalState.memberIsEditTypingFrontend currentUserId time channelId threadRoute guild
                                |> Result.withDefault guild
                        )
                        local.discordGuilds
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId, channelId }) ->
            case threadRoute of
                ViewThreadWithMessage _ _ ->
                    local

                NoThreadWithMessage messageId ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                channelId
                                (\dmChannel ->
                                    LocalState.memberIsEditTypingFrontendHelperNoThread time currentUserId messageId dmChannel
                                        |> Result.withDefault dmChannel
                                )
                                local.discordDmChannels
                    }


editMessage :
    Time.Posix
    -> Id UserId
    -> GuildOrDmId
    -> NonemptyString
    -> SeqDict (Id FileId) FileData
    -> ThreadRouteWithMessage
    -> LocalState
    -> LocalState
editMessage time userId guildOrDmId newContent attachedFiles threadRoute local =
    case guildOrDmId of
        GuildOrDmId_Guild { guildId, channelId } ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (\guild ->
                            LocalState.updateChannel
                                (\channel ->
                                    LocalState.editMessageFrontendHelper
                                        time
                                        userId
                                        (textToRichText
                                            newContent
                                            (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                                            local
                                        )
                                        (ChangeAttachments attachedFiles)
                                        threadRoute
                                        channel
                                        |> Result.withDefault channel
                                )
                                channelId
                                guild
                        )
                        local.guilds
            }

        GuildOrDmId_Dm { otherUserId } ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (\dmChannel ->
                            LocalState.editMessageFrontendHelper
                                time
                                userId
                                (textToRichText newContent [ local.localUser.session.userId, otherUserId ] local)
                                (ChangeAttachments attachedFiles)
                                threadRoute
                                dmChannel
                                |> Result.withDefault dmChannel
                        )
                        local.dmChannels
            }


deleteMessage : AnyGuildOrDmId -> ThreadRouteWithMessage -> LocalState -> LocalState
deleteMessage guildOrDmId threadRoute local =
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild { guildId, channelId }) ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.deleteMessageFrontend channelId threadRoute)
                        local.guilds
            }

        GuildOrDmId (GuildOrDmId_Dm { otherUserId }) ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (LocalState.deleteMessageFrontendHelper threadRoute)
                        local.dmChannels
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild { guildId, channelId }) ->
            { local
                | discordGuilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.deleteMessageFrontend channelId threadRoute)
                        local.discordGuilds
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
            case threadRoute of
                NoThreadWithMessage messageId ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                data.channelId
                                (LocalState.deleteMessageFrontendNoThread messageId)
                                local.discordDmChannels
                    }

                ViewThreadWithMessage _ _ ->
                    local


pingUserNameSoFar : HtmlId -> Range -> AnyGuildOrDmId -> ThreadRoute -> LoggedIn2 -> Maybe NameSoFar
pingUserNameSoFar htmlId selection guildOrDmId threadRoute loggedIn =
    let
        isValidStart : Int -> String -> Bool
        isValidStart index text =
            if index <= 0 then
                True

            else
                case String.slice (index - 1) index text of
                    " " ->
                        True

                    "\n" ->
                        True

                    "\u{000D}" ->
                        True

                    _ ->
                        False

        helper : Int -> String -> Maybe NameSoFar
        helper index text =
            if PersonName.maxLength < selection.start - index || index <= 0 then
                Nothing

            else
                case String.slice (index - 1) index text of
                    "@" ->
                        if isValidStart (index - 1) text then
                            { nameSoFar = String.slice index selection.start text
                            , index = index
                            }
                                |> NameSoFar
                                |> Just

                        else
                            Nothing

                    ":" ->
                        if isValidStart (index - 1) text then
                            { nameSoFar = String.slice index selection.start text
                            , index = index
                            }
                                |> EmojiSoFar
                                |> Just

                        else
                            Nothing

                    _ ->
                        helper (index - 1) text

        -- Unlike a mention or an emoji there's no symbol to look back for, so this reads the
        -- two words the caret sits at the end of. It's only asked about that one position,
        -- since the words it reads are the ones the dropdown replaces, and anywhere further
        -- back is text the caret has already left.
        timeOffsetSoFar : Int -> String -> Maybe NameSoFar
        timeOffsetSoFar caret text =
            let
                timeOffsetHelper : String -> String -> (Float -> TimestampData) -> Maybe NameSoFar
                timeOffsetHelper valueText unit offsetType =
                    case String.toFloat valueText of
                        Just value ->
                            offsetType value
                                |> TimestampSoFar
                                    { start = caret - String.length valueText - 1 - String.length unit
                                    , end = caret
                                    }
                                |> Just

                        Nothing ->
                            Nothing
            in
            case lastTwoWords caret text |> List.map String.toLower of
                [ value, "weeks" ] ->
                    timeOffsetHelper value "weeks" MessageInput.WeekOffset

                [ value, "week" ] ->
                    timeOffsetHelper value "week" MessageInput.WeekOffset

                [ value, "days" ] ->
                    timeOffsetHelper value "days" MessageInput.DayOffset

                [ value, "day" ] ->
                    timeOffsetHelper value "day" MessageInput.DayOffset

                [ value, "hours" ] ->
                    timeOffsetHelper value "hours" MessageInput.HourOffset

                [ value, "hour" ] ->
                    timeOffsetHelper value "hour" MessageInput.HourOffset

                [ value, "minutes" ] ->
                    timeOffsetHelper value "minutes" MessageInput.MinuteOffset

                [ value, "minute" ] ->
                    timeOffsetHelper value "minute" MessageInput.MinuteOffset

                _ ->
                    case lastWord caret text |> Maybe.map String.toLower of
                        Just valueText ->
                            case parseTimeOfDay valueText of
                                Just value2 ->
                                    case
                                        RichText.tryParseTimestamp
                                            -- Timezone doesn't matter here, we just want to know if it's a timestamp
                                            Time.utc
                                            (lastFiveWords caret text |> Maybe.withDefault "")
                                            0
                                    of
                                        Just _ ->
                                            Nothing

                                        Nothing ->
                                            TimestampSoFar
                                                { start = caret - String.length valueText, end = caret }
                                                (MessageInput.TimeOfDay value2)
                                                |> Just

                                Nothing ->
                                    Nothing

                        _ ->
                            Nothing

        nameSoFar : Int -> String -> Maybe NameSoFar
        nameSoFar caret text =
            case timeOffsetSoFar caret text of
                Just timeOffset ->
                    Just timeOffset

                Nothing ->
                    helper caret text
    in
    if selection.start == selection.end then
        if htmlId == Pages.Guild.channelTextInputId then
            case SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.drafts of
                Just draft ->
                    nameSoFar selection.start (String.Nonempty.toString draft)

                Nothing ->
                    Nothing

        else if htmlId == MessageMenu.editMessageTextInputId then
            case SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.editMessage of
                Just edit ->
                    nameSoFar selection.start edit.text

                Nothing ->
                    Nothing

        else
            Nothing

    else
        Nothing


parseTimeOfDay : String -> Maybe { hours : Int, minutes : Int }
parseTimeOfDay text =
    case String.split ":" text of
        [ hours, minutes ] ->
            parseTimeOfDayHelper hours minutes

        _ ->
            case String.split "." text of
                [ hours, minutes ] ->
                    parseTimeOfDayHelper hours minutes

                _ ->
                    Nothing


parseTimeOfDayHelper : String -> String -> Maybe { hours : Int, minutes : Int }
parseTimeOfDayHelper hours minutes =
    if String.length hours <= 2 && String.length minutes == 2 then
        case ( String.toInt hours, String.toInt minutes ) of
            ( Just hours2, Just minutes2 ) ->
                if hours2 < 24 && minutes2 < 60 then
                    Just { hours = hours2, minutes = minutes2 }

                else
                    Nothing

            _ ->
                Nothing

    else
        Nothing


lastFiveWords : Int -> String -> Maybe String
lastFiveWords index text =
    lastWordsHelper 5 index index text


lastWordsHelper : Int -> Int -> Int -> String -> Maybe String
lastWordsHelper count startIndex index text =
    if count <= 0 then
        String.slice (index + 1) startIndex text |> Just

    else
        case lastWord index text of
            Just word ->
                lastWordsHelper (count - 1) startIndex (index - String.length word - 1) text

            Nothing ->
                Nothing


{-| The word that ends at `index`, or nothing if the caret isn't sitting at the end of one.
-}
lastWord : Int -> String -> Maybe String
lastWord index text =
    let
        start : Int
        start =
            wordStart text index
    in
    if start < index then
        String.slice start index text |> Just

    else
        Nothing


{-| The two words that end at `index`, or nothing if there aren't two of them. They have to
be a single space apart and the second has to end exactly where the caret is, because the
dropdown replaces the text they cover and works out where that starts from how long they are.
-}
lastTwoWords : Int -> String -> List String
lastTwoWords index text =
    let
        secondStart : Int
        secondStart =
            wordStart text index

        firstStart : Int
        firstStart =
            wordStart text (secondStart - 1)
    in
    if
        (secondStart < index)
            && (String.slice (secondStart - 1) secondStart text == " ")
            && (firstStart < secondStart - 1)
    then
        [ String.slice firstStart (secondStart - 1) text, String.slice secondStart index text ]

    else
        []


{-| Where the run of characters ending at `end` starts, taking a word to run up to the
whitespace in front of it.
-}
wordStart : String -> Int -> Int
wordStart text end =
    if end <= 0 then
        0

    else
        case String.slice (end - 1) end text of
            " " ->
                end

            "\n" ->
                end

            "\u{000D}" ->
                end

            _ ->
                wordStart text (end - 1)


handleUndo : LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
handleUndo model =
    updateLoggedIn
        (\loggedIn ->
            case loggedIn.drawingMode of
                Drawing.NoSelectedAnchor ->
                    ( loggedIn, Command.none )

                Drawing.SelectedAnchor selected ->
                    drawingUndo selected loggedIn model
        )
        model


drawingUndo : Drawing.SelectedAnchorData -> LoggedIn2 -> LoadedFrontend -> ( LoggedIn2, Command FrontendOnly ToBackend msg )
drawingUndo selected loggedIn model =
    let
        ( canUndo, _ ) =
            ChannelHeader.drawingCanUndoOrRedo
                selected.guildOrDmId
                selected.anchorType
                (Local.model loggedIn.localState)
    in
    if canUndo then
        handleLocalChange
            model.time
            (Local_Drawing selected.guildOrDmId selected.anchorType Drawing.UndoStroke |> Just)
            loggedIn
            Command.none

    else
        ( loggedIn, Command.none )


handlePressedTextInput : LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
handlePressedTextInput model =
    updateLoggedIn
        (\loggedIn -> ( { loggedIn | drawingMode = Drawing.NoSelectedAnchor }, Command.none ))
        { model | virtualKeyboardOpen = True }


drawingRedo : Drawing.SelectedAnchorData -> LoggedIn2 -> LoadedFrontend -> ( LoggedIn2, Command FrontendOnly ToBackend msg )
drawingRedo selected loggedIn model =
    let
        ( _, canRedo ) =
            ChannelHeader.drawingCanUndoOrRedo
                selected.guildOrDmId
                selected.anchorType
                (Local.model loggedIn.localState)
    in
    if canRedo then
        handleLocalChange
            model.time
            (Local_Drawing selected.guildOrDmId selected.anchorType Drawing.RedoStroke |> Just)
            loggedIn
            Command.none

    else
        ( loggedIn, Command.none )


handleRedo : LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
handleRedo model =
    updateLoggedIn
        (\loggedIn ->
            case loggedIn.drawingMode of
                Drawing.NoSelectedAnchor ->
                    ( loggedIn, Command.none )

                Drawing.SelectedAnchor selected ->
                    drawingRedo selected loggedIn model
        )
        model


{-| The change that marks everything in a conversation as read, which is what leaving it or
pressing escape does. A message the user marked as unread would be undone by that right away,
so the conversation it happened in gets skipped once and then forgotten about.
-}
markConversationAsRead : AnyGuildOrDmId -> ThreadRoute -> LocalState -> Maybe LocalChange
markConversationAsRead guildOrDmId threadRoute local =
    case LocalState.guildOrDmIdToMessagesCount guildOrDmId threadRoute local of
        Just messages ->
            Local_SetLastViewed
                guildOrDmId
                (case threadRoute of
                    ViewThread threadMessageId ->
                        ViewThreadWithMessage threadMessageId (messages - 1 |> Id.fromInt)

                    NoThread ->
                        NoThreadWithMessage (messages - 1 |> Id.fromInt)
                )
                |> Just

        Nothing ->
            Nothing


handleEscapeKey : LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
handleEscapeKey model =
    case model.imageViewer of
        Just _ ->
            ( { model | imageViewer = Nothing }, Command.none )

        Nothing ->
            if Route.toChannelHeaderTab model.route == Just ChannelHeaderTab_Draw then
                -- Closing the draw tab also disables the drawing mode (handled in routeRequest)
                routePush model (Route.setChannelHeaderTab Nothing model.route)

            else
                updateLoggedIn (handleEscapeKeyHelper model) model


handleEscapeKeyHelper : LoadedFrontend -> LoggedIn2 -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg_ )
handleEscapeKeyHelper model loggedIn =
    let
        loggedIn2 =
            MessageMenu.close model loggedIn

        isPingUserDropdownOpen : Maybe ( LoggedIn2, Command FrontendOnly toMsg FrontendMsg_ )
        isPingUserDropdownOpen =
            case loggedIn2.textInputFocus of
                Just textInputFocus ->
                    if textInputFocus.htmlId == Emoji.searchInputId then
                        ( { loggedIn2
                            | emojiSelector = Emoji.setSearch "" loggedIn2.emojiSelector
                          }
                        , Dom.blur Emoji.searchInputId
                            |> Task.attempt
                                (\result ->
                                    let
                                        _ =
                                            Debug.log "result" result
                                    in
                                    RemoveFocus
                                )
                        )
                            |> Just

                    else
                        case textInputFocus.dropdown of
                            Just _ ->
                                ( { loggedIn2
                                    | textInputFocus = Just { textInputFocus | dropdown = Nothing }
                                    , previousTextInputFocus = loggedIn2.textInputFocus
                                    , showEmojiSelector = EmojiSelectorHidden
                                  }
                                , Command.none
                                )
                                    |> Just

                            Nothing ->
                                Nothing

                Nothing ->
                    Nothing
    in
    case isPingUserDropdownOpen of
        Just a ->
            a

        Nothing ->
            case loggedIn2.showEmojiSelector of
                Types.EmojiSelectorHidden ->
                    let
                        local =
                            Local.model loggedIn2.localState
                    in
                    case Route.toGuildOrDmId local.localUser.session.userId model.route of
                        Just ( guildOrDmId, threadRoute ) ->
                            let
                                localChange =
                                    markConversationAsRead guildOrDmId threadRoute local
                            in
                            handleLocalChange
                                model.time
                                localChange
                                (if
                                    SeqDict.member ( guildOrDmId, threadRoute ) loggedIn2.editMessage
                                        || SeqDict.member ( guildOrDmId, NoThread ) loggedIn2.editMessage
                                 then
                                    { loggedIn2
                                        | editMessage =
                                            SeqDict.remove ( guildOrDmId, threadRoute ) loggedIn2.editMessage
                                                |> SeqDict.remove ( guildOrDmId, NoThread )
                                    }

                                 else
                                    { loggedIn2
                                        | replyTo =
                                            SeqDict.remove ( guildOrDmId, threadRoute ) loggedIn2.replyTo
                                    }
                                )
                                (setFocus model Pages.Guild.channelTextInputId)

                        Nothing ->
                            ( loggedIn2, Command.none )

                _ ->
                    ( { loggedIn2 | showEmojiSelector = Types.EmojiSelectorHidden }, Command.none )


{-| How many of the newest messages to look through when the user presses the up
arrow in an empty message input in order to edit the last message they sent.
-}
editPreviousMessageLookback : number
editPreviousMessageLookback =
    5


handlePressedArrowUpInEmptyInput :
    LoadedFrontend
    -> AnyGuildOrDmId
    -> ThreadRoute
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
handlePressedArrowUpInEmptyInput model guildOrDmId threadRoute =
    updateLoggedIn
        (\loggedIn ->
            let
                local : LocalState
                local =
                    Local.model loggedIn.localState
            in
            case guildOrDmId of
                GuildOrDmId guildOrDmId2 ->
                    let
                        maybeMessages : Maybe (List ( Int, MessageNoReply (Id UserId) ))
                        maybeMessages =
                            LocalState.guildOrDmIdToLatestMessages
                                editPreviousMessageLookback
                                ( guildOrDmId2, threadRoute )
                                local
                    in
                    case maybeMessages of
                        Just messages ->
                            let
                                mostRecentMessage : Maybe ( Id ChannelMessageId, UserTextMessageDataNoReply (Id UserId) )
                                mostRecentMessage =
                                    List.reverse messages
                                        |> List.Extra.findMap
                                            (\( index, message ) ->
                                                case message of
                                                    UserTextMessage_NoReply data ->
                                                        if local.localUser.session.userId == data.createdBy then
                                                            Just ( Id.fromInt index, data )

                                                        else
                                                            Nothing

                                                    UserJoinedMessage_NoReply _ _ _ ->
                                                        Nothing

                                                    DeletedMessage_NoReply _ ->
                                                        Nothing

                                                    CallStarted_NoReply _ _ _ ->
                                                        Nothing

                                                    GoMatchStarted_NoReply _ _ ->
                                                        Nothing
                                            )
                            in
                            case mostRecentMessage of
                                Just ( index, message ) ->
                                    ( { loggedIn
                                        | editMessage =
                                            SeqDict.insert
                                                ( GuildOrDmId guildOrDmId2, threadRoute )
                                                { messageIndex = index
                                                , text =
                                                    RichText.toString local.localUser.timezone False (User.allUsers local.localUser) message.content
                                                , attachedFiles =
                                                    SeqDict.map (\_ a -> FileUploaded a) message.attachedFiles
                                                }
                                                loggedIn.editMessage
                                      }
                                    , setFocus model MessageMenu.editMessageTextInputId
                                    )

                                Nothing ->
                                    ( loggedIn, Command.none )

                        Nothing ->
                            ( loggedIn, Command.none )

                DiscordGuildOrDmId guildOrDmId2 ->
                    let
                        maybeMessages : Maybe (List ( Int, MessageNoReply (Discord.Id Discord.UserId) ))
                        maybeMessages =
                            LocalState.discordGuildOrDmIdToLatestMessages
                                editPreviousMessageLookback
                                guildOrDmId2
                                threadRoute
                                local
                    in
                    case maybeMessages of
                        Just messages ->
                            let
                                currentUserId : Discord.Id Discord.UserId
                                currentUserId =
                                    case guildOrDmId2 of
                                        DiscordGuildOrDmId_Guild id ->
                                            id.currentUserId

                                        DiscordGuildOrDmId_Dm data ->
                                            data.currentUserId

                                mostRecentMessage : Maybe ( Id ChannelMessageId, UserTextMessageDataNoReply (Discord.Id Discord.UserId) )
                                mostRecentMessage =
                                    List.reverse messages
                                        |> List.Extra.findMap
                                            (\( index, message ) ->
                                                case message of
                                                    UserTextMessage_NoReply data ->
                                                        if currentUserId == data.createdBy then
                                                            Just ( Id.fromInt index, data )

                                                        else
                                                            Nothing

                                                    UserJoinedMessage_NoReply _ _ _ ->
                                                        Nothing

                                                    DeletedMessage_NoReply _ ->
                                                        Nothing

                                                    CallStarted_NoReply _ _ _ ->
                                                        Nothing

                                                    GoMatchStarted_NoReply _ _ ->
                                                        Nothing
                                            )
                            in
                            case mostRecentMessage of
                                Just ( index, message ) ->
                                    ( { loggedIn
                                        | editMessage =
                                            SeqDict.insert
                                                ( DiscordGuildOrDmId guildOrDmId2, threadRoute )
                                                { messageIndex = index
                                                , text =
                                                    RichText.toString
                                                        local.localUser.timezone
                                                        False
                                                        (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                                                        message.content
                                                , attachedFiles =
                                                    SeqDict.map (\_ a -> FileUploaded a) message.attachedFiles
                                                }
                                                loggedIn.editMessage
                                      }
                                    , setFocus model MessageMenu.editMessageTextInputId
                                    )

                                Nothing ->
                                    ( loggedIn, Command.none )

                        Nothing ->
                            ( loggedIn, Command.none )
        )
        model


audio : AudioData -> FrontendModel_ -> Audio
audio _ model =
    case model of
        Loading _ ->
            Audio.silence

        Loaded loaded ->
            case loaded.loginStatus of
                LoggedIn loggedIn ->
                    let
                        local =
                            Local.model loggedIn.localState
                    in
                    case ( currentGame local loaded, loaded.popSound ) of
                        ( Just { guildOrDmId, matchId, match }, Ok popSound ) ->
                            SeqDict.get guildOrDmId loggedIn.games
                                |> Maybe.withDefault Game.initModel
                                |> Game.audio popSound local.localUser.session.userId matchId match

                        _ ->
                            Audio.silence

                NotLoggedIn _ ->
                    Audio.silence


addEncryptedDmMessage :
    Time.Posix
    -> Id UserId
    -> Id UserId
    -> EncryptedData (ContentAndEmbeds (Id UserId))
    -> ThreadRouteWithMaybeMessage
    -> SeqDict (Id FileId) FileData
    -> LocalState
    -> LocalState
addEncryptedDmMessage createdAt createdBy otherUserId contentAndEmbeds threadRouteWithRepliedTo attachedFiles local =
    let
        dmChannel : FrontendDmChannel
        dmChannel =
            SeqDict.get otherUserId local.dmChannels |> Maybe.withDefault DmChannel.frontendInit
    in
    { local
        | dmChannels =
            SeqDict.insert
                otherUserId
                (case threadRouteWithRepliedTo of
                    ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                        LocalState.createThreadMessageFrontend
                            threadId
                            (Message.encryptedUserTextMessageFrontend
                                createdAt
                                createdBy
                                contentAndEmbeds
                                maybeReplyTo
                                attachedFiles
                            )
                            dmChannel

                    NoThreadWithMaybeMessage maybeReplyTo ->
                        LocalState.createChannelMessageFrontend
                            (Message.encryptedUserTextMessageFrontend
                                createdAt
                                createdBy
                                contentAndEmbeds
                                maybeReplyTo
                                attachedFiles
                            )
                            dmChannel
                )
                local.dmChannels
    }


handleServerSendMessage :
    Id UserId
    -> GuildOrDmId
    -> Nonempty (RichText (Id UserId))
    -> ThreadRouteWithMaybeMessage
    -> LocalState
    -> LoggedIn2
    -> LoadedFrontend
    -> ( LoggedIn2, Command FrontendOnly toMsg FrontendMsg_ )
handleServerSendMessage senderId guildOrDmId content maybeRepliedTo local loggedIn2 model =
    let
        scrolledToBottom : Bool
        scrolledToBottom =
            -- The drawing tab holds the scroll position, otherwise the
            -- new message would throw off the stroke the user is drawing
            (Route.toChannelHeaderTab model.route /= Just ChannelHeaderTab_Draw)
                && (loggedIn2.channelScrollPosition == ScrolledToBottom)

        isViewingConversation : Bool
        isViewingConversation =
            Route.toGuildOrDmId local.localUser.session.userId model.route
                == Just
                    ( GuildOrDmId guildOrDmId
                    , Id.threadRouteWithoutMaybeMessage maybeRepliedTo
                    )

        helper channel =
            Command.batch
                [ playNotificationSound
                    senderId
                    guildOrDmId
                    maybeRepliedTo
                    channel
                    local
                    content
                    model
                , if scrolledToBottom then
                    if MyUi.isMobile model then
                        Scroll.toBottomOfChannelSmooth Pages.Guild.conversationContainerId SetScrollToBottom

                    else
                        Scroll.toBottomOfChannel Pages.Guild.conversationContainerId SetScrollToBottom

                  else
                    Command.none
                ]
    in
    ( if isViewingConversation && not scrolledToBottom then
        { loggedIn2
            | newMessagesWhileNotScrolledToBottom =
                loggedIn2.newMessagesWhileNotScrolledToBottom + 1
            , channelScrollPosition =
                case loggedIn2.channelScrollPosition of
                    ScrolledToBottom ->
                        ScrolledToMiddle

                    ScrolledToTop ->
                        loggedIn2.channelScrollPosition

                    ScrolledToMiddle ->
                        loggedIn2.channelScrollPosition
        }

      else
        loggedIn2
    , case guildOrDmId of
        GuildOrDmId_Guild { guildId, channelId } ->
            case LocalState.getGuildAndChannel { guildId = guildId, channelId = channelId } local of
                Just ( _, channel ) ->
                    helper channel

                Nothing ->
                    Command.none

        GuildOrDmId_Dm { otherUserId } ->
            case SeqDict.get otherUserId local.dmChannels of
                Just channel ->
                    helper channel

                Nothing ->
                    Command.none
    )


handleDecryptedMessage :
    Id Encryption.DecryptRequestId
    -> BytesHash
    -> Result () (ContentAndEmbeds (Id UserId))
    -> LoadedFrontend
    -> LoggedIn2
    -> ( LoggedIn2, Command FrontendOnly toMsg FrontendMsg_ )
handleDecryptedMessage requestId bytesHash result model loggedIn =
    case SeqDict.get requestId loggedIn.encryptionRequests.pendingDecryptedMessages of
        Just request ->
            let
                loggedIn2 : LoggedIn2
                loggedIn2 =
                    fileDecryptedMessages [ ( bytesHash, result ) ] loggedIn
            in
            handleServerSendMessage
                request.senderId
                (GuildOrDmId_Dm request.id)
                (case result of
                    Ok contentAndEmbeds ->
                        contentAndEmbeds.content

                    Err () ->
                        RichText.failedToDecryptMessage
                )
                request.threadRoute
                (Local.model loggedIn2.localState)
                loggedIn2
                model

        Nothing ->
            ( loggedIn, Command.none )


encryptOldMessages :
    List ( ThreadRouteWithMessage, EncryptedData (ContentAndEmbeds (Id UserId)) )
    -> FrontendDmChannel
    -> FrontendDmChannel
encryptOldMessages messages dmChannel =
    List.foldl
        (\( threadRoute, encryptedData ) channel ->
            case threadRoute of
                NoThreadWithMessage messageId ->
                    { channel
                        | messages =
                            MessageArray.updateIfExists
                                messageId
                                (Message.toEncrypted encryptedData)
                                channel.messages
                    }

                ViewThreadWithMessage threadId messageId ->
                    { channel
                        | threads =
                            SeqDict.updateIfExists
                                threadId
                                (\thread ->
                                    { thread
                                        | messages =
                                            MessageArray.updateIfExists
                                                messageId
                                                (Message.toEncrypted encryptedData)
                                                thread.messages
                                    }
                                )
                                channel.threads
                    }
        )
        dmChannel
        messages


fileDecryptedMessages :
    List ( BytesHash, Result () (ContentAndEmbeds (Id UserId)) )
    -> LoggedIn2
    -> LoggedIn2
fileDecryptedMessages decrypted loggedIn =
    { loggedIn
        | localState =
            Local.mapModel
                (\local ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | decryptedMessages =
                                    List.foldl
                                        (\( bytesHash, result ) dict -> SeqDict.insert bytesHash result dict)
                                        localUser.decryptedMessages
                                        decrypted
                            }
                    }
                )
                loggedIn.localState
    }


handleServerSendDmMessage :
    Viewing_DmId
    -> Id UserId
    -> FrontendUser
    -> SeqDict (Id StickerId) StickerData
    -> (Maybe (Id ChannelMessageId) -> Message ChannelMessageId (Id UserId))
    -> (Maybe (Id ThreadMessageId) -> Message ThreadMessageId (Id UserId))
    -> ThreadRouteWithMaybeMessage
    -> LocalState
    -> LocalState
handleServerSendDmMessage id createdBy createdByUser stickers messageForChannel messageForThread threadRouteWithRepliedTo local =
    let
        localUser : LocalUser
        localUser =
            local.localUser

        user : FrontendCurrentUser
        user =
            localUser.user

        dmChannel : FrontendDmChannel
        dmChannel =
            SeqDict.get id.otherUserId local.dmChannels |> Maybe.withDefault DmChannel.frontendInit

        dmChannel2 : FrontendDmChannel
        dmChannel2 =
            case threadRouteWithRepliedTo of
                ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                    LocalState.createThreadMessageFrontend threadId (messageForThread maybeReplyTo) dmChannel

                NoThreadWithMaybeMessage maybeReplyTo ->
                    LocalState.createChannelMessageFrontend (messageForChannel maybeReplyTo) dmChannel

        threadRouteNoReply : ThreadRoute
        threadRouteNoReply =
            case threadRouteWithRepliedTo of
                ViewThreadWithMaybeMessage threadId _ ->
                    ViewThread threadId

                NoThreadWithMaybeMessage _ ->
                    NoThread

        guildOrDmId =
            GuildOrDmId (GuildOrDmId_Dm id)

        ( currentlyViewing2, user2 ) =
            if createdBy == localUser.session.userId then
                LocalState.ownMessageIsReadFrontend
                    guildOrDmId
                    (latestMessageThreadRoute threadRouteWithRepliedTo dmChannel2)
                    ( localUser.currentlyViewing, user )

            else if isViewing guildOrDmId threadRouteNoReply local then
                LocalState.incrementLastViewedMessageFrontend
                    guildOrDmId
                    (latestMessageThreadRoute threadRouteWithRepliedTo dmChannel2)
                    ( localUser.currentlyViewing, user )

            else
                ( localUser.currentlyViewing, user )
    in
    { local
        | dmChannels = SeqDict.insert id.otherUserId dmChannel2 local.dmChannels
        , localUser =
            { localUser
                | user = user2
                , currentlyViewing = currentlyViewing2
                , otherUsers = addMessageSender createdBy createdByUser localUser
                , stickers = SeqDict.union stickers localUser.stickers
            }
    }
