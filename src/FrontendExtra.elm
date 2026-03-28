module FrontendExtra exposing (changeUpdate, externalLinkWarning, handleLocalChange, initAdminData, isPressMsg, layout, logout, pingUserNameSoFar, playNotificationSound, playNotificationSoundForDiscordMessage, routePush, routeReplace, routeRequest, setFocus, updateLoggedIn)

import AiChat
import Array exposing (Array)
import ChannelDescription
import ChannelName
import Discord
import DiscordUserData exposing (DiscordUserLoadingData(..))
import DmChannel exposing (DiscordFrontendDmChannel, FrontendDmChannel)
import Duration
import Editable
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Navigation as BrowserNavigation
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera as Lamdera
import Effect.Process as Process
import Effect.Task as Task
import Effect.Time as Time
import Emoji exposing (Emoji)
import FileStatus exposing (FileData, FileId)
import Html exposing (Html)
import Html.Events
import Icons
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import ImageEditor
import Json.Decode
import List.Nonempty exposing (Nonempty)
import Local
import LocalState exposing (AdminData, AdminStatus(..), DiscordFrontendChannel, DiscordFrontendGuild, FrontendChannel, FrontendGuild, LocalState, LocalUser)
import LoginForm
import MembersAndOwner
import Message exposing (ChangeAttachments(..), MessageState)
import MessageInput exposing (NameSoFar(..))
import MessageMenu
import MessageView
import MyUi exposing (Range)
import Pages.Admin exposing (InitAdminData)
import Pages.Guild
import Pagination
import PersonName
import Ports
import RichText exposing (Domain, RichText)
import Route exposing (ChannelRoute(..), DiscordChannelRoute(..), Route(..), ShowMembersTab(..), ThreadRouteWithFriends(..))
import Scroll
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import String.Nonempty
import TextEditor
import Thread exposing (FrontendGenericThread)
import Touch
import TwoFactorAuthentication
import Types exposing (ChannelSidebarMode(..), FrontendMsg(..), LoadedFrontend, LocalChange(..), LocalMsg(..), LoggedIn2, LoginStatus(..), MessageHover(..), ServerChange(..), ToBackend(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Input
import Ui.Prose
import Url exposing (Url)
import User exposing (FrontendCurrentUser, FrontendUser, LastDmViewed(..), NotificationLevel(..))
import UserSession exposing (NotificationMode(..), PushSubscription(..), SetViewing(..), ToBeFilledInByBackend(..), UserSession)
import VisibleMessages


pendingChangesText : LocalChange -> String
pendingChangesText localChange =
    case localChange of
        Local_Invalid ->
            -- We should never have a invalid change in the local msg queue
            "InvalidChange"

        Local_Admin adminChange ->
            Pages.Admin.pendingChangesText adminChange

        Local_SendMessage _ _ _ _ _ ->
            "Sent a message"

        Local_Discord_SendMessage _ _ _ _ _ ->
            "Sent a message"

        Local_NewChannel _ _ _ ->
            "Created new channel"

        Local_EditChannel _ _ _ ->
            "Edited channel"

        Local_DeleteChannel _ _ ->
            "Deleted channel"

        Local_NewInviteLink _ _ _ ->
            "Created invite link"

        Local_NewGuild _ _ _ ->
            "Created new guild"

        Local_MemberTyping _ _ ->
            "Is typing notification"

        Local_AddReactionEmoji _ _ _ ->
            "Added reaction emoji"

        Local_RemoveReactionEmoji _ _ _ ->
            "Removed reaction emoji"

        Local_SendEditMessage _ _ _ _ _ ->
            "Edit message"

        Local_Discord_SendEditGuildMessage _ _ _ _ _ _ ->
            "Edit message"

        Local_Discord_SendEditDmMessage _ _ _ _ ->
            "Edit message"

        Local_MemberEditTyping _ _ _ ->
            "Editing message"

        Local_SetLastViewed _ _ ->
            "Viewed channel"

        Local_DeleteMessage _ _ ->
            "Delete message"

        Local_CurrentlyViewing _ ->
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

        Local_SetDiscordGuildNotificationLevel _ notificationLevel ->
            case notificationLevel of
                NotifyOnEveryMessage ->
                    "Enabled notifications for all messages"

                NotifyOnMention ->
                    "Disabled notifications for all messages"

        Local_SetNotificationMode _ ->
            "Set notification mode"

        Local_RegisterPushSubscription _ ->
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

        Local_SetEmojiCategory _ ->
            "Selected emoji category"

        Local_SetEmojiSkinTone _ ->
            "Selected emoji skin tone"


layout : LoadedFrontend -> List (Ui.Attribute FrontendMsg) -> Element FrontendMsg -> Html FrontendMsg
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
                        Route.toGuildOrDmId model.route
                in
                [ Local.networkError
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
                                            MessageInput.dropdownView
                                                isMobile
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
                                            MessageInput.dropdownView
                                                isMobile
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
            ++ Ui.Font.family [ Ui.Font.sansSerif ]
            :: Ui.id "elm-ui-root-id"
            :: Ui.height Ui.fill
            :: Ui.behindContent (Ui.html MyUi.css)
            --:: Ui.behindContent
            --    (Ui.html
            --        (Html.node
            --            "style"
            --            []
            --            [ Html.text
            --                ("body { height: "
            --                    ++ String.fromInt (Coord.yRaw model.windowSize)
            --                    ++ "px !important; }"
            --                )
            --            ]
            --        )
            --    )
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
            :: attributes
            ++ (if MyUi.isMobile model then
                    [ Html.Events.on "touchstart" (Touch.decodeTouchEvent (TouchStart Nothing)) |> Ui.htmlAttribute
                    , Html.Events.on "touchmove" (Touch.decodeTouchEvent TouchMoved) |> Ui.htmlAttribute
                    , Html.Events.on
                        "touchend"
                        (Json.Decode.field "timeStamp" Json.Decode.float
                            |> Json.Decode.map (\time -> round time |> Time.millisToPosix |> TouchEnd)
                        )
                        |> Ui.htmlAttribute
                    , Html.Events.on
                        "touchcancel"
                        (Json.Decode.field "timeStamp" Json.Decode.float
                            |> Json.Decode.map (\time -> round time |> Time.millisToPosix |> TouchCancel)
                        )
                        |> Ui.htmlAttribute
                    , Ui.clip
                    , MyUi.htmlStyle "user-select" "none"
                    , MyUi.htmlStyle "-webkit-user-select" "none"
                    ]

                else
                    []
               )
        )
        child


externalLinkWarning : SeqSet Domain -> Bool -> Url -> Element FrontendMsg
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
                [ Ui.background (Ui.rgba 0 0 0 0.5)
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
                [ MyUi.secondaryButton
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
                    , MyUi.focusEffect
                    , Ui.Font.weight 500
                    , Ui.Font.color MyUi.white
                    , MyUi.htmlStyle "text-decoration" "none"
                    , Ui.alignRight
                    ]
                    (Ui.text "Continue to site")
                ]
            ]
        )


logout : LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
logout model =
    case model.loginStatus of
        LoggedIn _ ->
            let
                model2 : LoadedFrontend
                model2 =
                    { model
                        | loginStatus =
                            NotLoggedIn { loginForm = Nothing, useInviteAfterLoggedIn = Nothing }
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
    let
        a =
            ( guildOrDmId, threadRoute ) |> Just
    in
    (local.localUser.session.currentlyViewing == a)
        || List.any
            (\otherSession -> otherSession.currentlyViewing == a)
            (SeqDict.values local.otherSessions)


playNotificationSound :
    Id UserId
    -> GuildOrDmId
    -> ThreadRouteWithMaybeMessage
    -> FrontendChannel
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
                        GuildOrDmId_Guild guildId _ ->
                            SeqSet.member guildId local.localUser.user.notifyOnAllMessages

                        GuildOrDmId_Dm _ ->
                            False

                isMentionedOrRepliedTo =
                    LocalState.usersMentionedOrRepliedToFrontend threadRouteWithRepliedTo content channel
                        |> SeqSet.member local.localUser.session.userId
            in
            if not model.pageHasFocus && (alwaysNotify || isMentionedOrRepliedTo) then
                Command.batch
                    [ Ports.playSound "pop"
                    , Ports.setFavicon "/favicon-red.ico"
                    , case model.notificationPermission of
                        Ports.Granted ->
                            let
                                users : SeqDict (Id UserId) FrontendUser
                                users =
                                    LocalState.allUsers local.localUser
                            in
                            Ports.showNotification (User.toString senderId users) (RichText.toString users content)

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
            | messages : Array (MessageState ChannelMessageId (Discord.Id Discord.UserId))
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
                        DiscordGuildOrDmId_Guild _ guildId _ ->
                            SeqSet.member guildId local.localUser.user.discordNotifyOnAllMessages

                        DiscordGuildOrDmId_Dm _ ->
                            False

                isMentionedOrRepliedTo : Bool
                isMentionedOrRepliedTo =
                    LocalState.usersMentionedOrRepliedToFrontend threadRouteWithRepliedTo content channel
                        |> SeqSet.intersect (SeqDict.keys local.localUser.linkedDiscordUsers |> SeqSet.fromList)
                        |> SeqSet.isEmpty
                        |> not

                allUsers =
                    LocalState.allDiscordUsers local.localUser
            in
            if not model.pageHasFocus && (alwaysNotify || isMentionedOrRepliedTo) then
                Command.batch
                    [ Ports.playSound "pop"
                    , Ports.setFavicon "/favicon-red.ico"
                    , case model.notificationPermission of
                        Ports.Granted ->
                            Ports.showNotification
                                (User.toString senderId allUsers)
                                (RichText.toString allUsers content)

                        _ ->
                            Command.none
                    ]

            else
                Command.none

        PushNotifications ->
            Command.none


routePush : LoadedFrontend -> Route -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
routePush model route =
    if MyUi.isMobile model then
        routeRequest (Just model.route) route model

    else
        ( model, BrowserNavigation.pushUrl model.navigationKey (Route.encode route) )


routeReplace : LoadedFrontend -> Route -> Command FrontendOnly ToBackend FrontendMsg
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


routeViewingLocalChange : LocalState -> Route -> Maybe LocalChange
routeViewingLocalChange local route =
    let
        localChange : SetViewing
        localChange =
            LocalState.routeToViewing route local
    in
    if UserSession.setViewingToCurrentlyViewing localChange == local.localUser.session.currentlyViewing then
        Nothing

    else
        Just (Local_CurrentlyViewing localChange)


routeRequest : Maybe Route -> Route -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
routeRequest previousRoute newRoute model =
    let
        ( model2, viewCmd ) =
            updateLoggedIn
                (\loggedIn ->
                    handleLocalChange
                        model.time
                        (routeViewingLocalChange (Local.model loggedIn.localState) newRoute)
                        loggedIn
                        Command.none
                )
                { model | route = newRoute }
    in
    case newRoute of
        HomePageRoute ->
            ( { model2
                | loginStatus =
                    case model2.loginStatus of
                        NotLoggedIn notLoggedIn ->
                            NotLoggedIn { notLoggedIn | loginForm = Nothing }

                        LoggedIn _ ->
                            model2.loginStatus
              }
            , viewCmd
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
                    , Command.batch
                        [ viewCmd
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
                        ]
                    )
                )
                model2

        GuildRoute guildId channelRoute ->
            let
                model3 : LoadedFrontend
                model3 =
                    { model2
                        | loginStatus =
                            case model2.loginStatus of
                                LoggedIn loggedIn ->
                                    LoggedIn { loggedIn | revealedSpoilers = Nothing }

                                NotLoggedIn _ ->
                                    model2.loginStatus
                    }

                ( sameGuild, _ ) =
                    case previousRoute of
                        Just (GuildRoute previousGuildId previousChannelRoute) ->
                            ( guildId == previousGuildId
                            , guildId == previousGuildId && channelRoute == previousChannelRoute
                            )

                        _ ->
                            ( False, False )
            in
            case channelRoute of
                ChannelRoute _ threadRoute ->
                    let
                        showMembers : ShowMembersTab
                        showMembers =
                            case threadRoute of
                                ViewThreadWithFriends _ _ showMembers2 ->
                                    showMembers2

                                NoThreadWithFriends _ showMembers2 ->
                                    showMembers2

                        --previousShowMembers : ShowMembersTab
                        --previousShowMembers =
                        --    case threadRoute of
                        --        ViewThreadWithFriends threadId _ showMembers2 ->
                        --            showMembers2
                        --
                        --        NoThreadWithFriends maybeId showMembers2 ->
                        --            showMembers2
                    in
                    updateLoggedIn
                        (\loggedIn ->
                            ( case showMembers of
                                ShowMembersTab ->
                                    startOpeningChannelSidebar { loggedIn | sidebarMode = ChannelSidebarClosed }

                                HideMembersTab ->
                                    if sameGuild || previousRoute == Nothing then
                                        startOpeningChannelSidebar loggedIn

                                    else
                                        loggedIn
                            , Command.batch [ viewCmd, openChannelCmds threadRoute model3 ]
                            )
                        )
                        model3

                NewChannelRoute ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( if sameGuild || previousRoute == Nothing then
                                startOpeningChannelSidebar loggedIn

                              else
                                loggedIn
                            , viewCmd
                            )
                        )
                        model3

                EditChannelRoute _ ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( if sameGuild || previousRoute == Nothing then
                                startOpeningChannelSidebar loggedIn

                              else
                                loggedIn
                            , viewCmd
                            )
                        )
                        model3

                GuildSettingsRoute ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( if sameGuild || previousRoute == Nothing then
                                startOpeningChannelSidebar loggedIn

                              else
                                loggedIn
                            , viewCmd
                            )
                        )
                        model3

                JoinRoute inviteLinkId ->
                    case model3.loginStatus of
                        NotLoggedIn notLoggedIn ->
                            ( { model3
                                | loginStatus =
                                    { notLoggedIn | useInviteAfterLoggedIn = Just inviteLinkId }
                                        |> NotLoggedIn
                              }
                            , viewCmd
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
                                                    (NoThreadWithFriends Nothing HideMembersTab)
                                                )
                                            )

                                    Nothing ->
                                        viewCmd
                                ]
                            )

        DiscordGuildRoute { currentDiscordUserId, guildId, channelRoute } ->
            let
                model3 : LoadedFrontend
                model3 =
                    { model2
                        | loginStatus =
                            case model2.loginStatus of
                                LoggedIn loggedIn ->
                                    LoggedIn { loggedIn | revealedSpoilers = Nothing }

                                NotLoggedIn _ ->
                                    model2.loginStatus
                    }

                ( sameGuild, _ ) =
                    case previousRoute of
                        Just (DiscordGuildRoute a) ->
                            ( currentDiscordUserId == a.currentDiscordUserId && guildId == a.guildId
                            , currentDiscordUserId == a.currentDiscordUserId && guildId == a.guildId && channelRoute == a.channelRoute
                            )

                        _ ->
                            ( False, False )
            in
            case channelRoute of
                DiscordChannel_ChannelRoute _ threadRoute ->
                    let
                        showMembers : ShowMembersTab
                        showMembers =
                            case threadRoute of
                                ViewThreadWithFriends _ _ showMembers2 ->
                                    showMembers2

                                NoThreadWithFriends _ showMembers2 ->
                                    showMembers2

                        --previousShowMembers : ShowMembersTab
                        --previousShowMembers =
                        --    case threadRoute of
                        --        ViewThreadWithFriends threadId _ showMembers2 ->
                        --            showMembers2
                        --
                        --        NoThreadWithFriends maybeId showMembers2 ->
                        --            showMembers2
                    in
                    updateLoggedIn
                        (\loggedIn ->
                            ( case showMembers of
                                ShowMembersTab ->
                                    startOpeningChannelSidebar { loggedIn | sidebarMode = ChannelSidebarClosed }

                                HideMembersTab ->
                                    if sameGuild || previousRoute == Nothing then
                                        startOpeningChannelSidebar loggedIn

                                    else
                                        loggedIn
                            , Command.batch [ viewCmd, openChannelCmds threadRoute model3 ]
                            )
                        )
                        model3

                DiscordChannel_NewChannelRoute ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( if sameGuild || previousRoute == Nothing then
                                startOpeningChannelSidebar loggedIn

                              else
                                loggedIn
                            , viewCmd
                            )
                        )
                        model3

                DiscordChannel_EditChannelRoute _ ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( if sameGuild || previousRoute == Nothing then
                                startOpeningChannelSidebar loggedIn

                              else
                                loggedIn
                            , viewCmd
                            )
                        )
                        model3

                DiscordChannel_GuildSettingsRoute ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( if sameGuild || previousRoute == Nothing then
                                startOpeningChannelSidebar loggedIn

                              else
                                loggedIn
                            , viewCmd
                            )
                        )
                        model3

        AiChatRoute ->
            ( model2, Command.batch [ viewCmd, Command.map AiChatToBackend AiChatMsg AiChat.getModels ] )

        DmRoute _ threadRoute ->
            let
                model3 : LoadedFrontend
                model3 =
                    { model2
                        | loginStatus =
                            case model2.loginStatus of
                                LoggedIn loggedIn ->
                                    LoggedIn { loggedIn | revealedSpoilers = Nothing }

                                NotLoggedIn _ ->
                                    model2.loginStatus
                    }
            in
            updateLoggedIn
                (\loggedIn ->
                    ( startOpeningChannelSidebar loggedIn
                    , Command.batch [ viewCmd, openChannelCmds threadRoute model3 ]
                    )
                )
                model3

        DiscordDmRoute routeData ->
            let
                model3 : LoadedFrontend
                model3 =
                    { model2
                        | loginStatus =
                            case model2.loginStatus of
                                LoggedIn loggedIn ->
                                    LoggedIn { loggedIn | revealedSpoilers = Nothing }

                                NotLoggedIn _ ->
                                    model2.loginStatus
                    }
            in
            updateLoggedIn
                (\loggedIn ->
                    ( startOpeningChannelSidebar loggedIn
                    , Command.batch
                        [ viewCmd
                        , openChannelCmds (NoThreadWithFriends routeData.viewingMessage routeData.showMembersTab) model3
                        ]
                    )
                )
                model3

        SlackOAuthRedirect result ->
            ( model2
            , case result of
                Ok ( code, sessionId ) ->
                    Lamdera.sendToBackend (LinkSlackOAuthCode code sessionId)

                Err () ->
                    viewCmd
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


updateLoggedIn :
    (LoggedIn2 -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg ))
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
updateLoggedIn updateFunc model =
    case model.loginStatus of
        LoggedIn loggedIn ->
            updateFunc loggedIn |> Tuple.mapFirst (\a -> { model | loginStatus = LoggedIn a })

        NotLoggedIn _ ->
            ( model, Command.none )


openChannelCmds :
    ThreadRouteWithFriends
    -> LoadedFrontend
    -> Command FrontendOnly ToBackend FrontendMsg
openChannelCmds threadRoute model3 =
    let
        scrollToBottom : Command FrontendOnly ToBackend FrontendMsg
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
                        Scroll.smoothScroll (Pages.Guild.threadMessageHtmlId messageIndex)
                            |> Task.attempt (\_ -> ScrolledToMessage)

                    Nothing ->
                        scrollToBottom

            NoThreadWithFriends maybeMessageIndex _ ->
                case maybeMessageIndex of
                    Just messageIndex ->
                        Scroll.smoothScroll (Pages.Guild.channelMessageHtmlId messageIndex)
                            |> Task.attempt (\_ -> ScrolledToMessage)

                    Nothing ->
                        scrollToBottom
        ]


isPressMsg : FrontendMsg -> Bool
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

        PressedShowLogin ->
            True

        AdminPageMsg _ ->
            False

        PressedLogOut ->
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

        MouseEnteredChannelName _ _ _ ->
            False

        MouseExitedChannelName _ _ _ ->
            False

        EditChannelFormChanged _ _ _ ->
            False

        PressedCancelEditChannelChanges _ _ ->
            True

        PressedSubmitEditChannelChanges _ _ _ ->
            True

        PressedDeleteChannel _ _ ->
            True

        PressedCreateInviteLink _ ->
            True

        FrontendNoOp ->
            False

        PressedCopyText _ ->
            True

        PressedCreateGuild ->
            True

        NewGuildFormChanged _ ->
            False

        PressedSubmitNewGuild _ ->
            True

        PressedCancelNewGuild ->
            True

        DebouncedTyping ->
            False

        GotPingUserPosition _ _ ->
            False

        SetFocus ->
            False

        RemoveFocus ->
            False

        TextInputGotFocus _ ->
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

        CheckedPwaStatus _ ->
            False

        TouchStart _ _ _ ->
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

        ScrolledToMessage ->
            False

        MessageMenu_PressedClose ->
            True

        MessageMenu_PressedContainer ->
            True

        PressedCancelMessageEdit _ ->
            True

        CheckMessageAltPress _ _ _ _ ->
            False

        PressedShowUserOption ->
            True

        PressedCloseUserOptions ->
            True

        TwoFactorMsg twoFactorMsg ->
            TwoFactorAuthentication.isPressMsg twoFactorMsg

        AiChatMsg aiChatMsg ->
            AiChat.isPressMsg aiChatMsg

        UserNameEditableMsg editableMsg ->
            Editable.isPressMsg editableMsg

        ProfilePictureEditorMsg imageEditorMsg ->
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

        GotTimezone _ ->
            False

        FileUploadProgress _ _ _ ->
            False

        MessageMenu_PressedOpenThread _ ->
            True

        MessageViewMsg _ _ messageViewMsg ->
            MessageView.isPressMsg messageViewMsg

        GotRegisterPushSubscription _ ->
            False

        SelectedNotificationMode _ ->
            True

        PressedGuildNotificationLevel _ _ ->
            True

        GotScrollbarWidth _ ->
            False

        PressedViewAttachedFileInfo _ _ ->
            True

        EditMessage_PressedViewAttachedFileInfo _ _ ->
            True

        PressedCloseImageInfo ->
            True

        PressedShowMembers ->
            True

        PressedMemberListBack ->
            True

        GotUserAgent _ ->
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

        PressedLinkDiscordUser ->
            True

        PressedReloadDiscordUser _ ->
            True

        PressedUnlinkDiscordUser _ ->
            True

        MouseEnteredDiscordChannelName _ _ _ ->
            False

        MouseExitedDiscordChannelName _ _ _ ->
            False

        PressedDiscordGuildMemberLabel _ ->
            True

        TypedDiscordLinkBookmarklet ->
            False

        GotVersionNumber _ ->
            False

        PressedDiscordGuildNotificationLevel _ _ ->
            True

        PressedCloseExternalLinkWarning ->
            True

        PressedAddDomainToWhitelist _ ->
            True

        PressedRemoveDomainFromWhitelist _ ->
            True

        PressedContinueToSite ->
            True

        EditMessage_MessageInputMsg _ _ messageInputMsg ->
            MessageInput.isPress messageInputMsg

        MessageInputMsg _ _ messageInputMsg ->
            MessageInput.isPress messageInputMsg

        GotEmojiData _ ->
            False

        GotEditMessageTextInputPositionForEmojiSelector _ ->
            False

        MessageMenu_PressedReactionEmoji _ ->
            True


setFocus : LoadedFrontend -> HtmlId -> Command FrontendOnly toMsg FrontendMsg
setFocus model htmlId =
    if MyUi.isMobile model then
        Command.none

    else
        Dom.focus htmlId |> Task.attempt (\_ -> SetFocus)


startOpeningChannelSidebar : LoggedIn2 -> LoggedIn2
startOpeningChannelSidebar loggedIn =
    { loggedIn
        | sidebarMode =
            ChannelSidebarOpening
                { offset =
                    case loggedIn.sidebarMode of
                        ChannelSidebarClosing { offset } ->
                            offset

                        ChannelSidebarClosed ->
                            1

                        ChannelSidebarOpened ->
                            0

                        ChannelSidebarOpening { offset } ->
                            offset

                        ChannelSidebarDragging { offset } ->
                            offset
                }
    }


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

                Local_SendMessage createdAt guildOrDmId text threadRouteWithRepliedTo attachedFiles ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            case LocalState.getGuildAndChannel guildId channelId local of
                                Just ( guild, channel ) ->
                                    let
                                        user =
                                            local.localUser.user

                                        localUser =
                                            local.localUser
                                    in
                                    { local
                                        | guilds =
                                            guildSendMessage
                                                guildId
                                                guild
                                                channelId
                                                channel
                                                threadRouteWithRepliedTo
                                                createdAt
                                                localUser.session.userId
                                                text
                                                attachedFiles
                                                local
                                        , localUser =
                                            { localUser
                                                | user =
                                                    { user
                                                        | lastViewed =
                                                            SeqDict.insert
                                                                (GuildOrDmId guildOrDmId)
                                                                (Array.length channel.messages |> Id.fromInt)
                                                                user.lastViewed
                                                    }
                                            }
                                    }

                                Nothing ->
                                    local

                        GuildOrDmId_Dm otherUserId ->
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
                                                (Message.userTextMessage
                                                    createdAt
                                                    localUser.session.userId
                                                    text
                                                    maybeReplyTo
                                                    attachedFiles
                                                    |> Tuple.first
                                                )
                                                dmChannel

                                        NoThreadWithMaybeMessage maybeReplyTo ->
                                            LocalState.createChannelMessageFrontend
                                                (Message.userTextMessage
                                                    createdAt
                                                    localUser.session.userId
                                                    text
                                                    maybeReplyTo
                                                    attachedFiles
                                                    |> Tuple.first
                                                )
                                                dmChannel
                            in
                            { local
                                | dmChannels = SeqDict.insert otherUserId dmChannel2 local.dmChannels
                                , localUser =
                                    { localUser
                                        | user =
                                            { user
                                                | lastViewed =
                                                    SeqDict.insert
                                                        (GuildOrDmId guildOrDmId)
                                                        (DmChannel.latestMessageId dmChannel2)
                                                        user.lastViewed
                                            }
                                    }
                            }

                Local_Discord_SendMessage createdAt guildOrDmId text threadRouteWithRepliedTo attachedFiles ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId ->
                            case LocalState.getDiscordGuildAndChannel guildId channelId local of
                                Just ( guild, channel ) ->
                                    let
                                        user =
                                            local.localUser.user

                                        localUser =
                                            local.localUser
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
                                                currentDiscordUserId
                                                text
                                                attachedFiles
                                                local
                                        , localUser =
                                            { localUser
                                                | user =
                                                    { user
                                                        | lastViewed =
                                                            SeqDict.insert
                                                                (DiscordGuildOrDmId guildOrDmId)
                                                                (Array.length channel.messages |> Id.fromInt)
                                                                user.lastViewed
                                                    }
                                            }
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
                                                            (Message.userTextMessage
                                                                createdAt
                                                                currentUserId
                                                                text
                                                                maybeReplyTo
                                                                attachedFiles
                                                                |> Tuple.first
                                                            )
                                                            dmChannel
                                                )
                                                local.discordDmChannels
                                        , localUser =
                                            { localUser
                                                | user =
                                                    { user
                                                        | lastViewed =
                                                            SeqDict.insert
                                                                (DiscordGuildOrDmId guildOrDmId)
                                                                (Array.length dmChannel.messages |> Id.fromInt)
                                                                user.lastViewed
                                                    }
                                            }
                                    }

                                Nothing ->
                                    local

                Local_NewChannel time guildId channelName ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.createChannelFrontend time local.localUser.session.userId channelName)
                                local.guilds
                    }

                Local_EditChannel guildId channelId channelName ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.editChannel channelName channelId)
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
                                        (LocalState.guildToFrontend (Just ( LocalState.announcementChannel guild, NoThread )) guild)
                                        local.guilds
                            }

                Local_MemberTyping time ( guildOrDmId, threadRoute ) ->
                    case guildOrDmId of
                        GuildOrDmId guildOrDmId2 ->
                            memberTyping time local.localUser.session.userId guildOrDmId2 threadRoute local

                        DiscordGuildOrDmId guildOrDmId2 ->
                            case guildOrDmId2 of
                                DiscordGuildOrDmId_Guild userId guildId channelId ->
                                    discordGuildMemberTyping time userId guildId channelId threadRoute local

                                DiscordGuildOrDmId_Dm data ->
                                    discordDmMemberTyping time data.currentUserId data.channelId local

                Local_AddReactionEmoji guildOrDmId threadRoute emoji ->
                    addReactionEmoji local.localUser.session.userId guildOrDmId threadRoute emoji local

                Local_RemoveReactionEmoji guildOrDmId threadRoute emoji ->
                    removeReactionEmoji local.localUser.session.userId guildOrDmId threadRoute emoji local

                Local_SendEditMessage time guildOrDmId threadRoute newContent attachedFiles ->
                    editMessage time local.localUser.session.userId guildOrDmId newContent attachedFiles threadRoute local

                Local_Discord_SendEditGuildMessage time currentUserId guildId channelId threadRoute newContent ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.updateChannel
                                    (\channel ->
                                        LocalState.editMessageFrontendHelper
                                            time
                                            currentUserId
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

                Local_Discord_SendEditDmMessage time dmData messageId newContent ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                dmData.channelId
                                (\dmChannel ->
                                    LocalState.editMessageFrontendHelperNoThread
                                        time
                                        dmData.currentUserId
                                        newContent
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
                        user =
                            local.localUser.user

                        localUser =
                            local.localUser
                    in
                    case threadRoute of
                        ViewThreadWithMessage threadMessageId messageId ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            { user
                                                | lastViewedThreads =
                                                    SeqDict.insert ( guildOrDmId, threadMessageId ) messageId user.lastViewedThreads
                                            }
                                    }
                            }

                        NoThreadWithMessage messageId ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            { user
                                                | lastViewed =
                                                    SeqDict.insert guildOrDmId messageId user.lastViewed
                                            }
                                    }
                            }

                Local_DeleteMessage guildOrDmId threadRoute ->
                    deleteMessage guildOrDmId threadRoute local

                Local_CurrentlyViewing viewing ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser

                        session : UserSession
                        session =
                            UserSession.setCurrentlyViewing
                                (UserSession.setViewingToCurrentlyViewing viewing)
                                localUser.session
                    in
                    case viewing of
                        ViewDm otherUserId messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user = User.setLastDmViewed (DmChannelLastViewed otherUserId NoThread) localUser.user
                                        , session = session
                                    }
                                , dmChannels =
                                    SeqDict.updateIfExists
                                        otherUserId
                                        (DmChannel.loadMessages messagesLoaded)
                                        local.dmChannels
                            }

                        ViewDmThread otherUserId threadId messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            User.setLastDmViewed (DmChannelLastViewed otherUserId (ViewThread threadId)) localUser.user
                                        , session = session
                                    }
                                , dmChannels =
                                    SeqDict.updateIfExists
                                        otherUserId
                                        (\dmChannel ->
                                            { dmChannel
                                                | threads =
                                                    SeqDict.updateIfExists
                                                        threadId
                                                        (DmChannel.loadMessages messagesLoaded)
                                                        dmChannel.threads
                                            }
                                        )
                                        local.dmChannels
                            }

                        ViewDiscordDm _ channelId messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user = User.setLastDmViewed (DiscordDmChannelLastViewed channelId) localUser.user
                                        , session = session
                                    }
                                , discordDmChannels =
                                    SeqDict.updateIfExists
                                        channelId
                                        (DmChannel.loadMessages messagesLoaded)
                                        local.discordDmChannels
                            }

                        ViewChannel guildId channelId messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user = User.setLastChannelViewed guildId channelId NoThread localUser.user
                                        , session = session
                                    }
                                , guilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel (DmChannel.loadMessages messagesLoaded) channelId)
                                        local.guilds
                            }

                        ViewChannelThread guildId channelId threadId messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            User.setLastChannelViewed guildId channelId (ViewThread threadId) localUser.user
                                        , session = session
                                    }
                                , guilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel
                                            (\channel ->
                                                { channel
                                                    | threads =
                                                        SeqDict.updateIfExists
                                                            threadId
                                                            (DmChannel.loadMessages messagesLoaded)
                                                            channel.threads
                                                }
                                            )
                                            channelId
                                        )
                                        local.guilds
                            }

                        StopViewingChannel ->
                            { local | localUser = { localUser | session = session } }

                        ViewDiscordChannel guildId channelId _ messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            User.setLastDiscordChannelViewed
                                                guildId
                                                channelId
                                                NoThread
                                                localUser.user
                                        , session = session
                                    }
                                , discordGuilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel (DmChannel.loadMessages messagesLoaded) channelId)
                                        local.discordGuilds
                            }

                        ViewDiscordChannelThread guildId channelId _ threadId messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            User.setLastDiscordChannelViewed
                                                guildId
                                                channelId
                                                (ViewThread threadId)
                                                localUser.user
                                        , session = session
                                    }
                                , discordGuilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel
                                            (\channel ->
                                                { channel
                                                    | threads =
                                                        SeqDict.updateIfExists
                                                            threadId
                                                            (DmChannel.loadMessages messagesLoaded)
                                                            channel.threads
                                                }
                                            )
                                            channelId
                                        )
                                        local.discordGuilds
                            }

                Local_SetName name ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local | localUser = { localUser | user = User.setName name localUser.user } }

                Local_LoadChannelMessages guildOrDmId previousOldestVisibleMessage messagesLoaded ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
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

                        GuildOrDmId_Dm otherUserId ->
                            { local
                                | dmChannels =
                                    SeqDict.updateIfExists
                                        otherUserId
                                        (DmChannel.loadOlderMessages previousOldestVisibleMessage messagesLoaded)
                                        local.dmChannels
                            }

                Local_LoadThreadMessages guildOrDmId threadId previousOldestVisibleMessage messagesLoaded ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
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

                        GuildOrDmId_Dm otherUserId ->
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
                        DiscordGuildOrDmId_Guild _ guildId channelId ->
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
                        DiscordGuildOrDmId_Guild _ guildId channelId ->
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

                Local_SetDiscordGuildNotificationLevel guildId notificationLevel ->
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

                Local_RegisterPushSubscription pushSubscription ->
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
                            { localUser | session = { session | pushSubscription = Subscribed pushSubscription } }
                    }

                Local_TextEditor localChange2 ->
                    { local
                        | textEditor =
                            TextEditor.localChangeUpdate local.localUser.session.userId localChange2 local.textEditor
                    }

                Local_UnlinkDiscordUser userId ->
                    unlinkDiscordUser userId local

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

                Local_SetEmojiCategory category ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local | localUser = { localUser | user = User.setEmojiCategory category localUser.user } }

                Local_SetEmojiSkinTone maybeSkinTone ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local | localUser = { localUser | user = User.setEmojiSkinTone maybeSkinTone localUser.user } }

        ServerChange serverChange ->
            case serverChange of
                Server_SendMessage createdBy createdAt guildOrDmId text threadRouteWithRepliedTo attachedFiles ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            case LocalState.getGuildAndChannel guildId channelId local of
                                Just ( guild, channel ) ->
                                    let
                                        localUser : LocalUser
                                        localUser =
                                            local.localUser

                                        user : FrontendCurrentUser
                                        user =
                                            localUser.user

                                        isNotViewing : Bool
                                        isNotViewing =
                                            isViewing
                                                (GuildOrDmId guildOrDmId)
                                                (case threadRouteWithRepliedTo of
                                                    ViewThreadWithMaybeMessage threadId _ ->
                                                        ViewThread threadId

                                                    NoThreadWithMaybeMessage _ ->
                                                        NoThread
                                                )
                                                local
                                                |> not
                                    in
                                    { local
                                        | guilds =
                                            guildSendMessage
                                                guildId
                                                guild
                                                channelId
                                                channel
                                                threadRouteWithRepliedTo
                                                createdAt
                                                createdBy
                                                text
                                                attachedFiles
                                                local
                                        , localUser =
                                            { localUser
                                                | user =
                                                    if createdBy == localUser.session.userId then
                                                        { user
                                                            | lastViewed =
                                                                SeqDict.insert
                                                                    (GuildOrDmId guildOrDmId)
                                                                    (Array.length channel.messages |> Id.fromInt)
                                                                    user.lastViewed
                                                        }

                                                    else if
                                                        isNotViewing
                                                            && (LocalState.usersMentionedOrRepliedToFrontend
                                                                    threadRouteWithRepliedTo
                                                                    text
                                                                    channel
                                                                    |> SeqSet.member localUser.session.userId
                                                               )
                                                    then
                                                        User.addDirectMention
                                                            guildId
                                                            channelId
                                                            (case threadRouteWithRepliedTo of
                                                                ViewThreadWithMaybeMessage threadId _ ->
                                                                    ViewThread threadId

                                                                NoThreadWithMaybeMessage _ ->
                                                                    NoThread
                                                            )
                                                            user

                                                    else
                                                        user
                                            }
                                    }

                                Nothing ->
                                    local

                        GuildOrDmId_Dm otherUserId ->
                            let
                                localUser : LocalUser
                                localUser =
                                    local.localUser

                                user : FrontendCurrentUser
                                user =
                                    localUser.user

                                dmChannel : FrontendDmChannel
                                dmChannel =
                                    SeqDict.get otherUserId local.dmChannels |> Maybe.withDefault DmChannel.frontendInit

                                dmChannel2 : FrontendDmChannel
                                dmChannel2 =
                                    case threadRouteWithRepliedTo of
                                        ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                                            LocalState.createThreadMessageFrontend
                                                threadId
                                                (Message.userTextMessage
                                                    createdAt
                                                    localUser.session.userId
                                                    text
                                                    maybeReplyTo
                                                    attachedFiles
                                                    |> Tuple.first
                                                )
                                                dmChannel

                                        NoThreadWithMaybeMessage maybeReplyTo ->
                                            LocalState.createChannelMessageFrontend
                                                (Message.userTextMessage
                                                    createdAt
                                                    createdBy
                                                    text
                                                    maybeReplyTo
                                                    attachedFiles
                                                    |> Tuple.first
                                                )
                                                dmChannel
                            in
                            { local
                                | dmChannels = SeqDict.insert otherUserId dmChannel2 local.dmChannels
                                , localUser =
                                    { localUser
                                        | user =
                                            if createdBy == localUser.session.userId then
                                                { user
                                                    | lastViewed =
                                                        SeqDict.insert
                                                            (GuildOrDmId guildOrDmId)
                                                            (DmChannel.latestMessageId dmChannel2)
                                                            user.lastViewed
                                                }

                                            else
                                                user
                                    }
                            }

                Server_Discord_SendMessage createdAt guildOrDmId text threadRouteWithRepliedTo attachedFiles ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild discordUserId guildId channelId ->
                            case LocalState.getDiscordGuildAndChannel guildId channelId local of
                                Just ( guild, channel ) ->
                                    let
                                        localUser : LocalUser
                                        localUser =
                                            local.localUser

                                        user : FrontendCurrentUser
                                        user =
                                            localUser.user

                                        isNotViewing : Bool
                                        isNotViewing =
                                            isViewing
                                                (DiscordGuildOrDmId guildOrDmId)
                                                (case threadRouteWithRepliedTo of
                                                    ViewThreadWithMaybeMessage threadId _ ->
                                                        ViewThread threadId

                                                    NoThreadWithMaybeMessage _ ->
                                                        NoThread
                                                )
                                                local
                                                |> not
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
                                                discordUserId
                                                text
                                                attachedFiles
                                                local
                                        , localUser =
                                            { localUser
                                                | user =
                                                    if SeqDict.member discordUserId localUser.linkedDiscordUsers then
                                                        { user
                                                            | lastViewed =
                                                                SeqDict.insert
                                                                    (DiscordGuildOrDmId guildOrDmId)
                                                                    (Array.length channel.messages |> Id.fromInt)
                                                                    user.lastViewed
                                                        }

                                                    else if
                                                        isNotViewing
                                                            && (LocalState.usersMentionedOrRepliedToFrontend
                                                                    threadRouteWithRepliedTo
                                                                    text
                                                                    channel
                                                                    |> SeqSet.member discordUserId
                                                               )
                                                    then
                                                        User.addDiscordDirectMention
                                                            guildId
                                                            channelId
                                                            (case threadRouteWithRepliedTo of
                                                                ViewThreadWithMaybeMessage threadId _ ->
                                                                    ViewThread threadId

                                                                NoThreadWithMaybeMessage _ ->
                                                                    NoThread
                                                            )
                                                            user

                                                    else
                                                        user
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
                                                (Message.userTextMessage
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
                                                    |> Tuple.first
                                                )
                                                dmChannel
                                    in
                                    { local
                                        | discordDmChannels = SeqDict.insert data.channelId dmChannel2 local.discordDmChannels
                                        , localUser =
                                            { localUser
                                                | user =
                                                    if SeqDict.member data.currentUserId localUser.linkedDiscordUsers then
                                                        { user
                                                            | lastViewed =
                                                                SeqDict.insert
                                                                    (DiscordGuildOrDmId guildOrDmId)
                                                                    (DmChannel.latestMessageId dmChannel2)
                                                                    user.lastViewed
                                                        }

                                                    else
                                                        user
                                            }
                                    }

                                Nothing ->
                                    local

                Server_NewChannel time guildId channelName ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.createChannelFrontend time local.localUser.session.userId channelName)
                                local.guilds
                    }

                Server_EditChannel guildId channelId channelName ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.editChannel channelName channelId)
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

                Server_NewInviteLink time userId guildId inviteLinkId ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.addInvite inviteLinkId userId time)
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
                                            LocalState.markAllChannelsAsViewed
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

                Server_SendEditMessage time userId guildOrDmId messageIndex newContent attachedFiles ->
                    editMessage time userId guildOrDmId newContent attachedFiles messageIndex local

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

                Server_PushNotificationFailed error ->
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
                            { localUser | session = { session | pushSubscription = SubscriptionError error } }
                    }

                Server_NewSession sessionId session ->
                    { local | otherSessions = SeqDict.insert sessionId session local.otherSessions }

                Server_LoggedOut sessionId ->
                    { local | otherSessions = SeqDict.remove sessionId local.otherSessions }

                Server_CurrentlyViewing sessionIdHash currentlyViewing ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    if sessionIdHash == localUser.session.sessionIdHash then
                        { local
                            | localUser =
                                { localUser
                                    | session = UserSession.setCurrentlyViewing currentlyViewing localUser.session
                                }
                        }

                    else
                        { local
                            | otherSessions =
                                SeqDict.updateIfExists
                                    sessionIdHash
                                    (UserSession.setCurrentlyViewing currentlyViewing)
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
                            { localUser | linkedDiscordUsers = SeqDict.insert userId user localUser.linkedDiscordUsers }
                    }

                Server_UnlinkDiscordUser userId ->
                    unlinkDiscordUser userId local

                Server_DiscordChannelCreated guildId channelId channelName topic ->
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
                                                            }
                                                                |> Just

                                                        Nothing ->
                                                            { name = channelName
                                                            , description =
                                                                LocalState.discordTopicToDescription
                                                                    topic
                                                                    ChannelDescription.empty
                                                            , messages = Array.empty
                                                            , visibleMessages = VisibleMessages.empty
                                                            , lastTypedAt = SeqDict.empty
                                                            , threads = SeqDict.empty
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
                                            { messages = Array.empty
                                            , visibleMessages = VisibleMessages.empty
                                            , lastTypedAt = SeqDict.empty
                                            , members = members
                                            }
                                                |> Just
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
                                | linkedDiscordUsers =
                                    SeqDict.updateIfExists
                                        userId
                                        (\user -> { user | needsAuthAgain = True })
                                        localUser.linkedDiscordUsers
                            }
                    }

                Server_DiscordUserLoadingDataIsDone discordUserId result ->
                    let
                        localUser =
                            local.localUser
                    in
                    case result of
                        Ok data ->
                            { local
                                | localUser =
                                    { localUser
                                        | linkedDiscordUsers =
                                            SeqDict.updateIfExists
                                                discordUserId
                                                (\user ->
                                                    { user
                                                        | isLoadingData =
                                                            case result of
                                                                Ok _ ->
                                                                    DiscordUserLoadedSuccessfully

                                                                Err time ->
                                                                    DiscordUserLoadingFailed time
                                                    }
                                                )
                                                localUser.linkedDiscordUsers
                                        , otherDiscordUsers = SeqDict.foldl SeqDict.insert localUser.otherDiscordUsers data.discordUsers
                                    }
                                , discordGuilds = SeqDict.foldl SeqDict.insert local.discordGuilds data.discordGuilds
                                , discordDmChannels = SeqDict.foldl SeqDict.insert local.discordDmChannels data.discordDms
                            }

                        Err time ->
                            { local
                                | localUser =
                                    { localUser
                                        | linkedDiscordUsers =
                                            SeqDict.updateIfExists
                                                discordUserId
                                                (\user -> { user | isLoadingData = DiscordUserLoadingFailed time })
                                                localUser.linkedDiscordUsers
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
                    case LocalState.getGuildAndChannel guildId channelId local of
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

                Server_DiscordGuildJoinedOrCreated guildId guild ->
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
                    }

                Server_DiscordUpdateChannel guildId channelId name topic ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.updateChannel
                                    (\channel ->
                                        { channel
                                            | name =
                                                case name of
                                                    Discord.Included name2 ->
                                                        ChannelName.fromStringLossy name2

                                                    Discord.Missing ->
                                                        channel.name
                                            , description =
                                                LocalState.discordTopicToDescription topic channel.description
                                        }
                                    )
                                    channelId
                                )
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
                                (Message.userTextMessage
                                    createdAt
                                    userId
                                    text
                                    maybeReplyTo
                                    attachedFiles
                                    |> Tuple.first
                                )
                                channel

                        NoThreadWithMaybeMessage maybeReplyTo ->
                            LocalState.createChannelMessageFrontend
                                (Message.userTextMessage
                                    createdAt
                                    userId
                                    text
                                    maybeReplyTo
                                    attachedFiles
                                    |> Tuple.first
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
                                (Message.userTextMessage
                                    createdAt
                                    discordUserId
                                    text
                                    maybeReplyTo
                                    attachedFiles
                                    |> Tuple.first
                                )
                                channel

                        NoThreadWithMaybeMessage maybeReplyTo ->
                            LocalState.createChannelMessageFrontend
                                (Message.userTextMessage
                                    createdAt
                                    discordUserId
                                    text
                                    maybeReplyTo
                                    attachedFiles
                                    |> Tuple.first
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
    , discordDmChannels = adminData.discordDmChannels
    , discordUsers = adminData.discordUsers
    , discordGuilds = adminData.discordGuilds
    , guilds = adminData.guilds
    , loadingDiscordChannels = adminData.loadingDiscordChannels
    , signupsEnabled = adminData.signupsEnabled
    , logs = adminData.logs
    , connections = adminData.connections
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
                | linkedDiscordUsers =
                    SeqDict.updateIfExists
                        discordUserId
                        (\user -> { user | isLoadingData = DiscordUserLoadingData time })
                        localUser.linkedDiscordUsers
            }
    }


unlinkDiscordUser : Discord.Id Discord.UserId -> LocalState -> LocalState
unlinkDiscordUser userId local =
    let
        localUser =
            local.localUser
    in
    { local
        | localUser =
            { localUser | linkedDiscordUsers = SeqDict.remove userId localUser.linkedDiscordUsers }
    }


memberTyping : Time.Posix -> Id UserId -> GuildOrDmId -> ThreadRoute -> LocalState -> LocalState
memberTyping time userId guildOrDmId threadRoute local =
    case guildOrDmId of
        GuildOrDmId_Guild guildId channelId ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel (LocalState.memberIsTyping userId time threadRoute) channelId)
                        local.guilds
            }

        GuildOrDmId_Dm otherUserId ->
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


addReactionEmoji : Id UserId -> AnyGuildOrDmId -> ThreadRouteWithMessage -> Emoji -> LocalState -> LocalState
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
        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
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

        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (LocalState.addReactionEmojiFrontend emoji userId threadRoute)
                        local.dmChannels
                , localUser = localUser2
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId) ->
            { local
                | discordGuilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel
                            (LocalState.addReactionEmojiFrontend emoji currentDiscordUserId threadRoute)
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
    -> Emoji
    -> LocalState
    -> LocalState
removeReactionEmoji userId guildOrDmId threadRoute emoji local =
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
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

        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (LocalState.removeReactionEmojiFrontend emoji userId threadRoute)
                        local.dmChannels
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId) ->
            { local
                | discordGuilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel
                            (LocalState.removeReactionEmojiFrontend emoji currentDiscordUserId threadRoute)
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
        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
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

        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
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

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId) ->
            { local
                | discordGuilds =
                    SeqDict.updateIfExists
                        guildId
                        (\guild ->
                            LocalState.memberIsEditTypingFrontend currentDiscordUserId time channelId threadRoute guild
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
    -> Nonempty (RichText (Id UserId))
    -> SeqDict (Id FileId) FileData
    -> ThreadRouteWithMessage
    -> LocalState
    -> LocalState
editMessage time userId guildOrDmId newContent attachedFiles threadRoute local =
    case guildOrDmId of
        GuildOrDmId_Guild guildId channelId ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel
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
                        )
                        local.guilds
            }

        GuildOrDmId_Dm otherUserId ->
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


deleteMessage : AnyGuildOrDmId -> ThreadRouteWithMessage -> LocalState -> LocalState
deleteMessage guildOrDmId threadRoute local =
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.deleteMessageFrontend channelId threadRoute)
                        local.guilds
            }

        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (LocalState.deleteMessageFrontendHelper threadRoute)
                        local.dmChannels
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild _ guildId channelId) ->
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
    in
    if selection.start == selection.end then
        if htmlId == Pages.Guild.channelTextInputId then
            case SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.drafts of
                Just draft ->
                    helper selection.start (String.Nonempty.toString draft)

                Nothing ->
                    Nothing

        else if htmlId == MessageMenu.editMessageTextInputId then
            case SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.editMessage of
                Just edit ->
                    helper selection.start edit.text

                Nothing ->
                    Nothing

        else
            Nothing

    else
        Nothing
