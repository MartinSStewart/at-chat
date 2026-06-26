module Pages.Guild exposing
    ( DmChannelSelection(..)
    , HighlightMessage(..)
    , IsHovered(..)
    , channelMessageHtmlId
    , channelTextInputId
    , conversationContainerId
    , decodeMessageView
    , discordGuildView
    , dropdownButtonId
    , encodeMessageView
    , guildView
    , homePageLoggedInView
    , newGuildFormInit
    , scrollCloseToTop
    , threadMessageHtmlId
    , typingDebouncerDelay
    )

import Array exposing (Array)
import Array.Extra
import Bitwise
import Call
import ChannelDescription
import ChannelHeader
import ChannelName exposing (ChannelName)
import Coord
import CustomEmoji exposing (CustomEmojiData)
import Date exposing (Date)
import Discord
import DmChannel exposing (DiscordFrontendDmChannel, FrontendDmChannel)
import Drawing exposing (Drawing)
import Duration exposing (Duration)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Emoji exposing (EmojiConfig, EmojiOrCustomEmoji(..))
import Env
import FileStatus exposing (FileHash, FileId, FileStatus)
import GuildIcon exposing (ChannelNotificationType(..))
import GuildName
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, CustomEmojiId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, StickerId, ThreadMessageId, ThreadRoute(..), ThreadRouteWithMessage(..), UserId)
import ImageEditor
import Json.Decode
import LinkedAndOtherDiscordUsers exposing (DiscordFrontendCurrentUser)
import List.Extra
import List.Nonempty exposing (Nonempty)
import LocalState exposing (DiscordFrontendChannel, DiscordFrontendGuild, FrontendChannel, FrontendGuild, LocalState)
import Maybe.Extra
import MembersAndOwner exposing (IsMember(..), MembersAndOwner)
import Message exposing (Game(..), Message(..), MessageState(..), UserTextMessageData)
import MessageInput exposing (TextInputFocus)
import MessageMenu
import MessageView exposing (MessageViewMsg(..))
import MyUi exposing (Copied(..))
import NonemptyDict exposing (NonemptyDict)
import NonemptySet exposing (NonemptySet)
import OneOrGreater exposing (OneOrGreater)
import OneToOne
import PersonName exposing (PersonName)
import QRCode
import Quantity
import RichText exposing (RichText)
import Route exposing (ChannelRoute(..), DiscordChannelRoute(..), DiscordDmRouteData, DiscordGuildRouteData, DmRouteData, Route(..), ShowMembersTab(..), ThreadRouteWithFriends(..))
import SecretId
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Sticker exposing (AnimationMode(..))
import String.Nonempty
import Thread exposing (DiscordFrontendThread, FrontendGenericThread, FrontendThread, LastTypedAt)
import Time
import Touch
import Types exposing (Drag(..), EditChannelForm, EditGuildForm, EditMessage, EmojiSelector(..), FrontendMsg(..), GuildChannelNameHover(..), LoadedFrontend, LoggedIn2, MessageHover(..), NewChannelForm, NewGuildForm, ScrollPosition(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Gradient
import Ui.Input
import Ui.Keyed
import Ui.Lazy
import Ui.Prose
import Ui.Shadow
import User exposing (FrontendCurrentUser, FrontendUser, LocalUser, NotificationLevel(..))
import UserSession exposing (DiscordFrontendUser)
import VisibleMessages exposing (VisibleMessages)


{-| In the case of a channel, it's just the channel, not the threads it contains
-}
channelOrThreadHasNotifications :
    Maybe (NonemptyDict ( channelId, ThreadRoute ) OneOrGreater)
    -> Bool
    -> channelId
    -> ThreadRoute
    -> Maybe (Id messageId)
    -> { a | messages : Array (MessageState messageId userId) }
    -> ChannelNotificationType
channelOrThreadHasNotifications maybeDirectMentions notifyOnAllMessages channelId threadRoute maybeLastViewed channel =
    if notifyOnAllMessages then
        case newMessageCount maybeLastViewed channel |> OneOrGreater.fromInt of
            Just count ->
                NewMessageForUser count

            Nothing ->
                NoNotification

    else
        case Maybe.andThen (NonemptyDict.get ( channelId, threadRoute )) maybeDirectMentions of
            Just count ->
                NewMessageForUser count

            Nothing ->
                case newMessageCount maybeLastViewed channel |> OneOrGreater.fromInt of
                    Just count ->
                        NewMessage count

                    Nothing ->
                        NoNotification


newMessageCount : Maybe (Id messageId) -> { b | messages : Array (MessageState messageId userId) } -> Int
newMessageCount maybeLastViewed channel =
    case maybeLastViewed of
        Just lastViewed ->
            Array.length channel.messages - 1 - Id.toInt lastViewed

        Nothing ->
            Array.length channel.messages


channelNewMessageCount :
    AnyGuildOrDmId
    -> FrontendCurrentUser
    ->
        { b
            | messages : Array (MessageState ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : Array (MessageState ThreadMessageId userId) }
        }
    -> Int
channelNewMessageCount guildOrDmId currentUser channel =
    SeqDict.foldl
        (\threadId thread count ->
            newMessageCount
                (SeqDict.get ( guildOrDmId, threadId ) currentUser.lastViewedThreads)
                thread
                + count
        )
        (newMessageCount (SeqDict.get guildOrDmId currentUser.lastViewed) channel)
        channel.threads


guildNewMessageCount : FrontendCurrentUser -> Id GuildId -> FrontendGuild -> Int
guildNewMessageCount currentUser guildId guild =
    SeqDict.foldl
        (\channelId channel count ->
            channelNewMessageCount (GuildOrDmId (GuildOrDmId_Guild guildId channelId)) currentUser channel + count
        )
        0
        guild.channels


discordGuildNewMessageCount :
    Discord.Id Discord.UserId
    -> FrontendCurrentUser
    -> Discord.Id Discord.GuildId
    -> DiscordFrontendGuild
    -> Int
discordGuildNewMessageCount currentDiscordUserId currentUser guildId guild =
    SeqDict.foldl
        (\channelId channel count ->
            channelNewMessageCount (DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId)) currentUser channel + count
        )
        0
        guild.channels


guildHasNotifications : FrontendCurrentUser -> Id GuildId -> FrontendGuild -> ChannelNotificationType
guildHasNotifications currentUser guildId guild =
    if SeqSet.member guildId currentUser.notifyOnAllMessages then
        case guildNewMessageCount currentUser guildId guild |> OneOrGreater.fromInt of
            Just count ->
                NewMessageForUser count

            Nothing ->
                NoNotification

    else
        case SeqDict.get guildId currentUser.directMentions of
            Just directMentions ->
                NonemptyDict.values directMentions
                    |> List.Nonempty.foldl1 OneOrGreater.plus
                    |> NewMessageForUser

            Nothing ->
                case guildNewMessageCount currentUser guildId guild |> OneOrGreater.fromInt of
                    Just count ->
                        NewMessage count

                    Nothing ->
                        NoNotification


discordGuildHasNotifications :
    Discord.Id Discord.UserId
    -> FrontendCurrentUser
    -> Discord.Id Discord.GuildId
    -> DiscordFrontendGuild
    -> ChannelNotificationType
discordGuildHasNotifications currentDiscordUserId currentUser guildId guild =
    --if SeqSet.member guildId currentUser.notifyOnAllMessages then
    --    case guildNewMessageCount currentUser guildId guild |> OneOrGreater.fromInt of
    --        Just count ->
    --            NewMessageForUser count
    --
    --        Nothing ->
    --            NoNotification
    --
    --else
    case SeqDict.get guildId currentUser.discordDirectMentions of
        Just directMentions ->
            NonemptyDict.values directMentions
                |> List.Nonempty.foldl1 OneOrGreater.plus
                |> NewMessageForUser

        Nothing ->
            case discordGuildNewMessageCount currentDiscordUserId currentUser guildId guild |> OneOrGreater.fromInt of
                Just count ->
                    NewMessage count

                Nothing ->
                    NoNotification


dmHasNotifications : FrontendCurrentUser -> Id UserId -> FrontendDmChannel -> Maybe OneOrGreater
dmHasNotifications currentUser otherUserId dmChannel =
    channelNewMessageCount (GuildOrDmId (GuildOrDmId_Dm otherUserId)) currentUser dmChannel |> OneOrGreater.fromInt


{-| Find the linked Discord user that is a member of this Discord DM channel (i.e. "us").
-}
discordDmCurrentUserId : LocalUser -> DiscordFrontendDmChannel -> Maybe (Discord.Id Discord.UserId)
discordDmCurrentUserId localUser dmChannel =
    List.Extra.findMap
        (\( userId, _ ) ->
            if NonemptyDict.member userId dmChannel.members then
                Just userId

            else
                Nothing
        )
        (SeqDict.toList (LinkedAndOtherDiscordUsers.linkedUsers localUser.discordUsers))


discordDmHasNotifications :
    LocalUser
    -> Discord.Id Discord.PrivateChannelId
    -> DiscordFrontendDmChannel
    -> Maybe ( Discord.Id Discord.UserId, OneOrGreater )
discordDmHasNotifications localUser channelId dmChannel =
    case discordDmCurrentUserId localUser dmChannel of
        Just currentUserId ->
            newMessageCount
                (SeqDict.get
                    (DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId = currentUserId, channelId = channelId }))
                    localUser.user.lastViewed
                )
                dmChannel
                |> OneOrGreater.fromInt
                |> Maybe.map (Tuple.pair currentUserId)

        Nothing ->
            Nothing


canScroll : Drag -> Bool
canScroll drag =
    case drag of
        Dragging dragging ->
            not dragging.horizontalStart

        _ ->
            True


guildColumn :
    Bool
    -> Route
    -> LocalUser
    -> SeqDict (Id UserId) FrontendDmChannel
    -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel
    -> SeqDict (Id GuildId) FrontendGuild
    -> SeqDict (Discord.Id Discord.GuildId) DiscordFrontendGuild
    -> Bool
    -> Element FrontendMsg
guildColumn isMobile route localUser dmChannels discordDmChannels guilds discordGuilds canScroll2 =
    let
        allUsers =
            LocalState.allUsers localUser
    in
    Ui.el
        [ Ui.inFront
            (Ui.el
                [ Ui.backgroundGradient
                    [ Ui.Gradient.linear
                        (Ui.radians 0)
                        [ Ui.Gradient.percent 0 (Ui.rgba 0 0 0 0)
                        , Ui.Gradient.percent 100 MyUi.background1
                        ]
                    ]
                , MyUi.htmlStyle "height" ("calc(max(6px, " ++ MyUi.insetTop ++ "))")
                ]
                Ui.none
            )
        , Ui.width Ui.shrink
        , Ui.height Ui.fill
        ]
        (Ui.column
            [ Ui.spacing 4
            , Ui.width (Ui.px GuildIcon.fullWidth)
            , Ui.height Ui.fill
            , Ui.background MyUi.background1
            , scrollable canScroll2
            , MyUi.htmlStyle "overflow-x" "hidden"
            , Ui.htmlAttribute (Html.Attributes.class "disable-scrollbars")
            , MyUi.htmlStyle "padding" ("calc(max(6px, " ++ MyUi.insetTop ++ ")) 0 4px 0")
            , bounceScroll isMobile
            ]
            (List.filterMap
                (\( otherUserId, dmChannel ) ->
                    let
                        dmIcon =
                            case dmHasNotifications localUser.user otherUserId dmChannel of
                                Just count ->
                                    elLinkButton
                                        (Dom.id ("guildsColumn_openDm_" ++ Id.toString otherUserId))
                                        (DmRoute
                                            { channelId = DmChannel.channelIdFromUserIds localUser.session.userId otherUserId
                                            , threadRoute = NoThreadWithFriends Nothing HideMembersTab
                                            , tab = Nothing
                                            }
                                        )
                                        []
                                        (case SeqDict.get otherUserId allUsers of
                                            Just otherUser ->
                                                GuildIcon.userView (NewMessageForUser count) otherUser.icon otherUserId

                                            Nothing ->
                                                GuildIcon.userView (NewMessageForUser count) Nothing otherUserId
                                        )
                                        |> Just

                                Nothing ->
                                    Nothing
                    in
                    case route of
                        DmRoute dmRoute ->
                            if Just otherUserId == DmChannel.otherUserId localUser.session.userId dmRoute.channelId then
                                Nothing

                            else
                                dmIcon

                        _ ->
                            dmIcon
                )
                (SeqDict.toList dmChannels)
                ++ List.filterMap
                    (\( channelId, dmChannel ) ->
                        let
                            dmIcon =
                                case discordDmHasNotifications localUser channelId dmChannel of
                                    Just ( currentUserId, count ) ->
                                        let
                                            userId : Discord.Id Discord.UserId
                                            userId =
                                                NonemptyDict.remove currentUserId dmChannel.members
                                                    |> SeqDict.keys
                                                    |> List.head
                                                    |> Maybe.withDefault currentUserId

                                            maybeIcon : Maybe FileHash
                                            maybeIcon =
                                                User.getDiscordUser userId localUser |> Maybe.andThen .icon
                                        in
                                        elLinkButton
                                            (Dom.id ("guildsColumn_openDiscordDm_" ++ Discord.idToString channelId))
                                            (DiscordDmRoute
                                                { currentDiscordUserId = currentUserId
                                                , channelId = channelId
                                                , viewingMessage = Nothing
                                                , showMembersTab = HideMembersTab
                                                , tab = Nothing
                                                }
                                            )
                                            []
                                            (GuildIcon.discordUserView (NewMessageForUser count) maybeIcon userId)
                                            |> Just

                                    Nothing ->
                                        Nothing
                        in
                        case route of
                            DiscordDmRoute dmRoute ->
                                if dmRoute.channelId == channelId then
                                    Nothing

                                else
                                    dmIcon

                            _ ->
                                dmIcon
                    )
                    (SeqDict.toList discordDmChannels)
                ++ GuildIcon.showFriendsButton (route == HomePageRoute) (PressedLink HomePageRoute)
                :: List.map
                    (\( guildId, guild ) ->
                        elLinkButton
                            (Dom.id ("guild_openGuild_" ++ Id.toString guildId))
                            (GuildRoute
                                guildId
                                (case SeqDict.get guildId localUser.user.lastChannelViewed of
                                    Just ( channelId, threadRoute ) ->
                                        ChannelRoute
                                            channelId
                                            (case threadRoute of
                                                ViewThread threadId ->
                                                    ViewThreadWithFriends threadId Nothing HideMembersTab

                                                NoThread ->
                                                    NoThreadWithFriends Nothing HideMembersTab
                                            )
                                            Nothing

                                    Nothing ->
                                        ChannelRoute
                                            (LocalState.announcementChannel guild)
                                            (NoThreadWithFriends Nothing HideMembersTab)
                                            Nothing
                                )
                            )
                            []
                            (GuildIcon.view
                                (case route of
                                    GuildRoute a _ ->
                                        if a == guildId then
                                            GuildIcon.IsSelected

                                        else
                                            guildHasNotifications localUser.user guildId guild
                                                |> GuildIcon.Normal

                                    _ ->
                                        guildHasNotifications localUser.user guildId guild |> GuildIcon.Normal
                                )
                                guild
                            )
                    )
                    (SeqDict.toList guilds)
                ++ List.filterMap
                    (\( guildId, guild ) ->
                        let
                            maybeDiscordUserId : Maybe ( Discord.Id Discord.UserId, DiscordFrontendCurrentUser )
                            maybeDiscordUserId =
                                SeqDict.filter
                                    (\linkedUserId _ ->
                                        MembersAndOwner.isMember linkedUserId guild.membersAndOwner /= IsNotMember
                                    )
                                    (LinkedAndOtherDiscordUsers.linkedUsers localUser.discordUsers)
                                    |> SeqDict.toList
                                    |> List.head
                        in
                        case maybeDiscordUserId of
                            Just ( discordUserId, _ ) ->
                                elLinkButton
                                    (Dom.id ("guild_openDiscordGuild_" ++ Discord.idToString guildId))
                                    ({ currentDiscordUserId = discordUserId
                                     , guildId = guildId
                                     , channelRoute =
                                        case SeqDict.get guildId localUser.user.lastDiscordChannelViewed of
                                            Just ( channelId, threadRoute ) ->
                                                DiscordChannel_ChannelRoute
                                                    channelId
                                                    (case threadRoute of
                                                        ViewThread threadId ->
                                                            ViewThreadWithFriends threadId Nothing HideMembersTab

                                                        NoThread ->
                                                            NoThreadWithFriends Nothing HideMembersTab
                                                    )
                                                    Nothing

                                            Nothing ->
                                                DiscordChannel_ChannelRoute
                                                    (LocalState.discordAnnouncementChannel guild)
                                                    (NoThreadWithFriends Nothing HideMembersTab)
                                                    Nothing
                                     }
                                        |> DiscordGuildRoute
                                    )
                                    []
                                    (GuildIcon.view
                                        (case route of
                                            DiscordGuildRoute data ->
                                                if data.guildId == guildId then
                                                    GuildIcon.IsSelected

                                                else
                                                    discordGuildHasNotifications discordUserId localUser.user guildId guild
                                                        |> GuildIcon.Normal

                                            _ ->
                                                discordGuildHasNotifications discordUserId localUser.user guildId guild |> GuildIcon.Normal
                                        )
                                        guild
                                    )
                                    |> Just

                            Nothing ->
                                Nothing
                    )
                    (SeqDict.toList discordGuilds)
                ++ [ GuildIcon.addGuildButton (Dom.id "guild_createGuild") False PressedCreateGuild ]
            )
        )


elLinkButton : HtmlId -> Route -> List (Ui.Attribute FrontendMsg) -> Element FrontendMsg -> Element FrontendMsg
elLinkButton htmlId route attributes content =
    MyUi.elButton htmlId (PressedLink route) attributes content


rowLinkButton : HtmlId -> Route -> List (Ui.Attribute FrontendMsg) -> List (Element FrontendMsg) -> Element FrontendMsg
rowLinkButton htmlId route attributes content =
    MyUi.rowButton htmlId (PressedLink route) attributes content


loggedInAsView : LocalUser -> Element FrontendMsg
loggedInAsView localUser =
    Ui.row
        [ Ui.Font.color MyUi.font2
        , Ui.borderColor MyUi.border1
        , Ui.borderWith { left = 0, bottom = 0, top = 1, right = 0 }
        , Ui.background MyUi.background1
        , MyUi.htmlStyle "padding" ("4px 4px calc(" ++ MyUi.insetBottom ++ " + 4px) 4px")
        , Ui.spacing 8
        , Ui.clipWithEllipsis
        ]
        [ User.profileImageNoRounding localUser.session.userId localUser.user.icon
        , Ui.text (PersonName.toString localUser.user.name)
        , MyUi.elButton
            (Dom.id "guild_showUserOptions")
            PressedShowUserOption
            [ Ui.width (Ui.px 38)
            , Ui.height Ui.fill
            , Ui.contentCenterY
            , Ui.paddingXY 8 0
            , Ui.alignRight
            ]
            (Ui.html Icons.gear)
        ]


type DmChannelSelection
    = SelectedDmChannel DmRouteData
    | SelectedDiscordDmChannel DiscordDmRouteData
    | NoDmChannelSelected


homePageLoggedInView :
    DmChannelSelection
    -> LoadedFrontend
    -> LoggedIn2
    -> LocalState
    -> Element FrontendMsg
homePageLoggedInView maybeOtherUserId model loggedIn local =
    case ( loggedIn.showFileToUploadInfo, loggedIn.newGuildForm ) of
        ( Just fileData, _ ) ->
            FileStatus.imageInfoView PressedCloseImageInfo fileData

        ( Nothing, Just form ) ->
            newGuildFormView form

        ( Nothing, Nothing ) ->
            if MyUi.isMobile model then
                Ui.row
                    [ Ui.height Ui.fill
                    , Ui.background MyUi.background1
                    ]
                    [ Ui.column
                        [ Ui.height Ui.fill
                        , case maybeOtherUserId of
                            SelectedDmChannel dmRoute ->
                                dmChannelView dmRoute loggedIn local model
                                    |> Ui.el
                                        [ Ui.height Ui.fill
                                        , Ui.background MyUi.background3
                                        , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 0 0")
                                        , Ui.move
                                            { x = Call.sidebarOffsetAttr loggedIn.sidebarMode model
                                            , y = 0
                                            , z = 0
                                            }
                                        , Ui.heightMin 0
                                        , Ui.borderColor MyUi.border1
                                        , Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                                        ]
                                    |> Ui.inFront

                            SelectedDiscordDmChannel routeData ->
                                discordDmChannelView routeData loggedIn local model
                                    |> Ui.el
                                        [ Ui.height Ui.fill
                                        , Ui.background MyUi.background3
                                        , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 0 0")
                                        , Ui.move
                                            { x = Call.sidebarOffsetAttr loggedIn.sidebarMode model
                                            , y = 0
                                            , z = 0
                                            }
                                        , Ui.heightMin 0
                                        , Ui.borderColor MyUi.border1
                                        , Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                                        ]
                                    |> Ui.inFront

                            NoDmChannelSelected ->
                                Ui.noAttr
                        ]
                        [ Ui.row
                            [ Ui.height Ui.fill, Ui.heightMin 0 ]
                            [ guildColumnLazy True model local
                            , friendsColumnLazy (canScroll model.drag) True model.time maybeOtherUserId local
                            ]
                        , Ui.Lazy.lazy loggedInAsView local.localUser
                        ]
                    ]

            else
                Ui.row
                    [ Ui.height Ui.fill
                    , Ui.background MyUi.background1
                    ]
                    [ Ui.column
                        [ Ui.height Ui.fill, Ui.width (Ui.px (MyUi.channelAndGuildColumnWidth model.windowSize)) ]
                        [ Ui.row
                            [ Ui.height Ui.fill, Ui.heightMin 0 ]
                            [ guildColumnLazy False model local
                            , friendsColumnLazy (canScroll model.drag) False model.time maybeOtherUserId local
                            ]
                        , Ui.Lazy.lazy loggedInAsView local.localUser
                        ]
                    , case maybeOtherUserId of
                        SelectedDmChannel dmRoute ->
                            dmChannelView dmRoute loggedIn local model
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , Ui.background MyUi.background3
                                    , Ui.heightMin 0
                                    , Ui.borderColor MyUi.border1
                                    , Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                                    ]
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , MyUi.htmlStyle "padding-top" MyUi.insetTop
                                    ]

                        SelectedDiscordDmChannel routeData ->
                            discordDmChannelView routeData loggedIn local model
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , Ui.background MyUi.background3
                                    , Ui.heightMin 0
                                    , Ui.borderColor MyUi.border1
                                    , Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                                    ]
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , MyUi.htmlStyle "padding-top" MyUi.insetTop
                                    ]

                        NoDmChannelSelected ->
                            Ui.el [ Ui.Font.color MyUi.font1, Ui.contentCenterX ] Ui.none
                    ]


guildColumnLazy : Bool -> LoadedFrontend -> LocalState -> Element FrontendMsg
guildColumnLazy isMobile model local =
    Ui.Lazy.lazy6
        (case ( canScroll model.drag, isMobile ) of
            ( True, True ) ->
                guildColumnCanScrollMobile

            ( True, False ) ->
                guildColumnCanScrollNotMobile

            ( False, True ) ->
                guildColumnCannotScrollMobile

            ( False, False ) ->
                guildColumnCannotScrollNotMobile
        )
        model.route
        local.localUser
        local.dmChannels
        local.discordDmChannels
        local.guilds
        local.discordGuilds


guildColumnCanScrollMobile :
    Route
    -> LocalUser
    -> SeqDict (Id UserId) FrontendDmChannel
    -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel
    -> SeqDict (Id GuildId) FrontendGuild
    -> SeqDict (Discord.Id Discord.GuildId) DiscordFrontendGuild
    -> Element FrontendMsg
guildColumnCanScrollMobile route localUser dmChannels discordDmChannels guilds discordGuilds =
    guildColumn True route localUser dmChannels discordDmChannels guilds discordGuilds True


guildColumnCanScrollNotMobile :
    Route
    -> LocalUser
    -> SeqDict (Id UserId) FrontendDmChannel
    -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel
    -> SeqDict (Id GuildId) FrontendGuild
    -> SeqDict (Discord.Id Discord.GuildId) DiscordFrontendGuild
    -> Element FrontendMsg
guildColumnCanScrollNotMobile route localUser dmChannels discordDmChannels guilds discordGuilds =
    guildColumn False route localUser dmChannels discordDmChannels guilds discordGuilds True


guildColumnCannotScrollMobile :
    Route
    -> LocalUser
    -> SeqDict (Id UserId) FrontendDmChannel
    -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel
    -> SeqDict (Id GuildId) FrontendGuild
    -> SeqDict (Discord.Id Discord.GuildId) DiscordFrontendGuild
    -> Element FrontendMsg
guildColumnCannotScrollMobile route localUser dmChannels discordDmChannels guilds discordGuilds =
    guildColumn True route localUser dmChannels discordDmChannels guilds discordGuilds False


guildColumnCannotScrollNotMobile :
    Route
    -> LocalUser
    -> SeqDict (Id UserId) FrontendDmChannel
    -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel
    -> SeqDict (Id GuildId) FrontendGuild
    -> SeqDict (Discord.Id Discord.GuildId) DiscordFrontendGuild
    -> Element FrontendMsg
guildColumnCannotScrollNotMobile route localUser dmChannels discordDmChannels guilds discordGuilds =
    guildColumn False route localUser dmChannels discordDmChannels guilds discordGuilds False


dmChannelView : DmRouteData -> LoggedIn2 -> LocalState -> LoadedFrontend -> Element FrontendMsg
dmChannelView dmRoute loggedIn local model =
    case DmChannel.otherUserId local.localUser.session.userId dmRoute.channelId of
        Nothing ->
            Ui.el
                [ Ui.centerY
                , Ui.Font.center
                , Ui.Font.color MyUi.font1
                , Ui.Font.size 20
                ]
                (Ui.text "Conversation not found")

        Just otherUserId ->
            case User.getUser otherUserId local.localUser of
                Just otherUser ->
                    let
                        dmChannel : FrontendDmChannel
                        dmChannel =
                            SeqDict.get otherUserId local.dmChannels
                                |> Maybe.withDefault DmChannel.frontendInit
                    in
                    case dmRoute.threadRoute of
                        ViewThreadWithFriends threadMessageIndex maybeUrlMessageId _ ->
                            SeqDict.get threadMessageIndex dmChannel.threads
                                |> Maybe.withDefault Thread.frontendInit
                                |> threadConversationView
                                    (SeqDict.get
                                        ( GuildOrDmId (GuildOrDmId_Dm otherUserId), threadMessageIndex )
                                        local.localUser.user.lastViewedThreads
                                        |> Maybe.withDefault (Id.fromInt -1)
                                        |> Id.changeType
                                    )
                                    (GuildOrDmId_Dm otherUserId)
                                    maybeUrlMessageId
                                    threadMessageIndex
                                    loggedIn
                                    model
                                    local
                                    (PersonName.toString otherUser.name)

                        NoThreadWithFriends maybeUrlMessageId _ ->
                            conversationView
                                (SeqDict.get
                                    (GuildOrDmId (GuildOrDmId_Dm otherUserId))
                                    local.localUser.user.lastViewed
                                    |> Maybe.withDefault (Id.fromInt -1)
                                )
                                (GuildOrDmId_Dm otherUserId)
                                maybeUrlMessageId
                                loggedIn
                                model
                                local
                                (PersonName.toString otherUser.name)
                                dmChannel

                Nothing ->
                    Ui.el
                        [ Ui.centerY
                        , Ui.Font.center
                        , Ui.Font.color MyUi.font1
                        , Ui.Font.size 20
                        ]
                        (Ui.text "User not found")


discordDmChannelView :
    DiscordDmRouteData
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> Element FrontendMsg
discordDmChannelView routeData loggedIn local model =
    case SeqDict.get routeData.channelId local.discordDmChannels of
        Just dmChannel ->
            discordConversationView
                (SeqDict.get
                    (DiscordGuildOrDmId
                        (DiscordGuildOrDmId_Dm
                            { currentUserId = routeData.currentDiscordUserId, channelId = routeData.channelId }
                        )
                    )
                    local.localUser.user.lastViewed
                    |> Maybe.withDefault (Id.fromInt -1)
                )
                routeData.currentDiscordUserId
                (DiscordGuildOrDmId_Dm
                    { currentUserId = routeData.currentDiscordUserId, channelId = routeData.channelId }
                )
                routeData.viewingMessage
                loggedIn
                model
                local
                (NonemptyDict.toSeqDict dmChannel.members
                    |> SeqDict.remove routeData.currentDiscordUserId
                    |> SeqDict.toList
                    |> List.filterMap
                        (\( userId, _ ) ->
                            case User.getDiscordUser userId local.localUser of
                                Just user ->
                                    PersonName.toString user.name |> Just

                                Nothing ->
                                    Nothing
                        )
                    |> String.join ", "
                )
                { messages = dmChannel.messages
                , visibleMessages = dmChannel.visibleMessages
                , lastTypedAt = dmChannel.lastTypedAt
                , threads = SeqDict.empty
                , dateDividerDrawings = dmChannel.dateDividerDrawings
                }
                SeqSet.empty
                SeqSet.empty

        Nothing ->
            Ui.el
                [ Ui.centerY
                , Ui.Font.center
                , Ui.Font.color MyUi.font1
                , Ui.Font.size 20
                ]
                (Ui.text "DM channel not found")


conversationWidth : LoadedFrontend -> Int
conversationWidth model =
    if MyUi.isMobile model then
        Coord.xRaw model.windowSize
            - (User.profileImageSize
                + (messagePaddingX * 2)
                + profileImagePaddingRight
                + model.scrollbarWidth
              )

    else
        Coord.xRaw model.windowSize
            - ((GuildIcon.fullWidth + 1)
                + MyUi.channelColumnWidth model.windowSize
                + memberColumnWidth
                + User.profileImageSize
                + (messagePaddingX * 2)
                + profileImagePaddingRight
                + model.scrollbarWidth
              )


guildView : LoadedFrontend -> Id GuildId -> ChannelRoute -> LoggedIn2 -> LocalState -> Element FrontendMsg
guildView model guildId channelRoute loggedIn local =
    case ( loggedIn.showFileToUploadInfo, loggedIn.newGuildForm ) of
        ( Just fileData, _ ) ->
            FileStatus.imageInfoView PressedCloseImageInfo fileData

        ( Nothing, Just form ) ->
            newGuildFormView form

        ( Nothing, Nothing ) ->
            case SeqDict.get guildId local.guilds of
                Just guild ->
                    if MyUi.isMobile model then
                        let
                            canScroll2 =
                                canScroll model.drag

                            showMembers : ShowMembersTab
                            showMembers =
                                case channelRoute of
                                    ChannelRoute _ threadRoute _ ->
                                        case threadRoute of
                                            ViewThreadWithFriends _ _ showMembers2 ->
                                                showMembers2

                                            NoThreadWithFriends _ showMembers2 ->
                                                showMembers2

                                    _ ->
                                        HideMembersTab
                        in
                        Ui.column
                            [ Ui.height Ui.fill
                            , Ui.background MyUi.background1
                            , Ui.heightMin 0
                            , Ui.clip
                            , (case showMembers of
                                ShowMembersTab ->
                                    Ui.Lazy.lazy3
                                        memberColumnMobile
                                        canScroll2
                                        local.localUser
                                        guild.membersAndOwner
                                        |> Ui.el
                                            [ Ui.height Ui.fill
                                            , Ui.background MyUi.background3
                                            , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 0 0")
                                            , Ui.move
                                                { x = Call.sidebarOffsetAttr loggedIn.sidebarMode model
                                                , y = 0
                                                , z = 0
                                                }
                                            , Ui.heightMin 0
                                            ]

                                HideMembersTab ->
                                    Ui.none
                              )
                                |> Ui.inFront
                            , channelView channelRoute guildId guild loggedIn local model
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , Ui.background MyUi.background3
                                    , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 0 0")
                                    , case showMembers of
                                        ShowMembersTab ->
                                            Ui.noAttr

                                        HideMembersTab ->
                                            Ui.move
                                                { x = Call.sidebarOffsetAttr loggedIn.sidebarMode model
                                                , y = 0
                                                , z = 0
                                                }
                                    , Ui.heightMin 0
                                    ]
                                |> Ui.inFront
                            ]
                            [ Ui.row
                                [ Ui.height Ui.fill, Ui.heightMin 0 ]
                                [ guildColumnLazy True model local
                                , Ui.Lazy.lazy6
                                    (if canScroll2 then
                                        channelColumnCanScrollMobile

                                     else
                                        channelColumnCannotScrollMobile
                                    )
                                    local.localUser
                                    (nearestHour model.time)
                                    guildId
                                    guild
                                    channelRoute
                                    loggedIn.channelNameHover
                                ]
                            , Ui.Lazy.lazy loggedInAsView local.localUser
                            ]

                    else
                        Ui.row
                            [ Ui.height Ui.fill, Ui.background MyUi.background1 ]
                            [ Ui.column
                                [ Ui.height Ui.fill
                                , Ui.width (Ui.px (MyUi.channelAndGuildColumnWidth model.windowSize))
                                ]
                                [ Ui.row
                                    [ Ui.height Ui.fill, Ui.heightMin 0 ]
                                    [ guildColumnLazy False model local
                                    , Ui.Lazy.lazy6
                                        channelColumnNotMobile
                                        local.localUser
                                        (nearestHour model.time)
                                        guildId
                                        guild
                                        channelRoute
                                        loggedIn.channelNameHover
                                    ]
                                , Ui.Lazy.lazy loggedInAsView local.localUser
                                ]
                            , channelView channelRoute guildId guild loggedIn local model
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , Ui.background MyUi.background3
                                    , Ui.heightMin 0
                                    , Ui.borderColor MyUi.border1
                                    , Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                                    ]
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , MyUi.htmlStyle "padding-top" MyUi.insetTop
                                    ]
                            , Ui.Lazy.lazy2 memberColumnNotMobile local.localUser guild.membersAndOwner
                                |> Ui.el
                                    [ Ui.width Ui.shrink
                                    , Ui.height Ui.fill
                                    , MyUi.htmlStyle "padding-top" MyUi.insetTop
                                    ]
                            ]

                Nothing ->
                    if MyUi.isMobile model then
                        Ui.column
                            [ Ui.height Ui.fill
                            , Ui.background MyUi.background1
                            , Ui.heightMin 0
                            , Ui.clip
                            ]
                            [ Ui.row
                                [ Ui.height Ui.fill, Ui.heightMin 0 ]
                                [ guildColumnLazy True model local
                                , pageMissingMobile "Guild not found"
                                ]
                            , Ui.Lazy.lazy loggedInAsView local.localUser
                            ]

                    else
                        Ui.row
                            [ Ui.height Ui.fill, Ui.background MyUi.background1 ]
                            [ Ui.column
                                [ Ui.height Ui.fill
                                , Ui.width (Ui.px (MyUi.channelAndGuildColumnWidth model.windowSize))
                                ]
                                [ Ui.row
                                    [ Ui.height Ui.fill, Ui.heightMin 0 ]
                                    [ guildColumnLazy False model local
                                    , Ui.el
                                        [ Ui.background MyUi.background2
                                        , Ui.height Ui.fill
                                        , Ui.borderWith { left = 1, right = 0, top = 0, bottom = 0 }
                                        , Ui.borderColor MyUi.border1
                                        ]
                                        Ui.none
                                    ]
                                , Ui.Lazy.lazy loggedInAsView local.localUser
                                ]
                            , pageMissing "Guild not found"
                            ]


nearestHour : Time.Posix -> Int
nearestHour time =
    Time.posixToMillis time // (60 * 60 * 1000) |> (*) (60 * 60 * 1000)


discordGuildView :
    LoadedFrontend
    -> DiscordGuildRouteData
    -> LoggedIn2
    -> LocalState
    -> Element FrontendMsg
discordGuildView model routeData loggedIn local =
    case ( loggedIn.showFileToUploadInfo, loggedIn.newGuildForm ) of
        ( Just fileData, _ ) ->
            FileStatus.imageInfoView PressedCloseImageInfo fileData

        ( Nothing, Just form ) ->
            newGuildFormView form

        ( Nothing, Nothing ) ->
            case
                ( SeqDict.get routeData.guildId local.discordGuilds
                , LinkedAndOtherDiscordUsers.getLinkedUser routeData.currentDiscordUserId local.localUser.discordUsers
                )
            of
                ( Just guild, Just currentDiscordUser ) ->
                    if MembersAndOwner.isMember routeData.currentDiscordUserId guild.membersAndOwner == IsNotMember then
                        guildErrorPage
                            ("Selected Discord user ("
                                ++ PersonName.toString currentDiscordUser.name
                                ++ ") is not a member of this guild"
                            )
                            local
                            model

                    else if MyUi.isMobile model then
                        let
                            canScroll2 =
                                canScroll model.drag

                            showMembers : ShowMembersTab
                            showMembers =
                                case routeData.channelRoute of
                                    DiscordChannel_ChannelRoute _ threadRoute _ ->
                                        case threadRoute of
                                            ViewThreadWithFriends _ _ showMembers2 ->
                                                showMembers2

                                            NoThreadWithFriends _ showMembers2 ->
                                                showMembers2

                                    _ ->
                                        HideMembersTab
                        in
                        Ui.column
                            [ Ui.height Ui.fill
                            , Ui.background MyUi.background1
                            , Ui.heightMin 0
                            , Ui.clip
                            , (case showMembers of
                                ShowMembersTab ->
                                    Ui.Lazy.lazy4
                                        discordMemberColumnMobile
                                        canScroll2
                                        local.localUser
                                        routeData.currentDiscordUserId
                                        guild.membersAndOwner
                                        |> Ui.el
                                            [ Ui.height Ui.fill
                                            , Ui.background MyUi.background3
                                            , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 0 0")
                                            , Ui.move
                                                { x = Call.sidebarOffsetAttr loggedIn.sidebarMode model
                                                , y = 0
                                                , z = 0
                                                }
                                            , Ui.heightMin 0
                                            ]

                                HideMembersTab ->
                                    Ui.none
                              )
                                |> Ui.inFront
                            , discordChannelView routeData guild loggedIn local model
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , Ui.background MyUi.background3
                                    , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 0 0")
                                    , case showMembers of
                                        ShowMembersTab ->
                                            Ui.noAttr

                                        HideMembersTab ->
                                            Ui.move
                                                { x = Call.sidebarOffsetAttr loggedIn.sidebarMode model
                                                , y = 0
                                                , z = 0
                                                }
                                    , Ui.heightMin 0
                                    ]
                                |> Ui.inFront
                            ]
                            [ Ui.row
                                [ Ui.height Ui.fill, Ui.heightMin 0 ]
                                [ guildColumnLazy True model local
                                , Ui.Lazy.lazy5
                                    (if canScroll2 then
                                        discordChannelColumnCanScrollMobile

                                     else
                                        discordChannelColumnCannotScrollMobile
                                    )
                                    (nearestHour model.time)
                                    local.localUser
                                    routeData
                                    guild
                                    loggedIn.channelNameHover
                                ]
                            , Ui.Lazy.lazy loggedInAsView local.localUser
                            ]

                    else
                        Ui.row
                            [ Ui.height Ui.fill, Ui.background MyUi.background1 ]
                            [ Ui.column
                                [ Ui.height Ui.fill
                                , Ui.width (Ui.px (MyUi.channelAndGuildColumnWidth model.windowSize))
                                ]
                                [ Ui.row
                                    [ Ui.height Ui.fill, Ui.heightMin 0 ]
                                    [ guildColumnLazy False model local
                                    , Ui.Lazy.lazy5
                                        discordChannelColumnNotMobile
                                        (nearestHour model.time)
                                        local.localUser
                                        routeData
                                        guild
                                        loggedIn.channelNameHover
                                    ]
                                , Ui.Lazy.lazy loggedInAsView local.localUser
                                ]
                            , discordChannelView routeData guild loggedIn local model
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , Ui.background MyUi.background3
                                    , Ui.heightMin 0
                                    , Ui.borderColor MyUi.border1
                                    , Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                                    ]
                                |> Ui.el
                                    [ Ui.height Ui.fill
                                    , MyUi.htmlStyle "padding-top" MyUi.insetTop
                                    ]
                            , Ui.Lazy.lazy3
                                discordMemberColumnNotMobile
                                local.localUser
                                routeData.currentDiscordUserId
                                guild.membersAndOwner
                                |> Ui.el
                                    [ Ui.width Ui.shrink
                                    , Ui.height Ui.fill
                                    , MyUi.htmlStyle "padding-top" MyUi.insetTop
                                    ]
                            ]

                ( Just _, Nothing ) ->
                    guildErrorPage "Discord user not found" local model

                ( Nothing, _ ) ->
                    guildErrorPage "Discord guild not found" local model


guildErrorPage : String -> LocalState -> LoadedFrontend -> Element FrontendMsg
guildErrorPage error local model =
    if MyUi.isMobile model then
        Ui.column
            [ Ui.height Ui.fill
            , Ui.background MyUi.background1
            , Ui.heightMin 0
            , Ui.clip
            ]
            [ Ui.row
                [ Ui.height Ui.fill, Ui.heightMin 0 ]
                [ guildColumnLazy True model local
                , pageMissingMobile error
                ]
            , Ui.Lazy.lazy loggedInAsView local.localUser
            ]

    else
        Ui.row
            [ Ui.height Ui.fill, Ui.background MyUi.background1 ]
            [ Ui.column
                [ Ui.height Ui.fill
                , Ui.width (Ui.px (MyUi.channelAndGuildColumnWidth model.windowSize))
                ]
                [ Ui.row
                    [ Ui.height Ui.fill, Ui.heightMin 0 ]
                    [ guildColumnLazy False model local
                    , Ui.el
                        [ Ui.background MyUi.background2
                        , Ui.height Ui.fill
                        , Ui.borderWith { left = 1, right = 0, top = 0, bottom = 0 }
                        , Ui.borderColor MyUi.border1
                        ]
                        Ui.none
                    ]
                , Ui.Lazy.lazy loggedInAsView local.localUser
                ]
            , pageMissing error
            ]


memberColumnWidth : number
memberColumnWidth =
    200


memberColumnNotMobile : LocalUser -> MembersAndOwner (Id UserId) { joinedAt : Time.Posix } -> Element FrontendMsg
memberColumnNotMobile localUser membersAndOwner =
    let
        _ =
            Debug.log "rerendered memberColumn" ()

        members : SeqDict (Id UserId) { joinedAt : Time.Posix }
        members =
            MembersAndOwner.members membersAndOwner
    in
    Ui.column
        [ Ui.height Ui.fill
        , Ui.alignRight
        , Ui.background MyUi.background2
        , Ui.Font.color MyUi.font1
        , Ui.width (Ui.px memberColumnWidth)
        , Ui.scrollable
        , Ui.heightMin 0
        ]
        [ Ui.column
            [ Ui.paddingXY 8 4 ]
            [ Ui.text "Owner"
            , memberLabel False localUser (MembersAndOwner.owner membersAndOwner)
            ]
        , Ui.column
            [ Ui.paddingXY 8 4 ]
            [ Ui.text ("Members (" ++ String.fromInt (SeqDict.size members) ++ ")")
            , Ui.column
                [ Ui.height Ui.fill ]
                (SeqDict.foldr (\userId _ list -> memberLabel False localUser userId :: list) [] members)
            ]
        ]


discordMemberColumnNotMobile :
    LocalUser
    -> Discord.Id Discord.UserId
    -> MembersAndOwner (Discord.Id Discord.UserId) { joinedAt : Maybe Time.Posix }
    -> Element FrontendMsg
discordMemberColumnNotMobile localUser currentDiscordUserId membersAndOwner =
    let
        _ =
            Debug.log "rerendered memberColumn" ()

        members : SeqDict (Discord.Id Discord.UserId) { joinedAt : Maybe Time.Posix }
        members =
            MembersAndOwner.members membersAndOwner
    in
    Ui.column
        [ Ui.height Ui.fill
        , Ui.alignRight
        , Ui.background MyUi.background2
        , Ui.Font.color MyUi.font1
        , Ui.width (Ui.px memberColumnWidth)
        , Ui.scrollable
        , Ui.heightMin 0
        ]
        [ Ui.column
            [ Ui.paddingXY 8 4 ]
            [ Ui.text "Owner"
            , discordMemberLabel False localUser currentDiscordUserId (MembersAndOwner.owner membersAndOwner)
            , Ui.text ("Members (" ++ String.fromInt (SeqDict.size members) ++ ")")
            , Ui.column
                [ Ui.height Ui.fill ]
                (SeqDict.foldr
                    (\userId _ list -> discordMemberLabel False localUser currentDiscordUserId userId :: list)
                    []
                    members
                )
            ]
        ]


memberColumnMobile : Bool -> LocalUser -> MembersAndOwner (Id UserId) { joinedAt : Time.Posix } -> Element FrontendMsg
memberColumnMobile canScroll2 localUser membersAndOwner =
    let
        _ =
            Debug.log "rerendered memberColumn" ()

        members : SeqDict (Id UserId) { joinedAt : Time.Posix }
        members =
            MembersAndOwner.members membersAndOwner
    in
    Ui.column
        [ Ui.height Ui.fill ]
        [ Ui.row
            [ Ui.contentCenterY
            , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
            , Ui.borderColor MyUi.border2
            , Ui.background MyUi.background3
            , Ui.height (Ui.px MyUi.channelHeaderHeight)
            , MyUi.noShrinking
            ]
            [ ChannelHeader.headerBackButton (Dom.id "guild_memberColumnBack") PressedMemberListBack
            , Ui.el [ Ui.width (Ui.px 26), Ui.paddingRight 4 ] (Ui.html Icons.users)
            , Ui.text "Channel members"
            ]
        , Ui.column
            [ Ui.height Ui.fill
            , Ui.background MyUi.background2
            , Ui.Font.color MyUi.font1
            , MyUi.htmlStyle "padding" ("16px 0 calc(" ++ MyUi.insetBottom ++ " + 16px) 0")
            , scrollable canScroll2
            , Ui.heightMin 0
            ]
            [ Ui.column
                [ Ui.paddingXY 8 4 ]
                [ Ui.text "Owner"
                , memberLabel True localUser (MembersAndOwner.owner membersAndOwner)
                ]
            , Ui.column
                [ Ui.paddingXY 8 4 ]
                [ Ui.text ("Members (" ++ String.fromInt (SeqDict.size members) ++ ")")
                , Ui.column
                    [ Ui.height Ui.fill ]
                    (SeqDict.foldr (\userId _ list -> memberLabel True localUser userId :: list) [] members)
                ]
            ]
        ]


discordMemberColumnMobile :
    Bool
    -> LocalUser
    -> Discord.Id Discord.UserId
    -> MembersAndOwner (Discord.Id Discord.UserId) { joinedAt : Maybe Time.Posix }
    -> Element FrontendMsg
discordMemberColumnMobile canScroll2 localUser currentDiscordUserId membersAndOwner =
    let
        _ =
            Debug.log "rerendered memberColumn" ()

        members : SeqDict (Discord.Id Discord.UserId) { joinedAt : Maybe Time.Posix }
        members =
            MembersAndOwner.members membersAndOwner
    in
    Ui.column
        [ Ui.height Ui.fill ]
        [ Ui.row
            [ Ui.contentCenterY
            , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
            , Ui.borderColor MyUi.border2
            , Ui.background MyUi.background3
            , Ui.height (Ui.px MyUi.channelHeaderHeight)
            , MyUi.noShrinking
            ]
            [ ChannelHeader.headerBackButton (Dom.id "guild_memberColumnBack") PressedMemberListBack
            , Ui.el [ Ui.width (Ui.px 26), Ui.paddingRight 4 ] (Ui.html Icons.users)
            , Ui.text "Channel members"
            ]
        , Ui.column
            [ Ui.height Ui.fill
            , Ui.background MyUi.background2
            , Ui.Font.color MyUi.font1
            , MyUi.htmlStyle "padding" ("16px 0 calc(" ++ MyUi.insetBottom ++ " + 16px) 0")
            , scrollable canScroll2
            , Ui.heightMin 0
            ]
            [ Ui.column
                [ Ui.paddingXY 8 4 ]
                [ Ui.column
                    [ Ui.paddingXY 8 4 ]
                    [ Ui.text "Owner"
                    , discordMemberLabel False localUser currentDiscordUserId (MembersAndOwner.owner membersAndOwner)
                    ]
                , Ui.text ("Members (" ++ String.fromInt (SeqDict.size members) ++ ")")
                , Ui.column
                    [ Ui.height Ui.fill ]
                    (SeqDict.foldr
                        (\userId _ list -> discordMemberLabel True localUser currentDiscordUserId userId :: list)
                        []
                        members
                    )
                ]
            ]
        ]


memberLabel : Bool -> LocalUser -> Id UserId -> Element FrontendMsg
memberLabel isMobile localUser userId =
    rowLinkButton
        (Dom.id ("guild_openDm_" ++ Id.toString userId))
        (DmRoute
            { channelId = DmChannel.channelIdFromUserIds localUser.session.userId userId
            , threadRoute = NoThreadWithFriends Nothing HideMembersTab
            , tab = Nothing
            }
        )
        [ Ui.spacing 8
        , Ui.paddingXY 0 4
        , MyUi.hover
            isMobile
            [ Ui.Anim.backgroundColor (Ui.rgba 255 255 255 0.1)
            , Ui.Anim.fontColor MyUi.font1
            ]
        , Ui.Font.color MyUi.font3
        , Ui.clipWithEllipsis
        ]
        (case User.getUser userId localUser of
            Just user ->
                [ User.profileImage userId user.icon, Ui.text (PersonName.toString user.name) ]

            Nothing ->
                []
        )


discordMemberLabel :
    Bool
    -> LocalUser
    -> Discord.Id Discord.UserId
    -> Discord.Id Discord.UserId
    -> Element FrontendMsg
discordMemberLabel isMobile localUser currentUserId userId =
    MyUi.rowButton
        (Dom.id ("guild_openDiscordDm_" ++ Discord.idToString userId))
        (PressedDiscordGuildMemberLabel { currentUserId = currentUserId, otherUserId = userId })
        [ Ui.spacing 8
        , Ui.paddingXY 0 4
        , MyUi.hover
            isMobile
            [ Ui.Anim.backgroundColor (Ui.rgba 255 255 255 0.1)
            , Ui.Anim.fontColor MyUi.font1
            ]
        , Ui.Font.color MyUi.font3
        , Ui.clipWithEllipsis
        ]
        (case User.getDiscordUser userId localUser of
            Just user ->
                [ User.discordProfileImage userId user.icon, Ui.text (PersonName.toString user.name) ]

            Nothing ->
                []
        )


pageMissing : String -> Element msg
pageMissing text =
    Ui.el
        [ Ui.height Ui.fill
        , Ui.contentCenterY
        , Ui.Font.center
        , Ui.Font.color MyUi.font1
        , Ui.Font.size 20
        , Ui.background MyUi.background3
        ]
        (Ui.text text)


pageMissingMobile : String -> Element msg
pageMissingMobile text =
    Ui.el
        [ Ui.height Ui.fill
        , Ui.contentCenterY
        , Ui.Font.center
        , Ui.Font.color MyUi.font1
        , Ui.Font.size 20
        , Ui.background MyUi.background2
        ]
        (Ui.text text)


threadPreviewText :
    SeqDict userId { a | name : PersonName }
    -> Id ChannelMessageId
    -> { b | messages : Array (MessageState ChannelMessageId userId) }
    -> String
threadPreviewText allUsers threadMessageIndex channel =
    case IdArray.get threadMessageIndex channel.messages of
        Just (MessageLoaded message) ->
            LocalState.messageToString allUsers message

        _ ->
            "Thread not found"


channelView : ChannelRoute -> Id GuildId -> FrontendGuild -> LoggedIn2 -> LocalState -> LoadedFrontend -> Element FrontendMsg
channelView channelRoute guildId guild loggedIn local model =
    case channelRoute of
        ChannelRoute channelId threadRoute _ ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    case threadRoute of
                        ViewThreadWithFriends threadMessageIndex maybeUrlMessageId _ ->
                            SeqDict.get threadMessageIndex channel.threads
                                |> Maybe.withDefault Thread.frontendInit
                                |> threadConversationView
                                    (SeqDict.get
                                        ( GuildOrDmId (GuildOrDmId_Guild guildId channelId), threadMessageIndex )
                                        local.localUser.user.lastViewedThreads
                                        |> Maybe.withDefault (Id.fromInt -1)
                                        |> Id.changeType
                                    )
                                    (GuildOrDmId_Guild guildId channelId)
                                    maybeUrlMessageId
                                    threadMessageIndex
                                    loggedIn
                                    model
                                    local
                                    (ChannelName.toString channel.name
                                        ++ " / "
                                        ++ threadPreviewText
                                            (LocalState.allUsers local.localUser)
                                            threadMessageIndex
                                            channel
                                    )

                        NoThreadWithFriends maybeUrlMessageId _ ->
                            conversationView
                                (SeqDict.get
                                    (GuildOrDmId (GuildOrDmId_Guild guildId channelId))
                                    local.localUser.user.lastViewed
                                    |> Maybe.withDefault (Id.fromInt -1)
                                )
                                (GuildOrDmId_Guild guildId channelId)
                                maybeUrlMessageId
                                loggedIn
                                model
                                local
                                (ChannelName.toString channel.name)
                                channel

                Nothing ->
                    pageMissing "Channel does not exist"

        NewChannelRoute ->
            SeqDict.get guildId loggedIn.newChannelForm
                |> Maybe.withDefault newChannelFormInit
                |> newChannelFormView (MyUi.isMobile model) guildId

        EditChannelRoute channelId ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    editChannelFormView
                        (MyUi.isMobile model)
                        guildId
                        channelId
                        channel
                        (SeqDict.get ( guildId, channelId ) loggedIn.editChannelForm
                            |> Maybe.withDefault (editChannelFormInit channel)
                        )

                Nothing ->
                    pageMissing "Channel does not exist"

        GuildSettingsRoute ->
            guildSettingsForm model loggedIn local guildId guild

        JoinRoute _ ->
            Ui.none


discordChannelView : DiscordGuildRouteData -> DiscordFrontendGuild -> LoggedIn2 -> LocalState -> LoadedFrontend -> Element FrontendMsg
discordChannelView routeData guild loggedIn local model =
    case routeData.channelRoute of
        DiscordChannel_ChannelRoute channelId threadRoute _ ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    let
                        ( availableCustomEmojis, availableStickers ) =
                            LocalState.discordGuildAvailableStickersAndCustomEmojis local.localUser guild
                    in
                    case threadRoute of
                        ViewThreadWithFriends threadMessageIndex maybeUrlMessageId _ ->
                            SeqDict.get threadMessageIndex channel.threads
                                |> Maybe.withDefault Thread.discordFrontendInit
                                |> discordThreadConversationView
                                    (SeqDict.get
                                        ( DiscordGuildOrDmId
                                            (DiscordGuildOrDmId_Guild routeData.currentDiscordUserId routeData.guildId channelId)
                                        , threadMessageIndex
                                        )
                                        local.localUser.user.lastViewedThreads
                                        |> Maybe.withDefault (Id.fromInt -1)
                                        |> Id.changeType
                                    )
                                    routeData.currentDiscordUserId
                                    (DiscordGuildOrDmId_Guild routeData.currentDiscordUserId routeData.guildId channelId)
                                    maybeUrlMessageId
                                    threadMessageIndex
                                    loggedIn
                                    model
                                    local
                                    (ChannelName.toString channel.name
                                        ++ " / "
                                        ++ threadPreviewText
                                            (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                                            threadMessageIndex
                                            channel
                                    )
                                    availableCustomEmojis
                                    availableStickers

                        NoThreadWithFriends maybeUrlMessageId _ ->
                            discordConversationView
                                (SeqDict.get
                                    (DiscordGuildOrDmId (DiscordGuildOrDmId_Guild routeData.currentDiscordUserId routeData.guildId channelId))
                                    local.localUser.user.lastViewed
                                    |> Maybe.withDefault (Id.fromInt -1)
                                )
                                routeData.currentDiscordUserId
                                (DiscordGuildOrDmId_Guild routeData.currentDiscordUserId routeData.guildId channelId)
                                maybeUrlMessageId
                                loggedIn
                                model
                                local
                                (ChannelName.toString channel.name)
                                channel
                                availableCustomEmojis
                                availableStickers

                Nothing ->
                    pageMissing "Channel does not exist"

        DiscordChannel_NewChannelRoute ->
            pageMissing "Adding Discord channels not supported yet"

        DiscordChannel_EditChannelRoute channelId ->
            case SeqDict.get channelId guild.channels of
                Just _ ->
                    pageMissing "Editing Discord channels not supported yet"

                Nothing ->
                    pageMissing "Channel does not exist"

        DiscordChannel_GuildSettingsRoute ->
            discordGuildSettingsView routeData.currentDiscordUserId routeData.guildId local


discordGuildSettingsView : Discord.Id Discord.UserId -> Discord.Id Discord.GuildId -> LocalState -> Element FrontendMsg
discordGuildSettingsView userId guildId local =
    Ui.el
        [ Ui.height Ui.fill ]
        (Ui.column
            [ Ui.Font.color MyUi.font1
            , Ui.alignTop
            , Ui.spacing 16
            , Ui.padding 16
            ]
            [ Ui.el [ Ui.Font.bold, Ui.Font.size 20 ] (Ui.text "Discord Guild Settings")
            , Ui.el
                [ Ui.paddingXY 16 0 ]
                (MyUi.radioColumn
                    (Dom.id "guild_discordNotificationLevel")
                    (PressedDiscordGuildNotificationLevel userId guildId)
                    (if SeqSet.member guildId local.localUser.user.discordNotifyOnAllMessages then
                        Just NotifyOnEveryMessage

                     else
                        Just NotifyOnMention
                    )
                    "Guild notifications"
                    [ ( NotifyOnMention, "Only when mentioned" )
                    , ( NotifyOnEveryMessage, "On every message" )
                    ]
                )
            ]
        )


guildSettingsForm : LoadedFrontend -> LoggedIn2 -> LocalState -> Id GuildId -> FrontendGuild -> Element FrontendMsg
guildSettingsForm model loggedIn local guildId guild =
    let
        isMobile =
            MyUi.isMobile model

        isOwner : Bool
        isOwner =
            MembersAndOwner.owner guild.membersAndOwner == local.localUser.session.userId

        guildIconEditor : ImageEditor.Model
        guildIconEditor =
            case loggedIn.guildIconEditor of
                Just ( existingGuildId, editor ) ->
                    if existingGuildId == guildId then
                        editor

                    else
                        ImageEditor.init

                Nothing ->
                    ImageEditor.init
    in
    Ui.el
        [ Ui.height Ui.fill ]
        (Ui.column
            [ Ui.Font.color MyUi.font1
            , Ui.alignTop
            , Ui.spacing 16
            , scrollable (canScroll model.drag)
            ]
            [ ChannelHeader.channelHeader isMobile False (Ui.text "Guild settings") Nothing
            , if isOwner then
                Ui.column
                    [ Ui.spacing 8, Ui.paddingXY 16 0 ]
                    [ Ui.el [ Ui.Font.bold ] (Ui.text "Guild icon")
                    , Ui.row
                        [ Ui.spacing 12, Ui.alignLeft ]
                        [ GuildIcon.view (GuildIcon.Normal NoNotification) guild
                        , ImageEditor.view model.windowSize guildIconEditor
                            |> Ui.map (GuildIconEditorMsg guildId)
                        ]
                    ]

              else
                Ui.none
            , Ui.el
                [ Ui.paddingXY 16 0 ]
                (submitButton (Dom.id "guild_createInviteLink") (PressedCreateInviteLink guildId) "Create invite link")
            , if SeqDict.isEmpty guild.invites then
                Ui.none

              else
                Ui.el [ Ui.Font.bold, Ui.paddingXY 16 0 ] (Ui.text "Existing invites")
            , Ui.column
                [ Ui.spacing 8, Ui.paddingXY 16 0 ]
                (SeqDict.toList guild.invites
                    |> List.sortBy (\( _, data ) -> -(Time.posixToMillis data.createdAt))
                    |> List.map
                        (\( inviteId, data ) ->
                            let
                                url : String
                                url =
                                    Route.encode (GuildRoute guildId (JoinRoute inviteId))

                                inviteLink : String
                                inviteLink =
                                    Env.domain ++ url

                                showQrCode : Bool
                                showQrCode =
                                    Just inviteId == loggedIn.showInviteLinkQrCode
                            in
                            Ui.column
                                [ Ui.spacing 8 ]
                                [ Ui.row
                                    [ Ui.spacing 16 ]
                                    [ Ui.el [ Ui.widthMax 300 ] (copyableText inviteLink model)
                                    , MyUi.elButton
                                        (Dom.id ("guild_inviteLinkQrCode_" ++ SecretId.toString inviteId))
                                        (PressedToggleInviteLinkQrCode inviteId)
                                        [ Ui.Font.color MyUi.font2
                                        , Ui.rounded 4
                                        , Ui.border 1
                                        , Ui.borderColor MyUi.inputBorder
                                        , Ui.paddingXY 6 0
                                        , Ui.width Ui.shrink
                                        , Ui.height Ui.fill
                                        , Ui.contentCenterY
                                        , Ui.Font.size 14
                                        ]
                                        (Ui.text
                                            (if showQrCode then
                                                "Hide QR code"

                                             else
                                                "Show QR code"
                                            )
                                        )
                                    , if isOwner then
                                        MyUi.deleteButton
                                            (Dom.id ("guild_deleteInviteLink_" ++ SecretId.toString inviteId))
                                            (PressedDeleteInviteLink guildId inviteId)

                                      else
                                        Ui.none
                                    , if Duration.from data.createdAt model.time |> Quantity.lessThan (Duration.minutes 5) then
                                        Ui.text "Created just now!"

                                      else
                                        Ui.none
                                    ]
                                , if showQrCode then
                                    Ui.Lazy.lazy2 inviteLinkQrCodeView (conversationWidth model) inviteLink

                                  else
                                    Ui.none
                                ]
                        )
                )
            , Ui.el
                [ Ui.paddingXY 16 0 ]
                (MyUi.radioColumn
                    (Dom.id "guild_notificationLevel")
                    (PressedGuildNotificationLevel guildId)
                    (if SeqSet.member guildId local.localUser.user.notifyOnAllMessages then
                        Just NotifyOnEveryMessage

                     else
                        Just NotifyOnMention
                    )
                    "Guild notifications"
                    [ ( NotifyOnMention, "Only when mentioned" )
                    , ( NotifyOnEveryMessage, "On every message" )
                    ]
                )
            , if isOwner then
                deleteGuildSection guildId
                    guild
                    (SeqDict.get guildId loggedIn.editGuildForm
                        |> Maybe.withDefault editGuildFormInit
                    )

              else
                Ui.none
            ]
        )


editGuildFormInit : EditGuildForm
editGuildFormInit =
    { deleteConfirmation = "", showDeleteConfirmation = False }


deleteGuildSection : Id GuildId -> FrontendGuild -> EditGuildForm -> Element FrontendMsg
deleteGuildSection guildId guild form =
    let
        guildNameString : String
        guildNameString =
            GuildName.toString guild.name

        confirmationMatches : Bool
        confirmationMatches =
            form.deleteConfirmation == guildNameString

        ( deleteOnPress, deleteEnabled ) =
            if not form.showDeleteConfirmation then
                ( EditGuildFormChanged guildId { form | showDeleteConfirmation = True }, True )

            else if confirmationMatches then
                ( PressedDeleteGuild guildId, True )

            else
                ( FrontendNoOp, False )
    in
    Ui.column
        [ Ui.spacing 12, Ui.paddingXY 16 0 ]
        [ Ui.el [ Ui.height (Ui.px 1), Ui.background MyUi.border2 ] Ui.none
        , if form.showDeleteConfirmation then
            deleteGuildConfirmationInput guildId guildNameString form

          else
            Ui.none
        , MyUi.elButton
            (Dom.id "guild_deleteGuild")
            deleteOnPress
            [ Ui.paddingXY 16 8
            , Ui.background
                (if deleteEnabled then
                    MyUi.deleteButtonBackground

                 else
                    MyUi.disabledButtonBackground
                )
            , Ui.width Ui.shrink
            , Ui.rounded 8
            , Ui.Font.color MyUi.deleteButtonFont
            , Ui.Font.bold
            , Ui.borderColor MyUi.buttonBorder
            , Ui.border 1
            ]
            (Ui.text "Delete guild")
        ]


deleteGuildConfirmationInput : Id GuildId -> String -> EditGuildForm -> Element FrontendMsg
deleteGuildConfirmationInput guildId guildNameString form =
    let
        confirmLabel =
            Ui.Input.label
                "deleteGuildConfirmation"
                [ Ui.Font.color MyUi.font2, Ui.paddingXY 2 0 ]
                (Ui.text ("Type \"" ++ guildNameString ++ "\" to confirm deletion"))
    in
    Ui.column
        []
        [ confirmLabel.element
        , Ui.Input.text
            [ Ui.padding 6
            , Ui.background MyUi.inputBackground
            , Ui.borderColor MyUi.inputBorder
            , Ui.widthMax 500
            ]
            { onChange = \text -> EditGuildFormChanged guildId { form | deleteConfirmation = text }
            , text = form.deleteConfirmation
            , placeholder = Nothing
            , label = confirmLabel.id
            }
        ]


inviteLinkQrCodeView : Int -> String -> Element msg
inviteLinkQrCodeView containerWidth inviteLink =
    case QRCode.fromString inviteLink of
        Ok qrCode ->
            let
                size =
                    min 300 containerWidth
            in
            Ui.el
                [ Ui.background MyUi.white
                , Ui.padding 12
                , Ui.rounded 8
                , Ui.width Ui.shrink
                ]
                (QRCode.toSvgWithoutQuietZone
                    [ MyUi.widthAttr size, MyUi.heightAttr size ]
                    qrCode
                    |> Ui.html
                )

        Err _ ->
            Ui.none


copyableText : String -> LoadedFrontend -> Element FrontendMsg
copyableText text model =
    let
        isCopied : Bool
        isCopied =
            case model.lastCopied of
                Just copied ->
                    (copied.copied == CopiedText text)
                        && (Duration.from copied.copiedAt model.time
                                |> Quantity.lessThan (Duration.seconds 10)
                           )

                Nothing ->
                    False
    in
    Ui.row
        []
        [ Ui.Input.text
            [ Ui.roundedWith { topLeft = 4, bottomLeft = 4, topRight = 0, bottomRight = 0 }
            , Ui.border 1
            , Ui.borderColor MyUi.inputBorder
            , Ui.paddingXY 4 4
            , Ui.background MyUi.inputBackground
            ]
            { text = text
            , onChange = \_ -> FrontendNoOp
            , placeholder = Nothing
            , label = Ui.Input.labelHidden "Readonly text field"
            }
        , MyUi.elButton
            (Dom.id "guild_copyText")
            (PressedCopyText text)
            [ Ui.Font.color MyUi.font2
            , Ui.roundedWith { topRight = 4, bottomRight = 4, topLeft = 0, bottomLeft = 0 }
            , Ui.borderWith { left = 0, right = 1, top = 1, bottom = 1 }
            , Ui.borderColor MyUi.inputBorder
            , Ui.paddingXY 6 0
            , Ui.width Ui.shrink
            , Ui.height Ui.fill
            , Ui.contentCenterY
            , Ui.Font.size 14
            ]
            (if isCopied then
                Ui.text "Copied!"

             else
                Ui.el [ Ui.width (Ui.px 18) ] (Ui.html Icons.copyIcon)
            )
        ]


channelTextInputId : HtmlId
channelTextInputId =
    "channel_textinput" |> Dom.id


messageHover : AnyGuildOrDmId -> ThreadRouteWithMessage -> LoggedIn2 -> LoadedFrontend -> IsHovered
messageHover guildOrDmId threadRoute loggedIn model =
    case loggedIn.messageHover of
        MessageMenu messageMenu ->
            if guildOrDmId == messageMenu.guildOrDmId && threadRoute == messageMenu.threadRoute then
                IsHoveredButNoMenu

            else
                IsNotHovered

        MessageHover guildOrDmIdA threadRouteA ->
            if guildOrDmId == guildOrDmIdA then
                if threadRouteA == threadRoute then
                    if drawingIsSelectingAnchor loggedIn model then
                        IsHoveredWhileSelectingAnchor

                    else
                        IsHovered

                else
                    IsNotHovered

            else
                IsNotHovered

        _ ->
            IsNotHovered


conversationViewHelper :
    Id ChannelMessageId
    -> GuildOrDmId
    -> Maybe (Id ChannelMessageId)
    ->
        { a
            | messages : Array (MessageState ChannelMessageId (Id UserId))
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) FrontendThread
            , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
        }
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> List ( String, Element FrontendMsg )
conversationViewHelper lastViewedIndex guildOrDmIdNoThread maybeUrlMessageId channel loggedIn local model =
    let
        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( GuildOrDmId guildOrDmIdNoThread, NoThread )

        maybeEditing : Maybe EditMessage
        maybeEditing =
            SeqDict.get guildOrDmId loggedIn.editMessage

        othersEditing : SeqSet (Id ChannelMessageId)
        othersEditing =
            SeqDict.remove local.localUser.session.userId channel.lastTypedAt
                |> SeqDict.values
                |> List.filterMap
                    (\a ->
                        if Duration.from a.time model.time |> Quantity.lessThan (Duration.seconds 3) then
                            a.messageIndex

                        else
                            Nothing
                    )
                |> SeqSet.fromList

        replyToIndex : Maybe (Id ChannelMessageId)
        replyToIndex =
            SeqDict.get guildOrDmId loggedIn.replyTo

        revealedSpoilers : SeqDict (Id ChannelMessageId) (NonemptySet Int)
        revealedSpoilers =
            case loggedIn.revealedSpoilers of
                Just revealed ->
                    if revealed.guildOrDmId == guildOrDmId then
                        revealed.messages

                    else
                        SeqDict.empty

                Nothing ->
                    SeqDict.empty

        containerWidth : Int
        containerWidth =
            conversationWidth model

        isMobile : Bool
        isMobile =
            MyUi.isMobile model

        isSelectingAnchor =
            drawingIsSelectingAnchor loggedIn model
    in
    Array.foldr
        (\messageState ( index, maybeLastDate, list ) ->
            case messageState of
                MessageLoaded message ->
                    let
                        messageId : Id ChannelMessageId
                        messageId =
                            Id.fromInt index

                        threadRoute2 : ThreadRouteWithMessage
                        threadRoute2 =
                            NoThreadWithMessage messageId

                        threadId : Id ChannelMessageId
                        threadId =
                            Id.fromInt index

                        messageHover2 : IsHovered
                        messageHover2 =
                            messageHover (GuildOrDmId guildOrDmIdNoThread) threadRoute2 loggedIn model

                        otherUserIsEditing : Bool
                        otherUserIsEditing =
                            SeqSet.member (Id.changeType messageId) othersEditing

                        isEditing : Maybe EditMessage
                        isEditing =
                            case maybeEditing of
                                Just editing ->
                                    if editing.messageIndex == messageId then
                                        Just editing

                                    else
                                        Nothing

                                Nothing ->
                                    Nothing

                        highlight : HighlightMessage
                        highlight =
                            if maybeUrlMessageId == Just messageId then
                                UrlHighlight

                            else if replyToIndex == Just messageId then
                                ReplyToHighlight

                            else
                                NoHighlight

                        maybeRepliedTo2 : Maybe ( Id ChannelMessageId, Message ChannelMessageId (Id UserId) )
                        maybeRepliedTo2 =
                            maybeRepliedTo message channel

                        date : Date
                        date =
                            Message.createdAt message |> Date.fromPosix local.localUser.timezone
                    in
                    ( index - 1
                    , Just date
                    , ( String.fromInt index
                      , case isEditing of
                            Just edit ->
                                if MyUi.isMobile model then
                                    -- On mobile, we show the editor at the bottom instead
                                    messageView
                                        isMobile
                                        containerWidth
                                        False
                                        revealedSpoilers
                                        highlight
                                        messageHover2
                                        otherUserIsEditing
                                        local.localUser.session.userId
                                        (LocalState.allUsers local.localUser)
                                        local.localUser
                                        maybeRepliedTo2
                                        (SeqDict.get threadId channel.threads)
                                        messageId
                                        message
                                        |> Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                else
                                    let
                                        allUsers =
                                            LocalState.allUsers local.localUser

                                        editRichText : Maybe (Nonempty (RichText (Id UserId)))
                                        editRichText =
                                            case String.Nonempty.fromString edit.text of
                                                Just nonempty ->
                                                    RichText.fromNonemptyString allUsers nonempty |> Just

                                                Nothing ->
                                                    Nothing

                                        charsLeft =
                                            RichText.maxLength - String.length edit.text
                                    in
                                    messageEditingView
                                        isMobile
                                        guildOrDmId
                                        threadRoute2
                                        message
                                        maybeRepliedTo2
                                        (SeqDict.get threadId channel.threads)
                                        revealedSpoilers
                                        charsLeft
                                        edit
                                        editRichText
                                        loggedIn.textInputFocus
                                        local.localUser.session.userId
                                        allUsers
                                        local

                            Nothing ->
                                case SeqDict.get threadId channel.threads of
                                    Nothing ->
                                        case maybeRepliedTo2 of
                                            Just _ ->
                                                messageView
                                                    isMobile
                                                    containerWidth
                                                    False
                                                    revealedSpoilers
                                                    highlight
                                                    messageHover2
                                                    otherUserIsEditing
                                                    local.localUser.session.userId
                                                    (LocalState.allUsers local.localUser)
                                                    local.localUser
                                                    maybeRepliedTo2
                                                    Nothing
                                                    messageId
                                                    message
                                                    |> Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                            Nothing ->
                                                Ui.Lazy.lazy5
                                                    messageViewNotThreadStarter
                                                    (encodeMessageView isMobile messageHover2 containerWidth otherUserIsEditing highlight)
                                                    revealedSpoilers
                                                    local.localUser
                                                    index
                                                    message
                                                    |> Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                    Just thread ->
                                        case maybeRepliedTo2 of
                                            Just _ ->
                                                messageView
                                                    isMobile
                                                    containerWidth
                                                    False
                                                    revealedSpoilers
                                                    highlight
                                                    messageHover2
                                                    otherUserIsEditing
                                                    local.localUser.session.userId
                                                    (LocalState.allUsers local.localUser)
                                                    local.localUser
                                                    maybeRepliedTo2
                                                    (Just thread)
                                                    messageId
                                                    message
                                                    |> Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                            Nothing ->
                                                Ui.Lazy.lazy6
                                                    messageViewThreadStarter
                                                    (encodeMessageView isMobile messageHover2 containerWidth otherUserIsEditing highlight)
                                                    revealedSpoilers
                                                    local.localUser
                                                    index
                                                    thread
                                                    message
                                                    |> Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)
                      )
                        |> (\keyedMessage ->
                                keyedMessage
                                    :: List.map
                                        (Tuple.mapSecond (Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)))
                                        (newMessageLine
                                            Drawing.userColor
                                            isSelectingAnchor
                                            channel.dateDividerDrawings
                                            maybeLastDate
                                            date
                                            lastViewedIndex
                                            index
                                            messageId
                                        )
                                    ++ list
                           )
                    )

                MessageUnloaded ->
                    ( index - 1, maybeLastDate, ( String.fromInt index, unloadedMessageView index ) :: list )
        )
        ( Array.length channel.messages - 1, Nothing, [] )
        (VisibleMessages.slice channel)
        |> (\( _, _, a ) -> a)


maybeRepliedTo : Message messageId userId -> { a | messages : Array (MessageState messageId userId) } -> Maybe ( Id messageId, Message messageId userId )
maybeRepliedTo message channel =
    case message of
        UserTextMessage data ->
            case data.repliedTo of
                Just repliedToIndex ->
                    case IdArray.get repliedToIndex channel.messages of
                        Just (MessageLoaded message2) ->
                            Just ( repliedToIndex, message2 )

                        _ ->
                            Nothing

                Nothing ->
                    Nothing

        UserJoinedMessage _ _ _ _ ->
            Nothing

        DeletedMessage _ ->
            Nothing

        CallStarted _ _ _ _ _ ->
            Nothing

        GameStarted _ _ _ _ _ ->
            Nothing


drawingIsSelectingAnchor : LoggedIn2 -> LoadedFrontend -> Bool
drawingIsSelectingAnchor loggedIn model =
    loggedIn.drawingMode == Drawing.NoSelectedAnchor && Route.toChannelHeaderTab model.route == Just Route.DmChannelHeaderTab_Draw


discordConversationViewHelper :
    Id ChannelMessageId
    -> Discord.Id Discord.UserId
    -> DiscordGuildOrDmId
    -> Maybe (Id ChannelMessageId)
    ->
        { a
            | messages : Array (MessageState ChannelMessageId (Discord.Id Discord.UserId))
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) DiscordFrontendThread
            , dateDividerDrawings : SeqDict Date (Drawing (Discord.Id Discord.UserId))
        }
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> List ( String, Element FrontendMsg )
discordConversationViewHelper lastViewedIndex currentDiscordUserId guildOrDmIdNoThread maybeUrlMessageId channel loggedIn local model =
    let
        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( DiscordGuildOrDmId guildOrDmIdNoThread, NoThread )

        maybeEditing : Maybe EditMessage
        maybeEditing =
            SeqDict.get guildOrDmId loggedIn.editMessage

        othersEditing : SeqSet (Id ChannelMessageId)
        othersEditing =
            SeqDict.remove currentDiscordUserId channel.lastTypedAt
                |> SeqDict.values
                |> List.filterMap
                    (\a ->
                        if Duration.from a.time model.time |> Quantity.lessThan (Duration.seconds 3) then
                            a.messageIndex

                        else
                            Nothing
                    )
                |> SeqSet.fromList

        replyToIndex : Maybe (Id ChannelMessageId)
        replyToIndex =
            SeqDict.get guildOrDmId loggedIn.replyTo

        revealedSpoilers : SeqDict (Id ChannelMessageId) (NonemptySet Int)
        revealedSpoilers =
            case loggedIn.revealedSpoilers of
                Just revealed ->
                    if revealed.guildOrDmId == guildOrDmId then
                        revealed.messages

                    else
                        SeqDict.empty

                Nothing ->
                    SeqDict.empty

        containerWidth : Int
        containerWidth =
            conversationWidth model

        isMobile : Bool
        isMobile =
            MyUi.isMobile model

        isSelectingAnchor =
            drawingIsSelectingAnchor loggedIn model
    in
    Array.foldr
        (\messageState ( index, maybeLastDate, list ) ->
            case messageState of
                MessageLoaded message ->
                    let
                        messageId : Id ChannelMessageId
                        messageId =
                            Id.fromInt index

                        threadRoute2 : ThreadRouteWithMessage
                        threadRoute2 =
                            NoThreadWithMessage messageId

                        threadId : Id ChannelMessageId
                        threadId =
                            Id.fromInt index

                        messageHover2 : IsHovered
                        messageHover2 =
                            messageHover (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2 loggedIn model

                        otherUserIsEditing : Bool
                        otherUserIsEditing =
                            SeqSet.member (Id.changeType messageId) othersEditing

                        isEditing : Maybe EditMessage
                        isEditing =
                            case maybeEditing of
                                Just editing ->
                                    if editing.messageIndex == messageId then
                                        Just editing

                                    else
                                        Nothing

                                Nothing ->
                                    Nothing

                        highlight : HighlightMessage
                        highlight =
                            if maybeUrlMessageId == Just messageId then
                                UrlHighlight

                            else if replyToIndex == Just messageId then
                                ReplyToHighlight

                            else
                                NoHighlight

                        maybeRepliedTo2 =
                            maybeRepliedTo message channel

                        date : Date
                        date =
                            Message.createdAt message |> Date.fromPosix local.localUser.timezone
                    in
                    ( index - 1
                    , Just date
                    , ( String.fromInt index
                      , case isEditing of
                            Just edit ->
                                if MyUi.isMobile model then
                                    -- On mobile, we show the editor at the bottom instead
                                    discordMessageView
                                        isMobile
                                        containerWidth
                                        False
                                        revealedSpoilers
                                        highlight
                                        messageHover2
                                        currentDiscordUserId
                                        (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                                        local.localUser
                                        maybeRepliedTo2
                                        (SeqDict.get threadId channel.threads)
                                        messageId
                                        message
                                        |> Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                else
                                    let
                                        allUsers =
                                            LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers

                                        editRichText : Maybe (Nonempty (RichText (Discord.Id Discord.UserId)))
                                        editRichText =
                                            case String.Nonempty.fromString edit.text of
                                                Just nonempty ->
                                                    RichText.fromNonemptyString allUsers nonempty |> Just

                                                Nothing ->
                                                    Nothing
                                    in
                                    messageEditingView
                                        isMobile
                                        guildOrDmId
                                        threadRoute2
                                        message
                                        maybeRepliedTo2
                                        (SeqDict.get threadId channel.threads)
                                        revealedSpoilers
                                        (RichText.discordCharsLeft OneToOne.empty editRichText)
                                        edit
                                        editRichText
                                        loggedIn.textInputFocus
                                        currentDiscordUserId
                                        allUsers
                                        local

                            Nothing ->
                                case SeqDict.get threadId channel.threads of
                                    Nothing ->
                                        case maybeRepliedTo2 of
                                            Just _ ->
                                                discordMessageView
                                                    isMobile
                                                    containerWidth
                                                    False
                                                    revealedSpoilers
                                                    highlight
                                                    messageHover2
                                                    currentDiscordUserId
                                                    (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                                                    local.localUser
                                                    maybeRepliedTo2
                                                    Nothing
                                                    messageId
                                                    message
                                                    |> Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                            Nothing ->
                                                Ui.Lazy.lazy6
                                                    discordMessageViewNotThreadStarter
                                                    (encodeMessageView isMobile messageHover2 containerWidth otherUserIsEditing highlight)
                                                    revealedSpoilers
                                                    currentDiscordUserId
                                                    local.localUser
                                                    index
                                                    message
                                                    |> Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                    Just thread ->
                                        case maybeRepliedTo2 of
                                            Just _ ->
                                                discordMessageView
                                                    isMobile
                                                    containerWidth
                                                    False
                                                    revealedSpoilers
                                                    highlight
                                                    messageHover2
                                                    currentDiscordUserId
                                                    (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                                                    local.localUser
                                                    maybeRepliedTo2
                                                    (Just thread)
                                                    messageId
                                                    message
                                                    |> Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                            Nothing ->
                                                discordMessageViewThreadStarter
                                                    (encodeMessageView isMobile messageHover2 containerWidth otherUserIsEditing highlight)
                                                    revealedSpoilers
                                                    currentDiscordUserId
                                                    local.localUser
                                                    index
                                                    thread
                                                    message
                                                    |> Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)
                      )
                        |> (\keyedMessage ->
                                keyedMessage
                                    :: List.map
                                        (Tuple.mapSecond (Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)))
                                        (newMessageLine
                                            Drawing.discordUserColor
                                            isSelectingAnchor
                                            channel.dateDividerDrawings
                                            maybeLastDate
                                            date
                                            lastViewedIndex
                                            index
                                            messageId
                                        )
                                    ++ list
                           )
                    )

                MessageUnloaded ->
                    ( index - 1, maybeLastDate, ( String.fromInt index, unloadedMessageView index ) :: list )
        )
        ( Array.length channel.messages - 1, Nothing, [] )
        (VisibleMessages.slice channel)
        |> (\( _, _, a ) -> a)


newMessageLine :
    (userId -> String)
    -> Bool
    -> SeqDict Date (Drawing userId)
    -> Maybe Date
    -> Date
    -> Id messageId
    -> Int
    -> Id messageId
    -> List ( String, Element MessageViewMsg )
newMessageLine drawingUserColor isSelectingAnchor dateDividerDrawings maybeLastDate date lastViewedIndex index messageId =
    case maybeLastDate of
        Just lastDate ->
            case ( lastViewedIndex == messageId, date == lastDate ) of
                ( True, True ) ->
                    [ ( "n" ++ String.fromInt index
                      , Ui.el
                            ([ Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                             , Ui.borderColor MyUi.alertColor
                             ]
                                ++ newContentLabel
                            )
                            Ui.none
                      )
                    ]

                ( False, False ) ->
                    [ ( "n" ++ String.fromInt index
                      , Ui.el
                            [ Ui.paddingXY 8 0
                            , Ui.height (Ui.px 36)
                            , Ui.contentCenterY
                            , MyUi.noShrinking
                            ]
                            (Ui.el
                                [ Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                                , Ui.borderColor MyUi.font3
                                , dateDivider drawingUserColor isSelectingAnchor dateDividerDrawings date lastDate
                                ]
                                Ui.none
                            )
                      )
                    ]

                ( True, False ) ->
                    [ ( "n" ++ String.fromInt index
                      , Ui.el
                            [ Ui.height (Ui.px 36), Ui.contentCenterY, MyUi.noShrinking ]
                            (Ui.el
                                ([ Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                                 , Ui.borderColor MyUi.alertColor
                                 , dateDivider drawingUserColor isSelectingAnchor dateDividerDrawings date lastDate
                                 ]
                                    ++ newContentLabel
                                )
                                Ui.none
                            )
                      )
                    ]

                ( False, True ) ->
                    []

        Nothing ->
            []


threadConversationViewHelper :
    Id ThreadMessageId
    -> GuildOrDmId
    -> Id ChannelMessageId
    -> Maybe (Id ThreadMessageId)
    -> FrontendThread
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> List ( String, Element FrontendMsg )
threadConversationViewHelper lastViewedIndex guildOrDmIdNoThread threadId maybeUrlMessageId thread loggedIn local model =
    let
        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( GuildOrDmId guildOrDmIdNoThread, ViewThread threadId )

        maybeEditing : Maybe EditMessage
        maybeEditing =
            SeqDict.get guildOrDmId loggedIn.editMessage

        othersEditing : SeqSet (Id ThreadMessageId)
        othersEditing =
            SeqDict.remove local.localUser.session.userId thread.lastTypedAt
                |> SeqDict.values
                |> List.filterMap
                    (\a ->
                        if Duration.from a.time model.time |> Quantity.lessThan (Duration.seconds 3) then
                            a.messageIndex

                        else
                            Nothing
                    )
                |> SeqSet.fromList

        replyToIndex : Maybe (Id ThreadMessageId)
        replyToIndex =
            SeqDict.get guildOrDmId loggedIn.replyTo |> Maybe.map Id.changeType

        revealedSpoilers : SeqDict (Id ThreadMessageId) (NonemptySet Int)
        revealedSpoilers =
            case loggedIn.revealedSpoilers of
                Just revealed ->
                    if revealed.guildOrDmId == guildOrDmId then
                        SeqDict.get threadId revealed.threadMessages |> Maybe.withDefault SeqDict.empty

                    else
                        SeqDict.empty

                Nothing ->
                    SeqDict.empty

        containerWidth : Int
        containerWidth =
            conversationWidth model

        isMobile : Bool
        isMobile =
            MyUi.isMobile model

        isSelectingAnchor =
            drawingIsSelectingAnchor loggedIn model
    in
    Array.foldr
        (\messageState ( index, maybeLastDate, list ) ->
            case messageState of
                MessageLoaded message ->
                    let
                        messageId : Id ThreadMessageId
                        messageId =
                            Id.fromInt index

                        threadRoute2 =
                            ViewThreadWithMessage threadId (Id.fromInt index)

                        messageHover2 : IsHovered
                        messageHover2 =
                            messageHover (GuildOrDmId guildOrDmIdNoThread) threadRoute2 loggedIn model

                        otherUserIsEditing : Bool
                        otherUserIsEditing =
                            SeqSet.member messageId othersEditing

                        isEditing : Maybe EditMessage
                        isEditing =
                            case maybeEditing of
                                Just editing ->
                                    if editing.messageIndex == Id.changeType messageId then
                                        Just editing

                                    else
                                        Nothing

                                Nothing ->
                                    Nothing

                        highlight : HighlightMessage
                        highlight =
                            if maybeUrlMessageId == Just messageId then
                                UrlHighlight

                            else if replyToIndex == Just messageId then
                                ReplyToHighlight

                            else
                                NoHighlight

                        maybeRepliedTo2 : Maybe ( Id ThreadMessageId, Message ThreadMessageId (Id UserId) )
                        maybeRepliedTo2 =
                            maybeRepliedTo message thread

                        date : Date
                        date =
                            Message.createdAt message |> Date.fromPosix local.localUser.timezone
                    in
                    ( index - 1
                    , Just date
                    , ( String.fromInt index
                      , case isEditing of
                            Just editing ->
                                if MyUi.isMobile model then
                                    -- On mobile, we show the editor at the bottom instead
                                    threadMessageView
                                        isMobile
                                        containerWidth
                                        revealedSpoilers
                                        highlight
                                        messageHover2
                                        otherUserIsEditing
                                        (LocalState.allUsers local.localUser)
                                        local.localUser.session.userId
                                        local.localUser
                                        maybeRepliedTo2
                                        messageId
                                        message
                                        |> Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                else
                                    let
                                        allUsers =
                                            LocalState.allUsers local.localUser

                                        editRichText : Maybe (Nonempty (RichText (Id UserId)))
                                        editRichText =
                                            case String.Nonempty.fromString editing.text of
                                                Just text ->
                                                    Just (RichText.fromNonemptyString allUsers text)

                                                Nothing ->
                                                    Nothing
                                    in
                                    threadMessageEditingView
                                        isMobile
                                        guildOrDmId
                                        threadId
                                        (Id.fromInt index)
                                        message
                                        maybeRepliedTo2
                                        revealedSpoilers
                                        (RichText.maxLength - String.length editing.text)
                                        editing
                                        editRichText
                                        loggedIn.textInputFocus
                                        local.localUser.session.userId
                                        allUsers
                                        local

                            Nothing ->
                                case maybeRepliedTo2 of
                                    Just _ ->
                                        threadMessageView
                                            isMobile
                                            containerWidth
                                            revealedSpoilers
                                            highlight
                                            messageHover2
                                            otherUserIsEditing
                                            (LocalState.allUsers local.localUser)
                                            local.localUser.session.userId
                                            local.localUser
                                            maybeRepliedTo2
                                            messageId
                                            message
                                            |> Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                    Nothing ->
                                        Ui.Lazy.lazy5
                                            threadMessageViewLazy
                                            (encodeMessageView isMobile messageHover2 containerWidth otherUserIsEditing highlight)
                                            revealedSpoilers
                                            local.localUser
                                            index
                                            message
                                            |> Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)
                      )
                        :: List.map
                            (Tuple.mapSecond (Ui.map (MessageViewMsg (GuildOrDmId guildOrDmIdNoThread) threadRoute2)))
                            (newMessageLine
                                Drawing.userColor
                                isSelectingAnchor
                                thread.dateDividerDrawings
                                maybeLastDate
                                date
                                lastViewedIndex
                                index
                                messageId
                            )
                        ++ list
                    )

                MessageUnloaded ->
                    ( index - 1, maybeLastDate, ( String.fromInt index, unloadedMessageView index ) :: list )
        )
        ( Array.length thread.messages - 1, Nothing, [] )
        (VisibleMessages.slice thread)
        |> (\( _, _, a ) -> a)


discordThreadConversationViewHelper :
    Id ThreadMessageId
    -> Discord.Id Discord.UserId
    -> DiscordGuildOrDmId
    -> Id ChannelMessageId
    -> Maybe (Id ThreadMessageId)
    -> DiscordFrontendThread
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> List ( String, Element FrontendMsg )
discordThreadConversationViewHelper lastViewedIndex currentDiscordUserId guildOrDmIdNoThread threadId maybeUrlMessageId thread loggedIn local model =
    let
        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( DiscordGuildOrDmId guildOrDmIdNoThread, ViewThread threadId )

        maybeEditing : Maybe EditMessage
        maybeEditing =
            SeqDict.get guildOrDmId loggedIn.editMessage

        othersEditing : SeqSet (Id ThreadMessageId)
        othersEditing =
            SeqDict.remove currentDiscordUserId thread.lastTypedAt
                |> SeqDict.values
                |> List.filterMap
                    (\a ->
                        if Duration.from a.time model.time |> Quantity.lessThan (Duration.seconds 3) then
                            a.messageIndex

                        else
                            Nothing
                    )
                |> SeqSet.fromList

        replyToIndex : Maybe (Id ThreadMessageId)
        replyToIndex =
            SeqDict.get guildOrDmId loggedIn.replyTo |> Maybe.map Id.changeType

        revealedSpoilers : SeqDict (Id ThreadMessageId) (NonemptySet Int)
        revealedSpoilers =
            case loggedIn.revealedSpoilers of
                Just revealed ->
                    if revealed.guildOrDmId == guildOrDmId then
                        SeqDict.get threadId revealed.threadMessages |> Maybe.withDefault SeqDict.empty

                    else
                        SeqDict.empty

                Nothing ->
                    SeqDict.empty

        containerWidth : Int
        containerWidth =
            conversationWidth model

        isMobile : Bool
        isMobile =
            MyUi.isMobile model

        isSelectingAnchor =
            drawingIsSelectingAnchor loggedIn model
    in
    Array.foldr
        (\messageState ( index, maybeLastDate, list ) ->
            case messageState of
                MessageLoaded message ->
                    let
                        messageId : Id ThreadMessageId
                        messageId =
                            Id.fromInt index

                        threadRoute2 =
                            ViewThreadWithMessage threadId (Id.fromInt index)

                        messageHover2 : IsHovered
                        messageHover2 =
                            messageHover (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2 loggedIn model

                        otherUserIsEditing : Bool
                        otherUserIsEditing =
                            SeqSet.member messageId othersEditing

                        isEditing : Maybe EditMessage
                        isEditing =
                            case maybeEditing of
                                Just editing ->
                                    if editing.messageIndex == Id.changeType messageId then
                                        Just editing

                                    else
                                        Nothing

                                Nothing ->
                                    Nothing

                        highlight : HighlightMessage
                        highlight =
                            if maybeUrlMessageId == Just messageId then
                                UrlHighlight

                            else if replyToIndex == Just messageId then
                                ReplyToHighlight

                            else
                                NoHighlight

                        maybeRepliedTo2 : Maybe ( Id ThreadMessageId, Message ThreadMessageId (Discord.Id Discord.UserId) )
                        maybeRepliedTo2 =
                            maybeRepliedTo message thread

                        date : Date
                        date =
                            Message.createdAt message |> Date.fromPosix local.localUser.timezone
                    in
                    ( index - 1
                    , Just date
                    , ( String.fromInt index
                      , case isEditing of
                            Just editing ->
                                if MyUi.isMobile model then
                                    -- On mobile, we show the editor at the bottom instead
                                    discordThreadMessageView
                                        isMobile
                                        containerWidth
                                        revealedSpoilers
                                        highlight
                                        messageHover2
                                        (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                                        currentDiscordUserId
                                        local.localUser
                                        maybeRepliedTo2
                                        messageId
                                        message
                                        |> Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                else
                                    let
                                        allUsers =
                                            LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers

                                        editRichText : Maybe (Nonempty (RichText (Discord.Id Discord.UserId)))
                                        editRichText =
                                            case String.Nonempty.fromString editing.text of
                                                Just text ->
                                                    Just (RichText.fromNonemptyString allUsers text)

                                                Nothing ->
                                                    Nothing
                                    in
                                    threadMessageEditingView
                                        isMobile
                                        guildOrDmId
                                        threadId
                                        (Id.fromInt index)
                                        message
                                        maybeRepliedTo2
                                        revealedSpoilers
                                        (RichText.discordCharsLeft OneToOne.empty editRichText)
                                        editing
                                        editRichText
                                        loggedIn.textInputFocus
                                        currentDiscordUserId
                                        allUsers
                                        local

                            Nothing ->
                                case maybeRepliedTo2 of
                                    Just _ ->
                                        discordThreadMessageView
                                            isMobile
                                            containerWidth
                                            revealedSpoilers
                                            highlight
                                            messageHover2
                                            (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                                            currentDiscordUserId
                                            local.localUser
                                            maybeRepliedTo2
                                            messageId
                                            message
                                            |> Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)

                                    Nothing ->
                                        Ui.Lazy.lazy6
                                            discordThreadMessageViewLazy
                                            (encodeMessageView isMobile messageHover2 containerWidth otherUserIsEditing highlight)
                                            revealedSpoilers
                                            currentDiscordUserId
                                            local.localUser
                                            index
                                            message
                                            |> Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)
                      )
                        :: List.map
                            (Tuple.mapSecond (Ui.map (MessageViewMsg (DiscordGuildOrDmId guildOrDmIdNoThread) threadRoute2)))
                            (newMessageLine
                                Drawing.discordUserColor
                                isSelectingAnchor
                                thread.dateDividerDrawings
                                maybeLastDate
                                date
                                lastViewedIndex
                                index
                                messageId
                            )
                        ++ list
                    )

                MessageUnloaded ->
                    ( index - 1, maybeLastDate, ( String.fromInt index, unloadedMessageView index ) :: list )
        )
        ( Array.length thread.messages - 1, Nothing, [] )
        (VisibleMessages.slice thread)
        |> (\( _, _, a ) -> a)


unloadedMessageView : Int -> Element msg
unloadedMessageView index =
    Ui.el
        [ Ui.paddingXY 8 8
        , Ui.background MyUi.alertColor
        , Ui.Font.italic
        ]
        (Ui.text ("Something went wrong when loading message " ++ String.fromInt index))


dateDivider : (userId -> String) -> Bool -> SeqDict Date (Drawing userId) -> Date -> Date -> Ui.Attribute MessageViewMsg
dateDivider userIdToColor isSelectingAnchor dateDividerDrawings laterDate newDate =
    Ui.inFront
        (Ui.column
            ([ Ui.Font.color MyUi.font3
             , Ui.centerX
             , Ui.Font.size 14
             , Ui.Font.bold
             , Ui.move { x = 0, y = -20, z = 0 }
             , Ui.rounded 4
             , Ui.paddingXY 4 0
             ]
                ++ Drawing.anchorHighlight
                    (("guild_dateDivider_" ++ Date.toIsoString newDate) |> Dom.id)
                    userIdToColor
                    (MessageView_PressedDateDivider newDate)
                    isSelectingAnchor
                    (SeqDict.get newDate dateDividerDrawings
                        |> Maybe.withDefault Drawing.emptyDrawing
                    )
            )
            [ Ui.el [ MyUi.noPointerEvents, Ui.Font.center ] (Ui.text (MyUi.datestampDate laterDate))
            , Ui.el [ MyUi.noPointerEvents, Ui.Font.center ] (Ui.text (MyUi.datestampDate newDate))
            ]
        )


newContentLabel : List (Ui.Attribute msg)
newContentLabel =
    [ Ui.inFront
        (Ui.el
            [ Ui.move { x = -6, y = -11, z = 0 }
            , Ui.alignRight
            , Ui.width Ui.shrink
            , Ui.Font.bold
            , Ui.Font.size 14
            ]
            (Ui.text "new")
        )
    , Ui.inFront
        (Ui.el
            [ Ui.Font.color MyUi.font1
            , Ui.background MyUi.alertColor
            , Ui.width (Ui.px 42)
            , Ui.alignRight
            , Ui.height (Ui.px 15)
            , Ui.roundedWith
                { bottomLeft = 8, bottomRight = 0, topLeft = 8, topRight = 0 }
            , Ui.move { x = 0, y = -8, z = 0 }
            ]
            Ui.none
        )
    ]


encodeMessageView : Bool -> IsHovered -> Int -> Bool -> HighlightMessage -> Int
encodeMessageView isMobile isHovered containerWidth otherUserIsEditing highlight =
    (if otherUserIsEditing then
        1

     else
        0
    )
        + Bitwise.shiftLeftBy
            1
            (case isHovered of
                IsNotHovered ->
                    0

                IsHovered ->
                    1

                IsHoveredButNoMenu ->
                    2

                IsHoveredWhileSelectingAnchor ->
                    3
            )
        + Bitwise.shiftLeftBy
            3
            (case highlight of
                NoHighlight ->
                    0

                ReplyToHighlight ->
                    1

                MentionHighlight ->
                    2

                UrlHighlight ->
                    3
            )
        + Bitwise.shiftLeftBy
            5
            (if isMobile then
                1

             else
                0
            )
        + Bitwise.shiftLeftBy 6 containerWidth


decodeMessageView : Int -> { containerWidth : Int, isEditing : Bool, highlight : HighlightMessage, isHovered : IsHovered, isMobile : Bool }
decodeMessageView value =
    { isEditing = Bitwise.and 0x01 value == 1
    , isHovered =
        case Bitwise.shiftRightBy 1 value |> Bitwise.and 0x03 of
            1 ->
                IsHovered

            2 ->
                IsHoveredButNoMenu

            3 ->
                IsHoveredWhileSelectingAnchor

            _ ->
                IsNotHovered
    , highlight =
        case Bitwise.shiftRightBy 3 value |> Bitwise.and 0x03 of
            1 ->
                ReplyToHighlight

            2 ->
                MentionHighlight

            3 ->
                UrlHighlight

            _ ->
                NoHighlight
    , isMobile = Bitwise.shiftRightBy 5 value |> Bitwise.and 0x01 |> (==) 1
    , containerWidth = Bitwise.shiftRightBy 6 value
    }


scrollable : Bool -> Ui.Attribute msg
scrollable canScroll2 =
    if canScroll2 then
        Ui.scrollable

    else
        Ui.clip


conversationContainerId : HtmlId
conversationContainerId =
    Dom.id "conversationContainer"


scrollCloseToTop : number
scrollCloseToTop =
    300


decodeScrollToBottom : AnyGuildOrDmId -> ThreadRoute -> ScrollPosition -> Json.Decode.Decoder FrontendMsg
decodeScrollToBottom guildOrDmId threadRoute currentScrollPosition =
    Json.Decode.map3
        (\scrollTop scrollHeight clientHeight ->
            if scrollTop + clientHeight >= scrollHeight - 5 then
                ScrolledToBottom

            else if scrollTop <= scrollCloseToTop then
                ScrolledToTop

            else
                ScrolledToMiddle
        )
        (Json.Decode.at [ "target", "scrollTop" ] Json.Decode.float)
        (Json.Decode.at [ "target", "scrollHeight" ] Json.Decode.float)
        (Json.Decode.at [ "target", "clientHeight" ] Json.Decode.float)
        |> Json.Decode.andThen
            (\scrollPosition ->
                if scrollPosition == currentScrollPosition then
                    Json.Decode.fail ""

                else
                    UserScrolled guildOrDmId threadRoute scrollPosition |> Json.Decode.succeed
            )


emojiSelector :
    Bool
    -> SeqSet (Id CustomEmojiId)
    -> SeqSet (Id StickerId)
    -> LocalState
    -> LoggedIn2
    -> LoadedFrontend
    -> Ui.Attribute FrontendMsg
emojiSelector isMobile availableCustomEmojis availableStickers local loggedIn model =
    let
        emojiConfig : EmojiConfig
        emojiConfig =
            local.localUser.user.emojiConfig

        paddingX : number
        paddingX =
            4

        x : Int
        x =
            if isMobile then
                Coord.xRaw model.windowSize - paddingX * 2

            else
                Coord.xRaw model.windowSize - MyUi.channelAndGuildColumnWidth model.windowSize - paddingX * 2
    in
    case loggedIn.showEmojiSelector of
        EmojiSelectorHidden ->
            Ui.noAttr

        EmojiSelectorForReaction _ _ ->
            Ui.inFront
                (Emoji.selector
                    (Maybe.map .htmlId loggedIn.textInputFocus == Just Emoji.searchInputId)
                    isMobile
                    x
                    loggedIn.emojiSelector
                    emojiConfig
                    model.emojiData
                    availableCustomEmojis
                    local.localUser.customEmojis
                    availableStickers
                    local.localUser.stickers
                    |> Ui.el
                        [ Ui.alignBottom
                        , Ui.paddingXY paddingX 0
                        , if isMobile then
                            Ui.width Ui.fill

                          else
                            Ui.width Ui.shrink
                        ]
                    |> Ui.map EmojiSelectorMsg
                )

        EmojiSelectorForMessage _ ->
            Ui.inFront
                (Emoji.selector
                    (Maybe.map .htmlId loggedIn.textInputFocus == Just Emoji.searchInputId)
                    isMobile
                    x
                    loggedIn.emojiSelector
                    emojiConfig
                    model.emojiData
                    availableCustomEmojis
                    local.localUser.customEmojis
                    availableStickers
                    local.localUser.stickers
                    |> Ui.el
                        [ Ui.alignBottom
                        , Ui.paddingXY paddingX 0
                        , if isMobile then
                            Ui.width Ui.fill

                          else
                            Ui.width Ui.shrink
                        ]
                    |> Ui.map EmojiSelectorMsg
                )

        EmojiSelectorForEditMessage position _ ->
            let
                y =
                    Coord.yRaw position - Emoji.selectorHeight - MyUi.channelHeaderHeight
            in
            Ui.inFront
                (Emoji.selector
                    (Maybe.map .htmlId loggedIn.textInputFocus == Just Emoji.searchInputId)
                    isMobile
                    x
                    loggedIn.emojiSelector
                    emojiConfig
                    model.emojiData
                    availableCustomEmojis
                    local.localUser.customEmojis
                    availableStickers
                    local.localUser.stickers
                    |> Ui.el
                        [ Ui.paddingXY paddingX 0
                        , Ui.move
                            { x = 0
                            , y =
                                if y < 0 then
                                    Coord.yRaw position

                                else
                                    y
                            , z = 0
                            }
                        ]
                    |> Ui.map EmojiSelectorMsg
                )


replyToHeader :
    ( AnyGuildOrDmId, ThreadRoute )
    -> Maybe (Id messageId)
    -> SeqDict userId { a | name : PersonName }
    -> { b | messages : Array (MessageState messageId2 userId) }
    -> Element FrontendMsg
replyToHeader guildOrDmIdNoThread replyTo allUsers channel =
    case replyTo of
        Just messageIndex ->
            case IdArray.get messageIndex channel.messages of
                Just (MessageLoaded message) ->
                    case message of
                        UserTextMessage data ->
                            replyToHeaderHelper (PressedCloseReplyTo guildOrDmIdNoThread) (Just data.createdBy) allUsers

                        UserJoinedMessage _ userId _ _ ->
                            replyToHeaderHelper (PressedCloseReplyTo guildOrDmIdNoThread) (Just userId) allUsers

                        DeletedMessage _ ->
                            Ui.none

                        CallStarted _ _ userId _ _ ->
                            replyToHeaderHelper (PressedCloseReplyTo guildOrDmIdNoThread) (Just userId) allUsers

                        GameStarted _ userId _ _ _ ->
                            replyToHeaderHelper (PressedCloseReplyTo guildOrDmIdNoThread) (Just userId) allUsers

                _ ->
                    Ui.none

        Nothing ->
            Ui.none


replyToHeaderHelper : msg -> Maybe userId -> SeqDict userId { a | name : PersonName } -> Element msg
replyToHeaderHelper onPress userId allUsers =
    Ui.Prose.paragraph
        [ Ui.Font.color MyUi.font2
        , Ui.background MyUi.background2
        , Ui.paddingXY 32 10
        , Ui.roundedWith { topLeft = 8, topRight = 8, bottomLeft = 0, bottomRight = 0 }
        , Ui.borderWith { left = 1, right = 1, top = 1, bottom = 0 }
        , Ui.borderColor MyUi.border1
        , Ui.inFront
            (MyUi.elButton
                (Dom.id "guild_closeReplyToHeader")
                onPress
                [ Ui.width (Ui.px 32)
                , Ui.paddingWith { left = 4, right = 4, top = 4, bottom = 0 }
                , Ui.alignRight
                ]
                (Ui.html Icons.x)
            )
        , Ui.inFront
            (Ui.el [ Ui.width (Ui.px 18), Ui.move { x = 10, y = 8, z = 0 } ] (Ui.html Icons.reply))
        ]
        [ Ui.text "Reply to "
        , case userId of
            Just userId2 ->
                Ui.el [ Ui.Font.bold ] (Ui.text (User.toString userId2 allUsers))

            Nothing ->
                Ui.text "message"
        ]
        |> Ui.el [ Ui.paddingWith { left = 0, right = 36, top = 0, bottom = 0 }, Ui.move { x = 0, y = 1, z = 0 } ]


{-| Attributes added to the conversation while the drawing tab is open. Until
an anchor is picked, valid anchor elements are highlighted when hovering over
them. Once an anchor is picked an overlay captures mouse events for freehand
drawing.
-}
drawingModeAttributes : Route -> Drawing.Model -> List (Ui.Attribute FrontendMsg)
drawingModeAttributes route drawingMode =
    if Route.toChannelHeaderTab route == Just Route.DmChannelHeaderTab_Draw then
        case drawingMode of
            Drawing.NoSelectedAnchor ->
                []

            Drawing.SelectedAnchor selected ->
                Ui.inFront (Drawing.inputOverlay (selected.stroke /= Nothing) DrawingMsg)
                    :: (if selected.zoom /= 1 then
                            -- Keep the magnified conversation clipped to its normal
                            -- area so zooming in doesn't push the rest of the page around.
                            [ Ui.clip ]

                        else
                            []
                       )

    else
        []


{-| Css transform applied to the conversation container so the area around the
selected anchor is magnified for more precise drawing.
-}
drawingZoomAttributes : Route -> Drawing.Model -> List (Ui.Attribute FrontendMsg)
drawingZoomAttributes route drawingMode =
    case ( Route.toChannelHeaderTab route, drawingMode ) of
        ( Just Route.DmChannelHeaderTab_Draw, Drawing.SelectedAnchor selected ) ->
            case ( selected.zoom /= 1, Drawing.zoomCssOrigin selected ) of
                ( True, Just ( originX, originY ) ) ->
                    [ MyUi.htmlStyle "transform" ("scale(" ++ String.fromFloat selected.zoom ++ ")")
                    , MyUi.htmlStyle
                        "transform-origin"
                        (String.fromFloat originX ++ "px " ++ String.fromFloat originY ++ "px")
                    ]

                _ ->
                    []

        _ ->
            []


conversationView :
    Id ChannelMessageId
    -> GuildOrDmId
    -> Maybe (Id ChannelMessageId)
    -> LoggedIn2
    -> LoadedFrontend
    -> LocalState
    -> String
    ->
        { a
            | messages : Array (MessageState ChannelMessageId (Id UserId))
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) FrontendThread
            , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
        }
    -> Element FrontendMsg
conversationView lastViewedIndex guildOrDmIdNoThread maybeUrlMessageId loggedIn model local name channel =
    let
        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            LocalState.allUsers local.localUser

        replyTo : Maybe (Id ChannelMessageId)
        replyTo =
            SeqDict.get ( GuildOrDmId guildOrDmIdNoThread, NoThread ) loggedIn.replyTo

        isMobile : Bool
        isMobile =
            MyUi.isMobile model

        draft : String
        draft =
            case SeqDict.get ( GuildOrDmId guildOrDmIdNoThread, NoThread ) loggedIn.drafts of
                Just text ->
                    String.Nonempty.toString text

                Nothing ->
                    ""

        draftRichText : Maybe (Nonempty (RichText (Id UserId)))
        draftRichText =
            case SeqDict.get ( GuildOrDmId guildOrDmIdNoThread, NoThread ) loggedIn.drafts of
                Just text ->
                    Just (RichText.fromNonemptyString allUsers text)

                Nothing ->
                    Nothing
    in
    Ui.column
        [ Ui.height Ui.fill
        , Ui.heightMin 0
        ]
        [ ChannelHeader.channel isMobile name guildOrDmIdNoThread local loggedIn model
        , Ui.el
            ([ emojiSelector
                isMobile
                local.localUser.user.availableCustomEmojis
                local.localUser.user.availableStickers
                local
                loggedIn
                model
             , Ui.heightMin 0
             , Ui.height Ui.fill
             ]
                ++ drawingModeAttributes model.route loggedIn.drawingMode
            )
            (Ui.Keyed.column
                ([ Ui.height Ui.fill
                 , Ui.width Ui.fill
                 , Ui.paddingWith { left = 0, right = 0, top = 200, bottom = 16 }
                 , scrollable (canScroll model.drag)
                 , MyUi.htmlStyle "overflow-wrap" "break-word"
                 , Ui.id (Dom.idToString conversationContainerId)
                 , Ui.Events.on
                    "scroll"
                    (decodeScrollToBottom (GuildOrDmId guildOrDmIdNoThread) NoThread loggedIn.channelScrollPosition)
                 , Ui.heightMin 0
                 , bounceScroll isMobile
                 , MyUi.htmlStyle "background-image" "url(/grid1.png)"
                 ]
                    ++ drawingZoomAttributes model.route loggedIn.drawingMode
                )
                ((if VisibleMessages.startIsVisible channel.visibleMessages then
                    [ ( "a"
                      , case guildOrDmIdNoThread of
                            GuildOrDmId_Guild _ _ ->
                                Ui.el
                                    [ Ui.Font.color MyUi.font2, Ui.paddingXY 8 4, Ui.alignBottom, Ui.Font.size 20 ]
                                    (Ui.text ("This is the start of #" ++ name))

                            GuildOrDmId_Dm otherUserId ->
                                Ui.el
                                    [ Ui.Font.color MyUi.font2, Ui.paddingXY 8 4, Ui.alignBottom, Ui.Font.size 20 ]
                                    (Ui.text
                                        (if otherUserId == local.localUser.session.userId then
                                            "This is the start of a conversation with yourself"

                                         else
                                            "This is the start of your conversation with " ++ name
                                        )
                                    )
                      )
                    ]

                  else
                    []
                 )
                    ++ conversationViewHelper
                        lastViewedIndex
                        guildOrDmIdNoThread
                        maybeUrlMessageId
                        channel
                        loggedIn
                        local
                        model
                )
            )
        , Ui.column
            [ Ui.paddingXY 2 0
            , Ui.heightMin 0
            , MyUi.noShrinking
            , case SeqDict.get ( GuildOrDmId guildOrDmIdNoThread, NoThread ) loggedIn.filesToUpload of
                Just filesToUpload2 ->
                    fileUploadPreview
                        (PressedDeleteAttachedFile ( GuildOrDmId guildOrDmIdNoThread, NoThread ))
                        (PressedViewAttachedFileInfo ( GuildOrDmId guildOrDmIdNoThread, NoThread ))
                        (PressedToggleAttachedFileSpoiler ( GuildOrDmId guildOrDmIdNoThread, NoThread ))
                        draftRichText
                        filesToUpload2
                        |> Ui.inFront

                Nothing ->
                    Ui.noAttr
            ]
            [ replyToHeader ( GuildOrDmId guildOrDmIdNoThread, NoThread ) replyTo allUsers channel
            , MessageInput.view
                (Dom.id "messageMenu_channelInput")
                (replyTo == Nothing)
                (MyUi.isMobile model)
                channelTextInputId
                (case guildOrDmIdNoThread of
                    GuildOrDmId_Guild _ _ ->
                        "Write a message in #" ++ name

                    GuildOrDmId_Dm otherUserId ->
                        "Write a message to "
                            ++ (if otherUserId == local.localUser.session.userId then
                                    "yourself"

                                else
                                    name
                               )
                )
                (RichText.maxLength - String.length draft)
                draft
                draftRichText
                (case SeqDict.get ( GuildOrDmId guildOrDmIdNoThread, NoThread ) loggedIn.filesToUpload of
                    Just attachedFiles ->
                        NonemptyDict.toSeqDict attachedFiles

                    Nothing ->
                        SeqDict.empty
                )
                local.localUser.customEmojis
                local.localUser.stickers
                loggedIn.textInputFocus
                (LocalState.allUsers local.localUser)
                |> Ui.map (MessageInputMsg (GuildOrDmId guildOrDmIdNoThread) NoThread)
            , peopleAreTypingView allUsers channel local.localUser.session.userId model
            ]
        ]


discordConversationView :
    Id ChannelMessageId
    -> Discord.Id Discord.UserId
    -> DiscordGuildOrDmId
    -> Maybe (Id ChannelMessageId)
    -> LoggedIn2
    -> LoadedFrontend
    -> LocalState
    -> String
    ->
        { a
            | messages : Array (MessageState ChannelMessageId (Discord.Id Discord.UserId))
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) DiscordFrontendThread
            , dateDividerDrawings : SeqDict Date (Drawing (Discord.Id Discord.UserId))
        }
    -> SeqSet (Id CustomEmojiId)
    -> SeqSet (Id StickerId)
    -> Element FrontendMsg
discordConversationView lastViewedIndex currentDiscordUserId guildOrDmIdNoThread maybeUrlMessageId loggedIn model local name channel availableCustomEmojis availableStickers =
    let
        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( DiscordGuildOrDmId guildOrDmIdNoThread, NoThread )

        allUsers : SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
        allUsers =
            LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers

        replyTo : Maybe (Id ChannelMessageId)
        replyTo =
            SeqDict.get guildOrDmId loggedIn.replyTo

        isMobile : Bool
        isMobile =
            MyUi.isMobile model

        draft : String
        draft =
            case SeqDict.get guildOrDmId loggedIn.drafts of
                Just text ->
                    String.Nonempty.toString text

                Nothing ->
                    ""

        draftRichText : Maybe (Nonempty (RichText (Discord.Id Discord.UserId)))
        draftRichText =
            case SeqDict.get guildOrDmId loggedIn.drafts of
                Just text ->
                    Just (RichText.fromNonemptyString allUsers text)

                Nothing ->
                    Nothing
    in
    Ui.column
        [ Ui.height Ui.fill
        , Ui.heightMin 0
        ]
        [ ChannelHeader.discordChannel isMobile name guildOrDmIdNoThread local loggedIn model
        , Ui.el
            ([ emojiSelector isMobile availableCustomEmojis availableStickers local loggedIn model
             , Ui.heightMin 0
             , Ui.height Ui.fill
             ]
                ++ drawingModeAttributes model.route loggedIn.drawingMode
            )
            (Ui.Keyed.column
                ([ Ui.height Ui.fill
                 , Ui.width Ui.fill
                 , Ui.paddingWith { left = 0, right = 0, top = 200, bottom = 16 }
                 , scrollable (canScroll model.drag)
                 , MyUi.htmlStyle "overflow-wrap" "break-word"
                 , Ui.id (Dom.idToString conversationContainerId)
                 , Ui.Events.on
                    "scroll"
                    (decodeScrollToBottom (DiscordGuildOrDmId guildOrDmIdNoThread) NoThread loggedIn.channelScrollPosition)
                 , Ui.heightMin 0
                 , bounceScroll isMobile
                 , MyUi.htmlStyle "background-image" "url(/grid1.png)"
                 ]
                    ++ drawingZoomAttributes model.route loggedIn.drawingMode
                )
                ((if VisibleMessages.startIsVisible channel.visibleMessages then
                    [ ( "a"
                      , case guildOrDmIdNoThread of
                            DiscordGuildOrDmId_Guild _ _ _ ->
                                Ui.el
                                    [ Ui.Font.color MyUi.font2, Ui.paddingXY 8 4, Ui.alignBottom, Ui.Font.size 20 ]
                                    (Ui.text ("This is the start of #" ++ name))

                            DiscordGuildOrDmId_Dm data ->
                                Ui.el
                                    [ Ui.Font.color MyUi.font2, Ui.paddingXY 8 4, Ui.alignBottom, Ui.Font.size 20 ]
                                    (Ui.text
                                        (if ChannelHeader.chattingWithYourself data local then
                                            "This is the start of a conversation with yourself"

                                         else
                                            "This is the start of your conversation with " ++ name
                                        )
                                    )
                      )
                    ]

                  else
                    []
                 )
                    ++ discordConversationViewHelper
                        lastViewedIndex
                        currentDiscordUserId
                        guildOrDmIdNoThread
                        maybeUrlMessageId
                        channel
                        loggedIn
                        local
                        model
                )
            )
        , Ui.column
            [ Ui.paddingXY 2 0
            , Ui.heightMin 0
            , MyUi.noShrinking
            , case SeqDict.get guildOrDmId loggedIn.filesToUpload of
                Just filesToUpload2 ->
                    fileUploadPreview
                        (PressedDeleteAttachedFile guildOrDmId)
                        (PressedViewAttachedFileInfo guildOrDmId)
                        (PressedToggleAttachedFileSpoiler guildOrDmId)
                        draftRichText
                        filesToUpload2
                        |> Ui.inFront

                Nothing ->
                    Ui.noAttr
            ]
            [ replyToHeader ( DiscordGuildOrDmId guildOrDmIdNoThread, NoThread ) replyTo allUsers channel
            , case LocalState.canSendDiscordMessage local guildOrDmIdNoThread of
                Ok () ->
                    MessageInput.view
                        (Dom.id "messageMenu_channelInput")
                        (replyTo == Nothing)
                        (MyUi.isMobile model)
                        channelTextInputId
                        (case guildOrDmIdNoThread of
                            DiscordGuildOrDmId_Guild _ _ _ ->
                                "Write a message in #" ++ name

                            DiscordGuildOrDmId_Dm data ->
                                "Write a message to "
                                    ++ (if ChannelHeader.chattingWithYourself data local then
                                            "yourself"

                                        else
                                            name
                                       )
                        )
                        (RichText.discordCharsLeft OneToOne.empty draftRichText)
                        draft
                        draftRichText
                        (case SeqDict.get guildOrDmId loggedIn.filesToUpload of
                            Just attachedFiles ->
                                NonemptyDict.toSeqDict attachedFiles

                            Nothing ->
                                SeqDict.empty
                        )
                        local.localUser.customEmojis
                        local.localUser.stickers
                        loggedIn.textInputFocus
                        (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                        |> Ui.map (MessageInputMsg (DiscordGuildOrDmId guildOrDmIdNoThread) NoThread)

                Err error ->
                    MessageInput.disabledView
                        (replyTo == Nothing)
                        error
                        (case SeqDict.get guildOrDmId loggedIn.drafts of
                            Just text ->
                                String.Nonempty.toString text

                            Nothing ->
                                ""
                        )
                        (case SeqDict.get guildOrDmId loggedIn.filesToUpload of
                            Just attachedFiles ->
                                NonemptyDict.toSeqDict attachedFiles

                            Nothing ->
                                SeqDict.empty
                        )
                        local
            , peopleAreTypingView allUsers channel currentDiscordUserId model
            ]
        ]


typingDebouncerDelay : Duration
typingDebouncerDelay =
    Duration.seconds 7


peopleAreTypingView :
    SeqDict userId { a | name : PersonName }
    -> { b | lastTypedAt : SeqDict userId (LastTypedAt messageId) }
    -> userId
    -> LoadedFrontend
    -> Element msg
peopleAreTypingView allUsers channel currentUserId model =
    (case
        SeqDict.filter
            (\_ a ->
                (Duration.from a.time model.time |> Quantity.lessThan (Quantity.plus Duration.second typingDebouncerDelay))
                    && (a.messageIndex == Nothing)
            )
            (SeqDict.remove currentUserId channel.lastTypedAt)
            |> SeqDict.keys
     of
        [] ->
            " "

        [ single ] ->
            User.toString single allUsers ++ " is typing..."

        [ one, two ] ->
            User.toString one allUsers ++ " and " ++ User.toString two allUsers ++ " are typing..."

        [ one, two, three ] ->
            User.toString one allUsers
                ++ ", "
                ++ User.toString two allUsers
                ++ ", and "
                ++ User.toString three allUsers
                ++ " are typing..."

        _ :: _ :: _ :: _ ->
            "Several people are typing..."
    )
        |> Ui.text
        |> Ui.el
            [ Ui.Font.bold
            , Ui.Font.size 13
            , Ui.Font.color MyUi.font3
            , MyUi.prewrap
            , MyUi.noShrinking
            , Ui.contentCenterY
            , MyUi.htmlStyle "user-select" "none"
            , MyUi.htmlStyle
                "padding"
                ("0 calc(12px + "
                    ++ MyUi.insetBottom
                    ++ " * 0.5) "
                    ++ (if model.virtualKeyboardOpen then
                            "0"

                        else
                            MyUi.insetBottom
                       )
                    ++ " calc(12px + "
                    ++ MyUi.insetBottom
                    ++ " * 0.5)"
                )
            ]


threadConversationView :
    Id ThreadMessageId
    -> GuildOrDmId
    -> Maybe (Id ThreadMessageId)
    -> Id ChannelMessageId
    -> LoggedIn2
    -> LoadedFrontend
    -> LocalState
    -> String
    -> FrontendThread
    -> Element FrontendMsg
threadConversationView lastViewedIndex guildOrDmIdNoThread maybeUrlMessageId threadId loggedIn model local name channel =
    let
        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( GuildOrDmId guildOrDmIdNoThread, ViewThread threadId )

        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            LocalState.allUsers local.localUser

        replyTo : Maybe (Id ChannelMessageId)
        replyTo =
            SeqDict.get guildOrDmId loggedIn.replyTo

        isMobile : Bool
        isMobile =
            MyUi.isMobile model

        draft : String
        draft =
            case SeqDict.get guildOrDmId loggedIn.drafts of
                Just text ->
                    String.Nonempty.toString text

                Nothing ->
                    ""

        draftRichText : Maybe (Nonempty (RichText (Id UserId)))
        draftRichText =
            case SeqDict.get guildOrDmId loggedIn.drafts of
                Just text ->
                    Just (RichText.fromNonemptyString allUsers text)

                Nothing ->
                    Nothing
    in
    Ui.column
        [ Ui.height Ui.fill
        , Ui.heightMin 0
        ]
        [ ChannelHeader.thread isMobile name guildOrDmIdNoThread local loggedIn model
        , Ui.el
            ([ emojiSelector
                isMobile
                local.localUser.user.availableCustomEmojis
                local.localUser.user.availableStickers
                local
                loggedIn
                model
             , Ui.heightMin 0
             , Ui.height Ui.fill
             ]
                ++ drawingModeAttributes model.route loggedIn.drawingMode
            )
            (Ui.Keyed.column
                ([ Ui.height Ui.fill
                 , Ui.width Ui.fill
                 , Ui.paddingWith { left = 0, right = 0, top = 200, bottom = 16 }
                 , scrollable (canScroll model.drag)
                 , MyUi.htmlStyle "overflow-wrap" "break-word"
                 , Ui.id (Dom.idToString conversationContainerId)
                 , Ui.Events.on
                    "scroll"
                    (decodeScrollToBottom (GuildOrDmId guildOrDmIdNoThread) (ViewThread threadId) loggedIn.channelScrollPosition)
                 , Ui.heightMin 0
                 , bounceScroll isMobile
                 , MyUi.htmlStyle "background-image" "url(/grid1.png)"
                 ]
                    ++ drawingZoomAttributes model.route loggedIn.drawingMode
                )
                ((if VisibleMessages.startIsVisible channel.visibleMessages then
                    [ ( "a"
                      , Ui.column
                            [ Ui.alignBottom ]
                            [ Ui.el
                                [ Ui.Font.color MyUi.font2, Ui.paddingXY 8 4, Ui.alignBottom, Ui.Font.size 20 ]
                                (Ui.text "Start of thread")
                            , case guildOrDmIdNoThread of
                                GuildOrDmId_Guild guildId channelId ->
                                    case LocalState.getGuildAndChannel guildId channelId local of
                                        Just ( _, channel2 ) ->
                                            threadStarterMessage
                                                isMobile
                                                guildOrDmIdNoThread
                                                threadId
                                                channel2
                                                loggedIn
                                                local
                                                model

                                        Nothing ->
                                            Ui.none

                                GuildOrDmId_Dm otherUserId ->
                                    case SeqDict.get otherUserId local.dmChannels of
                                        Just dmChannel2 ->
                                            threadStarterMessage
                                                isMobile
                                                guildOrDmIdNoThread
                                                threadId
                                                dmChannel2
                                                loggedIn
                                                local
                                                model

                                        Nothing ->
                                            Ui.none
                            ]
                      )
                    ]

                  else
                    []
                 )
                    ++ threadConversationViewHelper
                        lastViewedIndex
                        guildOrDmIdNoThread
                        threadId
                        maybeUrlMessageId
                        channel
                        loggedIn
                        local
                        model
                )
            )
        , Ui.column
            [ Ui.paddingXY 2 0
            , Ui.heightMin 0
            , MyUi.noShrinking
            , case SeqDict.get guildOrDmId loggedIn.filesToUpload of
                Just filesToUpload2 ->
                    fileUploadPreview
                        (PressedDeleteAttachedFile guildOrDmId)
                        (PressedViewAttachedFileInfo guildOrDmId)
                        (PressedToggleAttachedFileSpoiler guildOrDmId)
                        draftRichText
                        filesToUpload2
                        |> Ui.inFront

                Nothing ->
                    Ui.noAttr
            ]
            [ replyToHeader guildOrDmId replyTo allUsers channel
            , MessageInput.view
                (Dom.id "messageMenu_channelInput")
                (replyTo == Nothing)
                (MyUi.isMobile model)
                channelTextInputId
                (case guildOrDmIdNoThread of
                    GuildOrDmId_Guild _ _ ->
                        "Write a message in this thread"

                    GuildOrDmId_Dm _ ->
                        "Write a message in this thread"
                )
                (RichText.maxLength - String.length draft)
                draft
                draftRichText
                (case SeqDict.get guildOrDmId loggedIn.filesToUpload of
                    Just attachedFiles ->
                        NonemptyDict.toSeqDict attachedFiles

                    Nothing ->
                        SeqDict.empty
                )
                local.localUser.customEmojis
                local.localUser.stickers
                loggedIn.textInputFocus
                (LocalState.allUsers local.localUser)
                |> Ui.map (MessageInputMsg (GuildOrDmId guildOrDmIdNoThread) (ViewThread threadId))
            , peopleAreTypingView allUsers channel local.localUser.session.userId model
            ]
        ]


discordThreadConversationView :
    Id ThreadMessageId
    -> Discord.Id Discord.UserId
    -> DiscordGuildOrDmId
    -> Maybe (Id ThreadMessageId)
    -> Id ChannelMessageId
    -> LoggedIn2
    -> LoadedFrontend
    -> LocalState
    -> String
    -> SeqSet (Id CustomEmojiId)
    -> SeqSet (Id StickerId)
    -> DiscordFrontendThread
    -> Element FrontendMsg
discordThreadConversationView lastViewedIndex currentDiscordUserId guildOrDmIdNoThread maybeUrlMessageId threadId loggedIn model local name availableCustomEmojis availableStickers channel =
    let
        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( DiscordGuildOrDmId guildOrDmIdNoThread, ViewThread threadId )

        allUsers : SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
        allUsers =
            LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers

        replyTo : Maybe (Id ChannelMessageId)
        replyTo =
            SeqDict.get guildOrDmId loggedIn.replyTo

        isMobile : Bool
        isMobile =
            MyUi.isMobile model

        draft : String
        draft =
            case SeqDict.get guildOrDmId loggedIn.drafts of
                Just text ->
                    String.Nonempty.toString text

                Nothing ->
                    ""

        draftRichText : Maybe (Nonempty (RichText (Discord.Id Discord.UserId)))
        draftRichText =
            case SeqDict.get guildOrDmId loggedIn.drafts of
                Just text ->
                    Just (RichText.fromNonemptyString allUsers text)

                Nothing ->
                    Nothing
    in
    Ui.column
        [ Ui.height Ui.fill
        , Ui.heightMin 0
        ]
        [ ChannelHeader.discordThread isMobile name guildOrDmIdNoThread local loggedIn model
        , Ui.el
            ([ emojiSelector isMobile availableCustomEmojis availableStickers local loggedIn model
             , Ui.heightMin 0
             , Ui.height Ui.fill
             ]
                ++ drawingModeAttributes model.route loggedIn.drawingMode
            )
            (Ui.Keyed.column
                ([ Ui.height Ui.fill
                 , Ui.width Ui.fill
                 , Ui.paddingWith { left = 0, right = 0, top = 200, bottom = 16 }
                 , scrollable (canScroll model.drag)
                 , MyUi.htmlStyle "overflow-wrap" "break-word"
                 , Ui.id (Dom.idToString conversationContainerId)
                 , Ui.Events.on
                    "scroll"
                    (decodeScrollToBottom (DiscordGuildOrDmId guildOrDmIdNoThread) (ViewThread threadId) loggedIn.channelScrollPosition)
                 , Ui.heightMin 0
                 , bounceScroll isMobile
                 , MyUi.htmlStyle "background-image" "url(/grid1.png)"
                 ]
                    ++ drawingZoomAttributes model.route loggedIn.drawingMode
                )
                ((if VisibleMessages.startIsVisible channel.visibleMessages then
                    [ ( "a"
                      , Ui.column
                            [ Ui.alignBottom ]
                            [ Ui.el
                                [ Ui.Font.color MyUi.font2, Ui.paddingXY 8 4, Ui.alignBottom, Ui.Font.size 20 ]
                                (Ui.text "Start of thread")
                            , case guildOrDmIdNoThread of
                                DiscordGuildOrDmId_Guild _ guildId channelId ->
                                    case LocalState.getDiscordGuildAndChannel guildId channelId local of
                                        Just ( _, channel2 ) ->
                                            discordThreadStarterMessage
                                                isMobile
                                                guildOrDmIdNoThread
                                                threadId
                                                channel2
                                                loggedIn
                                                local
                                                model

                                        Nothing ->
                                            Ui.none

                                DiscordGuildOrDmId_Dm _ ->
                                    Ui.none
                            ]
                      )
                    ]

                  else
                    []
                 )
                    ++ discordThreadConversationViewHelper
                        lastViewedIndex
                        currentDiscordUserId
                        guildOrDmIdNoThread
                        threadId
                        maybeUrlMessageId
                        channel
                        loggedIn
                        local
                        model
                )
            )
        , Ui.column
            [ Ui.paddingXY 2 0
            , Ui.heightMin 0
            , MyUi.noShrinking
            , case SeqDict.get guildOrDmId loggedIn.filesToUpload of
                Just filesToUpload2 ->
                    fileUploadPreview
                        (PressedDeleteAttachedFile guildOrDmId)
                        (PressedViewAttachedFileInfo guildOrDmId)
                        (PressedToggleAttachedFileSpoiler guildOrDmId)
                        draftRichText
                        filesToUpload2
                        |> Ui.inFront

                Nothing ->
                    Ui.noAttr
            ]
            [ replyToHeader guildOrDmId replyTo allUsers channel
            , MessageInput.view
                (Dom.id "messageMenu_channelInput")
                (replyTo == Nothing)
                (MyUi.isMobile model)
                channelTextInputId
                (case guildOrDmIdNoThread of
                    DiscordGuildOrDmId_Guild _ _ _ ->
                        "Write a message in this thread"

                    DiscordGuildOrDmId_Dm _ ->
                        "Write a message in this thread"
                )
                (RichText.discordCharsLeft OneToOne.empty draftRichText)
                draft
                draftRichText
                (case SeqDict.get guildOrDmId loggedIn.filesToUpload of
                    Just attachedFiles ->
                        NonemptyDict.toSeqDict attachedFiles

                    Nothing ->
                        SeqDict.empty
                )
                local.localUser.customEmojis
                local.localUser.stickers
                loggedIn.textInputFocus
                (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                |> Ui.map (MessageInputMsg (DiscordGuildOrDmId guildOrDmIdNoThread) (ViewThread threadId))
            , peopleAreTypingView allUsers channel currentDiscordUserId model
            ]
        ]


threadStarterMessage :
    Bool
    -> GuildOrDmId
    -> Id ChannelMessageId
    -> { a | messages : Array (MessageState ChannelMessageId (Id UserId)) }
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> Element FrontendMsg
threadStarterMessage isMobile normalGuildOrDmIdNoThread threadMessageIndex channel loggedIn local model =
    let
        guildOrDmIdNoThread : AnyGuildOrDmId
        guildOrDmIdNoThread =
            GuildOrDmId normalGuildOrDmIdNoThread

        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( guildOrDmIdNoThread, NoThread )

        threadRoute : ThreadRouteWithMessage
        threadRoute =
            NoThreadWithMessage threadMessageIndex

        revealedSpoilers : SeqDict (Id ChannelMessageId) (NonemptySet Int)
        revealedSpoilers =
            case loggedIn.revealedSpoilers of
                Just revealedSpoilers2 ->
                    if revealedSpoilers2.guildOrDmId == guildOrDmId then
                        revealedSpoilers2.messages

                    else
                        SeqDict.empty

                Nothing ->
                    SeqDict.empty
    in
    case IdArray.get threadMessageIndex channel.messages of
        Just (MessageLoaded message) ->
            case SeqDict.get guildOrDmId loggedIn.editMessage of
                Just edit ->
                    if edit.messageIndex == threadMessageIndex then
                        let
                            allUsers : SeqDict (Id UserId) FrontendUser
                            allUsers =
                                LocalState.allUsers local.localUser

                            editRichText : Maybe (Nonempty (RichText (Id UserId)))
                            editRichText =
                                case String.Nonempty.fromString edit.text of
                                    Just nonempty ->
                                        RichText.fromNonemptyString allUsers nonempty |> Just

                                    Nothing ->
                                        Nothing

                            charsLeft =
                                RichText.maxLength - String.length edit.text
                        in
                        messageEditingView
                            isMobile
                            guildOrDmId
                            (NoThreadWithMessage threadMessageIndex)
                            message
                            Nothing
                            Nothing
                            SeqDict.empty
                            charsLeft
                            edit
                            editRichText
                            loggedIn.textInputFocus
                            local.localUser.session.userId
                            allUsers
                            local

                    else
                        messageView
                            isMobile
                            (conversationWidth model)
                            True
                            revealedSpoilers
                            NoHighlight
                            (messageHover guildOrDmIdNoThread threadRoute loggedIn model)
                            False
                            local.localUser.session.userId
                            (LocalState.allUsers local.localUser)
                            local.localUser
                            Nothing
                            Nothing
                            threadMessageIndex
                            message
                            |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRoute)

                Nothing ->
                    messageView
                        isMobile
                        (conversationWidth model)
                        True
                        revealedSpoilers
                        NoHighlight
                        (messageHover guildOrDmIdNoThread threadRoute loggedIn model)
                        False
                        local.localUser.session.userId
                        (LocalState.allUsers local.localUser)
                        local.localUser
                        Nothing
                        Nothing
                        threadMessageIndex
                        message
                        |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRoute)

        _ ->
            Ui.none


discordThreadStarterMessage :
    Bool
    -> DiscordGuildOrDmId
    -> Id ChannelMessageId
    -> { a | messages : Array (MessageState ChannelMessageId (Discord.Id Discord.UserId)) }
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> Element FrontendMsg
discordThreadStarterMessage isMobile discordGuildOrDmId threadMessageIndex channel loggedIn local model =
    let
        currentUserId : Discord.Id Discord.UserId
        currentUserId =
            case discordGuildOrDmId of
                DiscordGuildOrDmId_Guild currentUserId2 _ _ ->
                    currentUserId2

                DiscordGuildOrDmId_Dm data ->
                    data.currentUserId

        guildOrDmIdNoThread : AnyGuildOrDmId
        guildOrDmIdNoThread =
            DiscordGuildOrDmId discordGuildOrDmId

        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( guildOrDmIdNoThread, NoThread )

        threadRoute : ThreadRouteWithMessage
        threadRoute =
            NoThreadWithMessage threadMessageIndex

        revealedSpoilers : SeqDict (Id ChannelMessageId) (NonemptySet Int)
        revealedSpoilers =
            case loggedIn.revealedSpoilers of
                Just revealedSpoilers2 ->
                    if revealedSpoilers2.guildOrDmId == guildOrDmId then
                        revealedSpoilers2.messages

                    else
                        SeqDict.empty

                Nothing ->
                    SeqDict.empty
    in
    case IdArray.get threadMessageIndex channel.messages of
        Just (MessageLoaded message) ->
            case SeqDict.get guildOrDmId loggedIn.editMessage of
                Just edit ->
                    if edit.messageIndex == threadMessageIndex then
                        let
                            allUsers =
                                LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers

                            editRichText : Maybe (Nonempty (RichText (Discord.Id Discord.UserId)))
                            editRichText =
                                case String.Nonempty.fromString edit.text of
                                    Just nonempty ->
                                        RichText.fromNonemptyString allUsers nonempty |> Just

                                    Nothing ->
                                        Nothing
                        in
                        messageEditingView
                            isMobile
                            guildOrDmId
                            (NoThreadWithMessage threadMessageIndex)
                            message
                            Nothing
                            Nothing
                            SeqDict.empty
                            (RichText.discordCharsLeft OneToOne.empty editRichText)
                            edit
                            editRichText
                            loggedIn.textInputFocus
                            currentUserId
                            allUsers
                            local

                    else
                        discordMessageView
                            isMobile
                            (conversationWidth model)
                            True
                            revealedSpoilers
                            NoHighlight
                            (messageHover guildOrDmIdNoThread threadRoute loggedIn model)
                            currentUserId
                            (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                            local.localUser
                            Nothing
                            Nothing
                            threadMessageIndex
                            message
                            |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRoute)

                Nothing ->
                    discordMessageView
                        isMobile
                        (conversationWidth model)
                        True
                        revealedSpoilers
                        NoHighlight
                        (messageHover guildOrDmIdNoThread threadRoute loggedIn model)
                        currentUserId
                        (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                        local.localUser
                        Nothing
                        Nothing
                        threadMessageIndex
                        message
                        |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRoute)

        _ ->
            Ui.none


dropdownButtonId : Int -> HtmlId
dropdownButtonId index =
    Dom.id ("dropdown_button" ++ String.fromInt index)


reactionEmojiView :
    IsHovered
    -> userId
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict userId { a | name : PersonName }
    -> AnimationMode
    -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
    -> Maybe (Element MessageViewMsg)
reactionEmojiView isHovered currentUserId customEmojis allUsers animationMode reactions =
    if SeqDict.isEmpty reactions then
        Nothing

    else
        Ui.row
            [ Ui.wrap
            , Ui.spacing 4
            ]
            (List.indexedMap
                (\index ( emoji, users ) ->
                    let
                        hasReactedTo : Bool
                        hasReactedTo =
                            NonemptySet.member currentUserId users
                    in
                    (if hasReactedTo then
                        MyUi.rowButton
                            (Dom.id ("guild_removeReactionEmoji_" ++ String.fromInt index))
                            (MessageView_PressedReactionEmoji_Remove emoji)

                     else
                        MyUi.rowButton
                            (Dom.id "guild_addReactionEmoji")
                            (MessageView_PressedReactionEmoji_Add emoji)
                    )
                        [ Ui.rounded 8
                        , Ui.spacing 2
                        , Ui.background MyUi.background1
                        , Ui.paddingXY 4 0
                        , Ui.htmlAttribute (Html.Attributes.class "reaction-emoji-button")
                        , Ui.borderColor
                            (if hasReactedTo then
                                MyUi.highlightedBorder

                             else
                                MyUi.border1
                            )
                        , Ui.Font.color
                            (if hasReactedTo then
                                MyUi.highlightedBorder

                             else
                                MyUi.font2
                            )
                        , Ui.border 1
                        , Ui.width Ui.shrink
                        , Ui.Font.bold
                        , case isHovered of
                            IsHovered ->
                                reactionPopup customEmojis allUsers animationMode emoji users |> Ui.above

                            IsNotHovered ->
                                Ui.noAttr

                            IsHoveredButNoMenu ->
                                Ui.noAttr

                            IsHoveredWhileSelectingAnchor ->
                                Ui.noAttr
                        ]
                        [ case emoji of
                            EmojiOrCustomEmoji_Emoji emoji2 ->
                                Emoji.view emoji2

                            EmojiOrCustomEmoji_CustomEmoji customEmojiId ->
                                Ui.el
                                    [ CustomEmoji.view "1.1em" "0em" customEmojiId customEmojis animationMode
                                        |> Ui.html
                                        |> Ui.el [ Ui.centerY, Ui.move { x = 1, y = 0, z = 0 } ]
                                        |> Ui.inFront
                                    , Ui.Font.color (Ui.rgba 0 0 0 0)
                                    , Ui.Font.size 20
                                    ]
                                    (Ui.text "❓")
                        , Ui.text (String.fromInt (NonemptySet.size users))
                        ]
                )
                (SeqDict.toList reactions)
            )
            |> Just


reactionPopupArrow : Element msg
reactionPopupArrow =
    Ui.html
        (Html.div
            [ Html.Attributes.style "position" "absolute"
            , Html.Attributes.style "top" "calc(100% - 1px)"
            , Html.Attributes.style "left" "11px"
            , Html.Attributes.style "width" "0"
            , Html.Attributes.style "height" "0"
            , Html.Attributes.style "border-left" "8px solid transparent"
            , Html.Attributes.style "border-right" "8px solid transparent"
            , Html.Attributes.style "border-top" ("8px solid " ++ MyUi.colorToStyle MyUi.background1)
            , Html.Attributes.style "pointer-events" "none"
            ]
            []
        )


reactionPopup :
    SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict userId { a | name : PersonName }
    -> AnimationMode
    -> EmojiOrCustomEmoji
    -> NonemptySet userId
    -> Element MessageViewMsg
reactionPopup customEmojis allUsers animationMode emoji users =
    let
        names : Nonempty (Element msg)
        names =
            List.Nonempty.map
                (\userId ->
                    case SeqDict.get userId allUsers of
                        Just user ->
                            Ui.el
                                [ Ui.Font.color MyUi.font1, Ui.width Ui.shrink ]
                                (Ui.text (PersonName.toString user.name))

                        Nothing ->
                            Ui.text "<Missing>"
                )
                (NonemptySet.toNonemptyList users)

        nameCount =
            List.Nonempty.length names
    in
    Ui.row
        [ Ui.htmlAttribute (Html.Attributes.class "reaction-emoji-popup")
        , Ui.width Ui.shrink
        , MyUi.htmlStyle "width" "max-content"
        , MyUi.htmlStyle "max-width" "400px"
        , Ui.background MyUi.background1
        , Ui.borderColor MyUi.border1
        , Ui.border 1
        , Ui.rounded 8
        , Ui.padding 8
        , Ui.spacing 8
        , Ui.move { x = 0, y = -8, z = 0 }
        , Ui.Font.color MyUi.font3
        , MyUi.noPointerEvents
        , Ui.Shadow.shadows [ { x = 0, y = 2, size = 0, blur = 8, color = Ui.rgba 0 0 0 0.3 } ]
        , Ui.contentCenterY
        , Ui.inFront reactionPopupArrow
        ]
        [ case emoji of
            EmojiOrCustomEmoji_Emoji emoji2 ->
                Ui.el [ Ui.Font.size 40, Ui.width Ui.shrink, MyUi.noShrinking ] (Ui.text (Emoji.toString emoji2))

            EmojiOrCustomEmoji_CustomEmoji customEmojiId ->
                CustomEmoji.view "40px" "0em" customEmojiId customEmojis animationMode |> Ui.html
        , Ui.Prose.paragraph
            [ Ui.Font.size 14, Ui.width Ui.fill ]
            (if nameCount > 10 then
                let
                    visible =
                        List.Nonempty.take 8 names
                            |> List.Nonempty.toList
                            |> List.intersperse (Ui.text ", ")
                in
                visible ++ [ Ui.text ", and ", Ui.text (String.fromInt (nameCount - 8)), Ui.text " more" ]

             else
                case List.Nonempty.tail names of
                    [] ->
                        [ List.Nonempty.head names ]

                    [ two ] ->
                        [ List.Nonempty.head names, Ui.text " and ", two ]

                    rest ->
                        List.intersperse (Ui.text ", ") rest ++ [ Ui.text ", and ", List.Nonempty.head names ]
            )
        ]


messageEditingView :
    Bool
    -> ( AnyGuildOrDmId, ThreadRoute )
    -> ThreadRouteWithMessage
    -> Message ChannelMessageId userId
    -> Maybe ( Id ChannelMessageId, Message ChannelMessageId userId )
    -> Maybe (FrontendGenericThread userId)
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> Int
    -> EditMessage
    -> Maybe (Nonempty (RichText userId))
    -> Maybe TextInputFocus
    -> userId
    -> SeqDict userId { a | name : PersonName, icon : Maybe FileHash }
    -> LocalState
    -> Element FrontendMsg
messageEditingView isMobile guildOrDmId threadRouteWithMessage message maybeRepliedTo2 maybeThread revealedSpoilers charsLeft editing editingRichText pingUser currentUserId allUsers local =
    case message of
        UserTextMessage data ->
            let
                maybeReactions : Maybe (Element MessageViewMsg)
                maybeReactions =
                    reactionEmojiView IsHovered currentUserId local.localUser.customEmojis allUsers LoopAFewTimesOnLoad data.reactions

                ( guildOrDmIdNoThread, threadRoute ) =
                    guildOrDmId

                messageInput =
                    MessageInput.view
                        (Dom.id "messageMenu_editDesktop")
                        True
                        False
                        MessageMenu.editMessageTextInputId
                        ""
                        charsLeft
                        editing.text
                        editingRichText
                        editing.attachedFiles
                        local.localUser.customEmojis
                        local.localUser.stickers
                        pingUser
                        allUsers
            in
            Ui.column
                [ Ui.Font.color MyUi.font1
                , Ui.background MyUi.hoverHighlight
                , Ui.paddingWith
                    { left = 0
                    , right = 0
                    , top = 4
                    , bottom =
                        if maybeReactions == Nothing then
                            8

                        else
                            4
                    }
                , Ui.spacing 4
                , (case threadRouteWithMessage of
                    ViewThreadWithMessage _ messageId ->
                        Id.changeType messageId

                    NoThreadWithMessage messageId ->
                        messageId
                  )
                    |> channelMessageHtmlId
                    |> Dom.idToString
                    |> Ui.id
                ]
                [ replyToHeaderAboveMessage
                    isMobile
                    local.localUser.timezone
                    maybeRepliedTo2
                    revealedSpoilers
                    local.localUser.customEmojis
                    allUsers
                    |> Ui.el [ Ui.paddingXY 8 0 ]
                    |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRouteWithMessage)
                , User.toString data.createdBy allUsers
                    ++ " "
                    |> Ui.text
                    |> Ui.el [ Ui.Font.bold, Ui.paddingXY 8 0 ]
                , Ui.column
                    [ case NonemptyDict.fromSeqDict editing.attachedFiles of
                        Just filesToUpload ->
                            fileUploadPreview
                                (EditMessage_PressedDeleteAttachedFile guildOrDmId)
                                (EditMessage_PressedViewAttachedFileInfo guildOrDmId)
                                (EditMessage_PressedToggleAttachedFileSpoiler guildOrDmId)
                                editingRichText
                                filesToUpload
                                |> Ui.inFront

                        Nothing ->
                            Ui.noAttr
                    ]
                    [ messageInput
                        |> Ui.map (EditMessage_MessageInputMsg guildOrDmIdNoThread threadRoute)
                        |> Ui.el [ Ui.paddingXY 5 0 ]
                    , Ui.row
                        [ Ui.Font.size 14
                        , Ui.Font.color MyUi.font3
                        , Ui.paddingXY 12 0
                        , MyUi.prewrap
                        ]
                        [ Ui.text "Press "
                        , MyUi.elButton
                            (Dom.id "guild_exitEditMessage")
                            (PressedCancelMessageEdit guildOrDmId)
                            [ Ui.Font.color MyUi.font1
                            , Ui.width Ui.shrink
                            ]
                            (Ui.text "escape")
                        , Ui.text " to cancel edit"
                        ]
                    ]
                , case maybeReactions of
                    Just reactionView ->
                        Ui.el [ Ui.paddingXY 8 0 ] reactionView
                            |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRouteWithMessage)

                    Nothing ->
                        Ui.none
                , case ( threadRouteWithMessage, maybeThread ) of
                    ( NoThreadWithMessage messageId, Just thread ) ->
                        previewThreadLastMessage local.localUser.timezone local.localUser.customEmojis allUsers messageId thread
                            |> Ui.el [ Ui.paddingXY 8 0 ]
                            |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRouteWithMessage)

                    _ ->
                        Ui.none
                ]

        UserJoinedMessage _ _ _ _ ->
            Ui.none

        DeletedMessage _ ->
            Ui.none

        CallStarted _ _ _ _ _ ->
            Ui.none

        GameStarted _ _ _ _ _ ->
            Ui.none


threadMessageEditingView :
    Bool
    -> ( AnyGuildOrDmId, ThreadRoute )
    -> Id ChannelMessageId
    -> Id ThreadMessageId
    -> Message ThreadMessageId userId
    -> Maybe ( Id ThreadMessageId, Message ThreadMessageId userId )
    -> SeqDict (Id ThreadMessageId) (NonemptySet Int)
    -> Int
    -> EditMessage
    -> Maybe (Nonempty (RichText userId))
    -> Maybe TextInputFocus
    -> userId
    -> SeqDict userId { a | name : PersonName, icon : Maybe FileHash }
    -> LocalState
    -> Element FrontendMsg
threadMessageEditingView isMobile guildOrDmId threadId messageId message maybeRepliedTo2 revealedSpoilers charsLeft editing editingRichText pingUser currentUserId allUsers local =
    case message of
        UserTextMessage data ->
            let
                maybeReactions =
                    reactionEmojiView IsHovered currentUserId local.localUser.customEmojis allUsers LoopAFewTimesOnLoad data.reactions

                ( guildOrDmIdNoThread, _ ) =
                    guildOrDmId

                threadRouteWithMessage =
                    ViewThreadWithMessage threadId messageId

                messageInput =
                    MessageInput.view
                        (Dom.id "messageMenu_editDesktop")
                        True
                        False
                        MessageMenu.editMessageTextInputId
                        ""
                        charsLeft
                        editing.text
                        editingRichText
                        editing.attachedFiles
                        local.localUser.customEmojis
                        local.localUser.stickers
                        pingUser
                        allUsers
            in
            Ui.column
                [ Ui.Font.color MyUi.font1
                , Ui.background MyUi.hoverHighlight
                , Ui.paddingWith
                    { left = 0
                    , right = 0
                    , top = 4
                    , bottom =
                        if maybeReactions == Nothing then
                            8

                        else
                            4
                    }
                , Ui.spacing 4
                , threadMessageHtmlId messageId |> Dom.idToString |> Ui.id
                ]
                [ replyToHeaderAboveMessage
                    isMobile
                    local.localUser.timezone
                    maybeRepliedTo2
                    revealedSpoilers
                    local.localUser.customEmojis
                    allUsers
                    |> Ui.el [ Ui.paddingXY 8 0 ]
                    |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRouteWithMessage)
                , User.toString data.createdBy allUsers
                    ++ " "
                    |> Ui.text
                    |> Ui.el [ Ui.Font.bold, Ui.paddingXY 8 0 ]
                , Ui.column
                    [ case NonemptyDict.fromSeqDict editing.attachedFiles of
                        Just filesToUpload ->
                            fileUploadPreview
                                (EditMessage_PressedDeleteAttachedFile guildOrDmId)
                                (EditMessage_PressedViewAttachedFileInfo guildOrDmId)
                                (EditMessage_PressedToggleAttachedFileSpoiler guildOrDmId)
                                editingRichText
                                filesToUpload
                                |> Ui.inFront

                        Nothing ->
                            Ui.noAttr
                    ]
                    [ messageInput
                        |> Ui.map (EditMessage_MessageInputMsg guildOrDmIdNoThread (ViewThread threadId))
                        |> Ui.el [ Ui.paddingXY 5 0 ]
                    , Ui.row
                        [ Ui.Font.size 14
                        , Ui.Font.color MyUi.font3
                        , Ui.paddingXY 12 0
                        , MyUi.prewrap
                        ]
                        [ Ui.text "Press "
                        , MyUi.elButton
                            (Dom.id "guild_exitEditMessage")
                            (PressedCancelMessageEdit guildOrDmId)
                            [ Ui.Font.color MyUi.font1
                            , Ui.width Ui.shrink
                            ]
                            (Ui.text "escape")
                        , Ui.text " to cancel edit"
                        ]
                    ]
                , case maybeReactions of
                    Just reactionView ->
                        Ui.el [ Ui.paddingXY 8 0 ] reactionView
                            |> Ui.map (MessageViewMsg guildOrDmIdNoThread threadRouteWithMessage)

                    Nothing ->
                        Ui.none
                ]

        UserJoinedMessage _ _ _ _ ->
            Ui.none

        DeletedMessage _ ->
            Ui.none

        CallStarted _ _ _ _ _ ->
            Ui.none

        GameStarted _ _ _ _ _ ->
            Ui.none


type IsHovered
    = IsNotHovered
    | IsHovered
    | IsHoveredButNoMenu
    | IsHoveredWhileSelectingAnchor


messageViewNotThreadStarter :
    Int
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> LocalUser
    -> Int
    -> Message ChannelMessageId (Id UserId)
    -> Element MessageViewMsg
messageViewNotThreadStarter data revealedSpoilers localUser messageIndex message =
    let
        { containerWidth, isEditing, highlight, isHovered, isMobile } =
            decodeMessageView data

        _ =
            Debug.log "rerender messageViewNotThreadStarter" ()
    in
    messageView
        isMobile
        containerWidth
        False
        revealedSpoilers
        highlight
        isHovered
        isEditing
        localUser.session.userId
        (LocalState.allUsers localUser)
        localUser
        Nothing
        Nothing
        (Id.fromInt messageIndex)
        message


discordMessageViewNotThreadStarter :
    Int
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> Discord.Id Discord.UserId
    -> LocalUser
    -> Int
    -> Message ChannelMessageId (Discord.Id Discord.UserId)
    -> Element MessageViewMsg
discordMessageViewNotThreadStarter data revealedSpoilers currentDiscordUserId localUser messageIndex message =
    let
        { containerWidth, highlight, isHovered, isMobile } =
            decodeMessageView data

        _ =
            Debug.log "discord rerender messageViewNotThreadStarter" ()
    in
    --Ui.el
    --    [ Ui.inFront (MyUi.lazyChangedValue "revealedSpoilers" revealedSpoilers)
    --    , Ui.inFront (MyUi.lazyChangedValue "localUser" localUser)
    --    , Ui.inFront (MyUi.lazyChangedValue "messageIndex" messageIndex)
    --    , Ui.inFront (MyUi.lazyChangedValue "message" message)
    --    , Ui.inFront (MyUi.lazyChangedValue "data" data)
    --    , Ui.inFront (MyUi.lazyChangedValue "currentDiscordUserId" currentDiscordUserId)
    --    ]
    discordMessageView
        isMobile
        containerWidth
        False
        revealedSpoilers
        highlight
        isHovered
        currentDiscordUserId
        (LinkedAndOtherDiscordUsers.allDiscordUsers localUser.discordUsers)
        localUser
        Nothing
        Nothing
        (Id.fromInt messageIndex)
        message


messageViewThreadStarter :
    Int
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> LocalUser
    -> Int
    -> FrontendThread
    -> Message ChannelMessageId (Id UserId)
    -> Element MessageViewMsg
messageViewThreadStarter data revealedSpoilers localUser messageIndex thread message =
    let
        { containerWidth, isEditing, highlight, isHovered, isMobile } =
            decodeMessageView data

        _ =
            Debug.log "rerender messageViewThreadStarter" ()
    in
    messageView
        isMobile
        containerWidth
        False
        revealedSpoilers
        highlight
        isHovered
        isEditing
        localUser.session.userId
        (LocalState.allUsers localUser)
        localUser
        Nothing
        (Just thread)
        (Id.fromInt messageIndex)
        message


discordMessageViewThreadStarter :
    Int
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> Discord.Id Discord.UserId
    -> LocalUser
    -> Int
    -> DiscordFrontendThread
    -> Message ChannelMessageId (Discord.Id Discord.UserId)
    -> Element MessageViewMsg
discordMessageViewThreadStarter data revealedSpoilers currentDiscordUserId localUser messageIndex thread message =
    let
        { containerWidth, highlight, isHovered, isMobile } =
            decodeMessageView data

        -- TODO, figure out why this lazy keeps getting triggered even though all the values seem reference unchanged
        --_ =
        --    Debug.log "discord rerender messageViewThreadStarter" ()
    in
    --Ui.el
    --    [ Ui.inFront (MyUi.lazyChangedValue "revealedSpoilers" revealedSpoilers)
    --    , Ui.inFront (MyUi.lazyChangedValue "localUser" localUser)
    --    , Ui.inFront (MyUi.lazyChangedValue "messageIndex" messageIndex)
    --    , Ui.inFront (MyUi.lazyChangedValue "thread" thread)
    --    , Ui.inFront (MyUi.lazyChangedValue "message" message)
    --    , Ui.inFront (MyUi.lazyChangedValue "data" data)
    --    , Ui.inFront (MyUi.lazyChangedValue "currentDiscordUserId" currentDiscordUserId)
    --    ]
    discordMessageView
        isMobile
        containerWidth
        False
        revealedSpoilers
        highlight
        isHovered
        currentDiscordUserId
        (LinkedAndOtherDiscordUsers.allDiscordUsers localUser.discordUsers)
        localUser
        Nothing
        (Just thread)
        (Id.fromInt messageIndex)
        message


threadMessageViewLazy :
    Int
    -> SeqDict (Id ThreadMessageId) (NonemptySet Int)
    -> LocalUser
    -> Int
    -> Message ThreadMessageId (Id UserId)
    -> Element MessageViewMsg
threadMessageViewLazy data revealedSpoilers localUser messageIndex message =
    let
        { containerWidth, isEditing, highlight, isHovered, isMobile } =
            decodeMessageView data

        _ =
            Debug.log "rerender threadMessageViewLazy" ()
    in
    threadMessageView
        isMobile
        containerWidth
        revealedSpoilers
        highlight
        isHovered
        isEditing
        (LocalState.allUsers localUser)
        localUser.session.userId
        localUser
        Nothing
        (Id.fromInt messageIndex)
        message


discordThreadMessageViewLazy :
    Int
    -> SeqDict (Id ThreadMessageId) (NonemptySet Int)
    -> Discord.Id Discord.UserId
    -> LocalUser
    -> Int
    -> Message ThreadMessageId (Discord.Id Discord.UserId)
    -> Element MessageViewMsg
discordThreadMessageViewLazy data revealedSpoilers currentDiscordUserId localUser messageIndex message =
    let
        { containerWidth, highlight, isHovered, isMobile } =
            decodeMessageView data

        _ =
            Debug.log "discord rerender threadMessageViewLazy" ()
    in
    discordThreadMessageView
        isMobile
        containerWidth
        revealedSpoilers
        highlight
        isHovered
        (LinkedAndOtherDiscordUsers.allDiscordUsers localUser.discordUsers)
        currentDiscordUserId
        localUser
        Nothing
        (Id.fromInt messageIndex)
        message


type HighlightMessage
    = NoHighlight
    | ReplyToHighlight
    | MentionHighlight
    | UrlHighlight


profileImagePaddingRight : number
profileImagePaddingRight =
    8


messageView :
    Bool
    -> Int
    -> Bool
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> HighlightMessage
    -> IsHovered
    -> Bool
    -> Id UserId
    -> SeqDict (Id UserId) FrontendUser
    -> LocalUser
    -> Maybe ( Id ChannelMessageId, Message ChannelMessageId (Id UserId) )
    -> Maybe (FrontendGenericThread (Id UserId))
    -> Id ChannelMessageId
    -> Message ChannelMessageId (Id UserId)
    -> Element MessageViewMsg
messageView isMobile containerWidth isThreadStarter revealedSpoilers highlight isHovered isBeingEdited currentUserId allUsers localUser maybeRepliedTo2 maybeThreadStarter messageId message =
    case message of
        UserTextMessage data ->
            messageContainer
                isThreadStarter
                localUser.timezone
                localUser.customEmojis
                allUsers
                (case highlight of
                    NoHighlight ->
                        if SeqSet.member currentUserId (RichText.mentionsUser data.content) then
                            MentionHighlight

                        else
                            highlight

                    _ ->
                        highlight
                )
                messageId
                (currentUserId == data.createdBy)
                currentUserId
                localUser.user
                data.reactions
                maybeThreadStarter
                isHovered
                (userTextMessageContent
                    (Dom.id "spoiler")
                    containerWidth
                    isBeingEdited
                    isMobile
                    maybeRepliedTo2
                    localUser
                    revealedSpoilers
                    allUsers
                    isHovered
                    messageId
                    data
                )

        UserJoinedMessage joinedAt userId reactions drawings ->
            messageContainer
                isThreadStarter
                localUser.timezone
                localUser.customEmojis
                allUsers
                highlight
                messageId
                False
                currentUserId
                localUser.user
                reactions
                maybeThreadStarter
                isHovered
                (Ui.row
                    []
                    [ userJoinedContent userId allUsers
                    , messageTimestamp
                        Drawing.userColor
                        drawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        joinedAt
                        localUser.timezone
                    , messageIdView messageId
                    ]
                )

        DeletedMessage createdAt ->
            messageContainer
                isThreadStarter
                localUser.timezone
                localUser.customEmojis
                allUsers
                highlight
                messageId
                False
                currentUserId
                localUser.user
                SeqDict.empty
                maybeThreadStarter
                isHovered
                (deletedMessageContent
                    messageId
                    (isHovered == IsHoveredWhileSelectingAnchor)
                    highlight
                    createdAt
                    localUser.timezone
                )

        CallStarted time endedAt userId reactions drawings ->
            messageContainer
                isThreadStarter
                localUser.timezone
                localUser.customEmojis
                allUsers
                highlight
                messageId
                False
                currentUserId
                localUser.user
                reactions
                maybeThreadStarter
                isHovered
                (Ui.row
                    [ Ui.contentTop ]
                    [ callStartedCard userId time endedAt allUsers
                    , messageTimestamp
                        Drawing.userColor
                        drawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        time
                        localUser.timezone
                    , messageIdView messageId
                    ]
                )

        GameStarted time userId reactions drawings game ->
            messageContainer
                isThreadStarter
                localUser.timezone
                localUser.customEmojis
                allUsers
                highlight
                messageId
                False
                currentUserId
                localUser.user
                reactions
                maybeThreadStarter
                isHovered
                (Ui.row
                    [ Ui.contentTop ]
                    [ goMatchStartedCard messageId userId allUsers game
                    , messageTimestamp
                        Drawing.userColor
                        drawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        time
                        localUser.timezone
                    , messageIdView messageId
                    ]
                )


discordMessageView :
    Bool
    -> Int
    -> Bool
    -> SeqDict (Id ChannelMessageId) (NonemptySet Int)
    -> HighlightMessage
    -> IsHovered
    -> Discord.Id Discord.UserId
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
    -> LocalUser
    -> Maybe ( Id ChannelMessageId, Message ChannelMessageId (Discord.Id Discord.UserId) )
    -> Maybe (FrontendGenericThread (Discord.Id Discord.UserId))
    -> Id ChannelMessageId
    -> Message ChannelMessageId (Discord.Id Discord.UserId)
    -> Element MessageViewMsg
discordMessageView isMobile containerWidth isThreadStarter revealedSpoilers highlight isHovered currentUserId allUsers localUser maybeRepliedTo2 maybeThreadStarter messageId message =
    case message of
        UserTextMessage data ->
            messageContainer
                isThreadStarter
                localUser.timezone
                localUser.customEmojis
                allUsers
                (case highlight of
                    NoHighlight ->
                        if SeqSet.member currentUserId (RichText.mentionsUser data.content) then
                            MentionHighlight

                        else
                            highlight

                    _ ->
                        highlight
                )
                messageId
                (currentUserId == data.createdBy)
                currentUserId
                localUser.user
                data.reactions
                maybeThreadStarter
                isHovered
                (discordUserTextMessageContent
                    (Dom.id "spoiler")
                    containerWidth
                    isMobile
                    maybeRepliedTo2
                    localUser
                    revealedSpoilers
                    allUsers
                    isHovered
                    messageId
                    data
                )

        UserJoinedMessage joinedAt userId reactions drawings ->
            messageContainer
                isThreadStarter
                localUser.timezone
                localUser.customEmojis
                allUsers
                highlight
                messageId
                False
                currentUserId
                localUser.user
                reactions
                maybeThreadStarter
                isHovered
                (Ui.row
                    []
                    [ userJoinedContent userId allUsers
                    , messageTimestamp
                        Drawing.discordUserColor
                        drawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        joinedAt
                        localUser.timezone
                    , messageIdView messageId
                    ]
                )

        DeletedMessage createdAt ->
            messageContainer
                isThreadStarter
                localUser.timezone
                localUser.customEmojis
                allUsers
                highlight
                messageId
                False
                currentUserId
                localUser.user
                SeqDict.empty
                maybeThreadStarter
                isHovered
                (deletedMessageContent
                    messageId
                    (isHovered == IsHoveredWhileSelectingAnchor)
                    highlight
                    createdAt
                    localUser.timezone
                )

        CallStarted time endedAt userId reactions drawings ->
            messageContainer
                isThreadStarter
                localUser.timezone
                localUser.customEmojis
                allUsers
                highlight
                messageId
                False
                currentUserId
                localUser.user
                reactions
                maybeThreadStarter
                isHovered
                (Ui.row
                    [ Ui.contentTop ]
                    [ callStartedCard userId time endedAt allUsers
                    , messageTimestamp
                        Drawing.discordUserColor
                        drawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        time
                        localUser.timezone
                    , messageIdView messageId
                    ]
                )

        GameStarted time userId reactions drawings game ->
            messageContainer
                isThreadStarter
                localUser.timezone
                localUser.customEmojis
                allUsers
                highlight
                messageId
                False
                currentUserId
                localUser.user
                reactions
                maybeThreadStarter
                isHovered
                (Ui.row
                    [ Ui.contentTop ]
                    [ goMatchStartedCard messageId userId allUsers game
                    , messageTimestamp
                        Drawing.discordUserColor
                        drawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        time
                        localUser.timezone
                    , messageIdView messageId
                    ]
                )


threadMessageView :
    Bool
    -> Int
    -> SeqDict (Id ThreadMessageId) (NonemptySet Int)
    -> HighlightMessage
    -> IsHovered
    -> Bool
    -> SeqDict (Id UserId) FrontendUser
    -> Id UserId
    -> LocalUser
    -> Maybe ( Id ThreadMessageId, Message ThreadMessageId (Id UserId) )
    -> Id ThreadMessageId
    -> Message ThreadMessageId (Id UserId)
    -> Element MessageViewMsg
threadMessageView isMobile containerWidth revealedSpoilers highlight isHovered isBeingEdited allUsers currentUserId localUser maybeRepliedTo2 messageId message =
    case message of
        UserTextMessage message2 ->
            threadMessageContainer
                (case highlight of
                    NoHighlight ->
                        if SeqSet.member currentUserId (RichText.mentionsUser message2.content) then
                            MentionHighlight

                        else
                            highlight

                    _ ->
                        highlight
                )
                messageId
                (currentUserId == message2.createdBy)
                currentUserId
                localUser.user
                message2.reactions
                localUser.customEmojis
                allUsers
                isHovered
                (userTextMessageContent
                    (Dom.id "threadSpoiler")
                    containerWidth
                    isBeingEdited
                    isMobile
                    maybeRepliedTo2
                    localUser
                    revealedSpoilers
                    allUsers
                    isHovered
                    messageId
                    message2
                )

        UserJoinedMessage joinedAt userId reactions drawings ->
            threadMessageContainer
                highlight
                messageId
                False
                currentUserId
                localUser.user
                reactions
                localUser.customEmojis
                allUsers
                isHovered
                (Ui.row
                    []
                    [ userJoinedContent userId allUsers
                    , messageTimestamp
                        Drawing.userColor
                        drawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        joinedAt
                        localUser.timezone
                    ]
                )

        DeletedMessage createdAt ->
            threadMessageContainer
                highlight
                messageId
                False
                currentUserId
                localUser.user
                SeqDict.empty
                localUser.customEmojis
                allUsers
                isHovered
                (deletedMessageContent
                    messageId
                    (isHovered == IsHoveredWhileSelectingAnchor)
                    highlight
                    createdAt
                    localUser.timezone
                )

        CallStarted time endedAt userId reactions drawings ->
            threadMessageContainer
                highlight
                messageId
                False
                currentUserId
                localUser.user
                reactions
                localUser.customEmojis
                allUsers
                isHovered
                (Ui.row
                    []
                    [ callStartedCard userId time endedAt allUsers
                    , messageTimestamp
                        Drawing.userColor
                        drawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        time
                        localUser.timezone
                    ]
                )

        GameStarted time userId reactions drawings game ->
            threadMessageContainer
                highlight
                messageId
                False
                currentUserId
                localUser.user
                reactions
                localUser.customEmojis
                allUsers
                isHovered
                (Ui.row
                    []
                    [ goMatchStartedCard messageId userId allUsers game
                    , messageTimestamp
                        Drawing.userColor
                        drawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        time
                        localUser.timezone
                    ]
                )


discordThreadMessageView :
    Bool
    -> Int
    -> SeqDict (Id ThreadMessageId) (NonemptySet Int)
    -> HighlightMessage
    -> IsHovered
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
    -> Discord.Id Discord.UserId
    -> LocalUser
    -> Maybe ( Id ThreadMessageId, Message ThreadMessageId (Discord.Id Discord.UserId) )
    -> Id ThreadMessageId
    -> Message ThreadMessageId (Discord.Id Discord.UserId)
    -> Element MessageViewMsg
discordThreadMessageView isMobile containerWidth revealedSpoilers highlight isHovered allUsers currentUserId localUser maybeRepliedTo2 messageId message =
    case message of
        UserTextMessage message2 ->
            threadMessageContainer
                (case highlight of
                    NoHighlight ->
                        if SeqSet.member currentUserId (RichText.mentionsUser message2.content) then
                            MentionHighlight

                        else
                            highlight

                    _ ->
                        highlight
                )
                messageId
                (currentUserId == message2.createdBy)
                currentUserId
                localUser.user
                message2.reactions
                localUser.customEmojis
                allUsers
                isHovered
                (discordUserTextMessageContent
                    (Dom.id "threadSpoiler")
                    containerWidth
                    isMobile
                    maybeRepliedTo2
                    localUser
                    revealedSpoilers
                    allUsers
                    isHovered
                    messageId
                    message2
                )

        UserJoinedMessage joinedAt userId reactions drawings ->
            threadMessageContainer
                highlight
                messageId
                False
                currentUserId
                localUser.user
                reactions
                localUser.customEmojis
                allUsers
                isHovered
                (Ui.row
                    []
                    [ userJoinedContent userId allUsers
                    , messageTimestamp
                        Drawing.discordUserColor
                        drawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        joinedAt
                        localUser.timezone
                    ]
                )

        DeletedMessage createdAt ->
            threadMessageContainer
                highlight
                messageId
                False
                currentUserId
                localUser.user
                SeqDict.empty
                localUser.customEmojis
                allUsers
                isHovered
                (deletedMessageContent
                    messageId
                    (isHovered == IsHoveredWhileSelectingAnchor)
                    highlight
                    createdAt
                    localUser.timezone
                )

        CallStarted time endedAt userId reactions drawings ->
            threadMessageContainer
                highlight
                messageId
                False
                currentUserId
                localUser.user
                reactions
                localUser.customEmojis
                allUsers
                isHovered
                (Ui.row
                    []
                    [ callStartedCard userId time endedAt allUsers
                    , messageTimestamp
                        Drawing.discordUserColor
                        drawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        time
                        localUser.timezone
                    ]
                )

        GameStarted time userId reactions drawings game ->
            threadMessageContainer
                highlight
                messageId
                False
                currentUserId
                localUser.user
                reactions
                localUser.customEmojis
                allUsers
                isHovered
                (Ui.row
                    []
                    [ goMatchStartedCard messageId userId allUsers game
                    , messageTimestamp
                        Drawing.discordUserColor
                        drawings
                        (isHovered == IsHoveredWhileSelectingAnchor)
                        messageId
                        time
                        localUser.timezone
                    ]
                )


isHoveredToAnimationMode : IsHovered -> AnimationMode
isHoveredToAnimationMode isHovered =
    case isHovered of
        IsNotHovered ->
            Sticker.LoopAFewTimesOnLoad

        IsHovered ->
            Sticker.ResetAndLoopAFewTimes

        IsHoveredButNoMenu ->
            Sticker.ResetAndLoopAFewTimes

        IsHoveredWhileSelectingAnchor ->
            Sticker.ResetAndLoopAFewTimes


userTextMessageContent :
    HtmlId
    -> Int
    -> Bool
    -> Bool
    -> Maybe ( Id messageId, Message messageId (Id UserId) )
    -> LocalUser
    -> SeqDict (Id messageId) (NonemptySet Int)
    -> SeqDict (Id UserId) FrontendUser
    -> IsHovered
    -> Id messageId
    -> UserTextMessageData messageId (Id UserId)
    -> Element MessageViewMsg
userTextMessageContent spoilerHtmlId containerWidth isBeingEdited isMobile maybeRepliedTo2 localUser revealedSpoilers allUsers isHovered messageId message2 =
    Ui.row
        []
        [ (case SeqDict.get message2.createdBy allUsers of
            Just user ->
                User.profileImage message2.createdBy user.icon

            Nothing ->
                User.profileImage message2.createdBy Nothing
          )
            |> Ui.el
                (Drawing.anchorHighlight
                    (Drawing.profileImageAnchorId messageId)
                    Drawing.userColor
                    MessageView_PressedUserIcon
                    (isHovered == IsHoveredWhileSelectingAnchor)
                    message2.userIconDrawings
                )
            |> Ui.el
                [ Ui.paddingWith
                    { left = 0
                    , right = profileImagePaddingRight
                    , top =
                        case maybeRepliedTo2 of
                            Just _ ->
                                24

                            Nothing ->
                                2
                    , bottom = 0
                    }
                , Ui.width Ui.shrink
                , Ui.alignTop
                ]
        , Ui.column
            []
            [ replyToHeaderAboveMessage
                isMobile
                localUser.timezone
                maybeRepliedTo2
                revealedSpoilers
                localUser.customEmojis
                allUsers
            , Ui.row
                []
                [ User.toString message2.createdBy allUsers
                    ++ " "
                    |> Ui.text
                    |> Ui.el [ Ui.Font.bold ]
                , messageTimestamp
                    Drawing.userColor
                    message2.timestampDrawings
                    (isHovered == IsHoveredWhileSelectingAnchor)
                    messageId
                    message2.createdAt
                    localUser.timezone
                , messageIdView messageId
                ]
            , Html.div
                [ Html.Attributes.style "white-space" "pre-wrap" ]
                (RichText.view
                    (Dom.id (Dom.idToString spoilerHtmlId ++ "_" ++ Id.toString messageId))
                    containerWidth
                    MessageView_PressedNonWhitelistLink
                    MessageView_PressedSpoiler
                    MessageView_PressedImage
                    { revealedSpoilers =
                        case SeqDict.get messageId revealedSpoilers of
                            Just nonempty ->
                                NonemptySet.toSeqSet nonempty

                            Nothing ->
                                SeqSet.empty
                    , users = allUsers
                    , attachedFiles = message2.attachedFiles
                    , domainWhitelist = localUser.user.domainWhitelist
                    , customEmojis = localUser.customEmojis
                    , stickers = localUser.stickers
                    , animationMode = isHoveredToAnimationMode isHovered
                    , timezone = localUser.timezone
                    , drawings = message2.imageAttachmentDrawings
                    , embedDrawings = message2.embedDrawings
                    , drawingUserColor = Drawing.userColor
                    , isSelectingAnchor = isHovered == IsHoveredWhileSelectingAnchor
                    }
                    message2.embeds
                    message2.content
                    ++ (if isBeingEdited then
                            [ Html.span
                                [ Html.Attributes.style "color" "rgb(200,200,200)"
                                , Html.Attributes.style "font-size" "12px"
                                ]
                                [ Html.text " (editing...)" ]
                            ]

                        else
                            case message2.editedAt of
                                Just editedAt ->
                                    [ Html.span
                                        [ Html.Attributes.style "color" "rgb(200,200,200)"
                                        , Html.Attributes.style "font-size" "12px"
                                        , MyUi.datestamp localUser.timezone editedAt |> Html.Attributes.title
                                        ]
                                        [ Html.text " (edited)" ]
                                    ]

                                Nothing ->
                                    []
                       )
                )
                |> Ui.html
            ]
        ]


discordUserTextMessageContent :
    HtmlId
    -> Int
    -> Bool
    -> Maybe ( Id messageId, Message messageId (Discord.Id Discord.UserId) )
    -> LocalUser
    -> SeqDict (Id messageId) (NonemptySet Int)
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
    -> IsHovered
    -> Id messageId
    -> UserTextMessageData messageId (Discord.Id Discord.UserId)
    -> Element MessageViewMsg
discordUserTextMessageContent spoilerHtmlId containerWidth isMobile maybeRepliedTo2 localUser revealedSpoilers allUsers isHovered messageId message2 =
    Ui.row
        []
        [ (case SeqDict.get message2.createdBy allUsers of
            Just user ->
                User.discordProfileImage message2.createdBy user.icon

            Nothing ->
                User.discordProfileImage message2.createdBy Nothing
          )
            |> Ui.el
                (Drawing.anchorHighlight
                    (Drawing.profileImageAnchorId messageId)
                    Drawing.discordUserColor
                    MessageView_PressedUserIcon
                    (isHovered == IsHoveredWhileSelectingAnchor)
                    message2.userIconDrawings
                )
            |> Ui.el
                [ Ui.paddingWith
                    { left = 0
                    , right = profileImagePaddingRight
                    , top =
                        case maybeRepliedTo2 of
                            Just _ ->
                                24

                            Nothing ->
                                2
                    , bottom = 0
                    }
                , Ui.width Ui.shrink
                , Ui.alignTop
                ]
        , Ui.column
            []
            [ replyToHeaderAboveMessage
                isMobile
                localUser.timezone
                maybeRepliedTo2
                revealedSpoilers
                localUser.customEmojis
                allUsers
            , Ui.row
                []
                [ User.toString message2.createdBy allUsers
                    ++ " "
                    |> Ui.text
                    |> Ui.el [ Ui.Font.bold ]
                , messageTimestamp
                    Drawing.discordUserColor
                    message2.timestampDrawings
                    (isHovered == IsHoveredWhileSelectingAnchor)
                    messageId
                    message2.createdAt
                    localUser.timezone
                , messageIdView messageId
                ]
            , Html.div
                [ Html.Attributes.style "white-space" "pre-wrap" ]
                (RichText.view
                    (Dom.id (Dom.idToString spoilerHtmlId ++ "_" ++ Id.toString messageId))
                    containerWidth
                    MessageView_PressedNonWhitelistLink
                    MessageView_PressedSpoiler
                    MessageView_PressedImage
                    { revealedSpoilers =
                        case SeqDict.get messageId revealedSpoilers of
                            Just nonempty ->
                                NonemptySet.toSeqSet nonempty

                            Nothing ->
                                SeqSet.empty
                    , users = allUsers
                    , attachedFiles = message2.attachedFiles
                    , domainWhitelist = localUser.user.domainWhitelist
                    , customEmojis = localUser.customEmojis
                    , stickers = localUser.stickers
                    , animationMode = isHoveredToAnimationMode isHovered
                    , timezone = localUser.timezone
                    , drawings = message2.imageAttachmentDrawings
                    , embedDrawings = message2.embedDrawings
                    , drawingUserColor = Drawing.discordUserColor
                    , isSelectingAnchor = isHovered == IsHoveredWhileSelectingAnchor
                    }
                    message2.embeds
                    message2.content
                    ++ (case message2.editedAt of
                            Just editedAt ->
                                [ Html.span
                                    [ Html.Attributes.style "color" "rgb(200,200,200)"
                                    , Html.Attributes.style "font-size" "12px"
                                    , MyUi.datestamp localUser.timezone editedAt |> Html.Attributes.title
                                    ]
                                    [ Html.text " (edited)" ]
                                ]

                            Nothing ->
                                []
                       )
                )
                |> Ui.html
            ]
        ]


messageIdView : Id messageId -> Element msg
messageIdView _ =
    Ui.none



--if Env.isProduction then
--    Ui.none
--
--else
--    Ui.el [ Ui.Font.size 14, Ui.width Ui.shrink, Ui.paddingLeft 4 ] (Ui.text (Id.toString messageId))


deletedMessageContent : Id messageId -> Bool -> HighlightMessage -> Time.Posix -> Time.Zone -> Element MessageViewMsg
deletedMessageContent messageId isSelectingAnchor highlight createdAt timezone =
    Ui.row
        [ Ui.paddingWith { left = 4, right = 0, top = 4, bottom = 0 } ]
        [ Ui.el
            [ Ui.Font.color MyUi.font3
            , Ui.Font.italic
            , Ui.Font.size 14
            , case highlight of
                NoHighlight ->
                    Ui.noAttr

                ReplyToHighlight ->
                    Ui.noAttr

                MentionHighlight ->
                    Ui.noAttr

                UrlHighlight ->
                    Ui.background MyUi.hoverAndReplyToColor
            ]
            (Ui.text LocalState.messageDeleted)
        , messageTimestamp (\_ -> "") Drawing.emptyDrawing isSelectingAnchor messageId createdAt timezone
        ]


messageTimestamp : (userId -> String) -> Drawing userId -> Bool -> Id messageId -> Time.Posix -> Time.Zone -> Element MessageViewMsg
messageTimestamp userIdToColor drawings isSelectingAnchor messageId createdAt timezone =
    Ui.el
        ([ Ui.Font.size 14
         , Ui.Font.color MyUi.font3
         , Ui.paddingXY 4 0
         , Ui.rounded 4
         ]
            ++ Drawing.anchorHighlight
                ("guild_messageTimestamp_" ++ Id.toString messageId |> Dom.id)
                userIdToColor
                MessageView_PressedTimestamp
                isSelectingAnchor
                drawings
        )
        (Ui.text (MyUi.timestamp createdAt timezone))


messagePreviewTimestamp : Time.Posix -> Time.Zone -> Html msg
messagePreviewTimestamp createdAt timezone =
    Html.span
        [ Html.Attributes.style "font-size" "14px"
        , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3)
        ]
        [ MyUi.timestamp createdAt timezone |> Html.text ]


replyToHeaderAboveMessage :
    Bool
    -> Time.Zone
    -> Maybe ( Id messageId, Message messageId userId )
    -> SeqDict (Id messageId) (NonemptySet Int)
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict userId { a | name : PersonName, icon : Maybe FileHash }
    -> Element MessageViewMsg
replyToHeaderAboveMessage isMobile timezone maybeRepliedTo2 revealedSpoilers customEmojis allUsers =
    case maybeRepliedTo2 of
        Just ( repliedToIndex, UserTextMessage repliedToData ) ->
            replyToHeaderAboveMessageHelper
                isMobile
                repliedToIndex
                (userTextMessagePreview
                    timezone
                    customEmojis
                    allUsers
                    (case SeqDict.get repliedToIndex revealedSpoilers of
                        Just set ->
                            NonemptySet.toSeqSet set

                        Nothing ->
                            SeqSet.empty
                    )
                    repliedToData
                )

        Just ( repliedToIndex, UserJoinedMessage _ userId _ _ ) ->
            replyToHeaderAboveMessageHelper isMobile repliedToIndex (userJoinedContent userId allUsers)

        Just ( repliedToIndex, DeletedMessage _ ) ->
            replyToHeaderAboveMessageHelper
                isMobile
                repliedToIndex
                (Ui.el
                    [ Ui.Font.italic, Ui.Font.color MyUi.font3 ]
                    (Ui.text LocalState.messageDeleted)
                )

        Just ( repliedToIndex, CallStarted startedAt endedAt userId _ _ ) ->
            replyToHeaderAboveMessageHelper isMobile repliedToIndex (callStarted userId startedAt endedAt allUsers)

        Just ( repliedToIndex, GameStarted _ userId _ _ _ ) ->
            replyToHeaderAboveMessageHelper isMobile repliedToIndex (goMatchStarted userId allUsers)

        Nothing ->
            Ui.none


userTextMessagePreview :
    Time.Zone
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict userId { a | name : PersonName }
    -> SeqSet Int
    -> UserTextMessageData messageId userId
    -> Element MessageViewMsg
userTextMessagePreview timezone customEmojis allUsers revealedSpoilers message =
    Html.div
        [ Html.Attributes.style "white-space" "nowrap"
        , Html.Attributes.style "overflow" "hidden"
        , Html.Attributes.style "text-overflow" "ellipsis"
        ]
        (Html.span
            [ Html.Attributes.style "color" "rgb(200,200,200)"
            , Html.Attributes.style "padding" "0 6px 0 2px"
            ]
            [ Html.text (User.toString message.createdBy allUsers) ]
            :: RichText.preview
                (\_ -> MessageView_NoOp)
                { revealedSpoilers = revealedSpoilers
                , users = allUsers
                , attachedFiles = message.attachedFiles
                , customEmojis = customEmojis
                , domainWhitelist = SeqSet.empty
                , timezone = timezone
                }
                message.content
        )
        |> Ui.html


channelMessageHtmlId : Id ChannelMessageId -> HtmlId
channelMessageHtmlId messageIndex =
    "guild_message_" ++ Id.toString messageIndex |> Dom.id


threadMessageHtmlId : Id ThreadMessageId -> HtmlId
threadMessageHtmlId messageIndex =
    "thread_message_" ++ Id.toString messageIndex |> Dom.id


replyToHeaderAboveMessageHelper : Bool -> Id messageId -> Element MessageViewMsg -> Element MessageViewMsg
replyToHeaderAboveMessageHelper isMobile messageId content =
    MyUi.rowButton
        (Dom.id ("guild_replyLink_" ++ Id.toString messageId))
        MessageView_PressedReplyLink
        [ Ui.Font.size 14
        , Ui.paddingWith { left = 0, right = 8, top = 2, bottom = 0 }
        , Ui.Font.color MyUi.font3
        , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
        ]
        [ Ui.el
            [ Ui.width (Ui.px 18)
            , Ui.move { x = 0, y = 3, z = 0 }
            ]
            (Ui.html Icons.reply)
        , content
        ]


userJoinedContent : userId -> SeqDict userId { a | name : PersonName } -> Element msg
userJoinedContent userId allUsers =
    Ui.Prose.paragraph
        [ Ui.paddingXY 0 4 ]
        [ User.toString userId allUsers |> Ui.text |> Ui.el [ Ui.Font.bold ]
        , Ui.el [] (Ui.text " joined!")
        ]


callStarted : userId -> Time.Posix -> Maybe Time.Posix -> SeqDict userId { a | name : PersonName } -> Element msg
callStarted userId startedAt endedAt allUsers =
    Ui.Prose.paragraph
        [ Ui.paddingXY 0 4 ]
        [ User.toString userId allUsers
            |> Ui.text
            |> Ui.el [ Ui.Font.bold ]
        , " started a call" ++ eventDurationText startedAt endedAt |> Ui.text |> Ui.el []
        ]


eventDurationText : Time.Posix -> Maybe Time.Posix -> String
eventDurationText start end =
    case end of
        Just endedAt2 ->
            ", lasted " ++ MyUi.timeElapsed start endedAt2

        Nothing ->
            ""


goMatchStarted : userId -> SeqDict userId { a | name : PersonName } -> Element msg
goMatchStarted userId allUsers =
    Ui.Prose.paragraph
        [ Ui.paddingXY 0 4 ]
        [ User.toString userId allUsers
            |> Ui.text
            |> Ui.el [ Ui.Font.bold ]
        , Ui.text " started a Go match" |> Ui.el []
        ]


callStartedCard : userId -> Time.Posix -> Maybe Time.Posix -> SeqDict userId { a | name : PersonName } -> Element MessageViewMsg
callStartedCard userId startedAt endedAt allUsers =
    eventCard
        (Dom.id "guild_callStartedCard")
        MessageViewMsg_PressedCallStartedCard
        (Ui.html Icons.phone)
        (User.toString userId allUsers)
        ("started a call" ++ eventDurationText startedAt endedAt)


goMatchStartedCard : Id messageId -> userId -> SeqDict userId { a | name : PersonName } -> Game -> Element MessageViewMsg
goMatchStartedCard messageId userId allUsers game =
    case game of
        Game_Go ->
            eventCard
                (Dom.id ("guild_gameStartedCard_" ++ Id.toString messageId))
                MessageViewMsg_PressedGameStartedCard
                (Ui.html Icons.go)
                (User.toString userId allUsers)
                "started a Go match"

        Game_WordSpellingGame ->
            eventCard
                (Dom.id ("guild_gameStartedCard_" ++ Id.toString messageId))
                MessageViewMsg_PressedGameStartedCard
                (Ui.html Icons.go)
                (User.toString userId allUsers)
                "started a Word Spelling game"


eventCard : HtmlId -> MessageViewMsg -> Element MessageViewMsg -> String -> String -> Element MessageViewMsg
eventCard htmlId onPress icon userName action =
    Ui.el
        []
        (MyUi.rowButton
            htmlId
            onPress
            [ Ui.spacing 12
            , Ui.paddingXY 16 6
            , Ui.background MyUi.background2
            , Ui.border 1
            , Ui.borderColor MyUi.border1
            , Ui.rounded 6
            , Ui.width Ui.shrink
            , Ui.Font.color MyUi.font3
            , MyUi.hover False [ Ui.Anim.fontColor MyUi.font1 ]
            ]
            [ icon
            , Ui.column
                [ Ui.spacing 2, Ui.width Ui.shrink ]
                [ Ui.el [ Ui.Font.bold, Ui.Font.color MyUi.font1 ] (Ui.text userName)
                , Ui.el [ Ui.Font.size 13 ] (Ui.text action)
                ]
            ]
        )


messagePaddingX : number
messagePaddingX =
    8


{-| Decodes a "contextmenu" event into a message that opens the message menu.
If the right-click landed on an image attachment or a hyperlink we also grab
their urls (exposed via the "data-image-url"/"data-link-url" attributes) so that
the menu can offer "Copy image"/"Copy image link"/"Copy link" options.
-}
decodeMessageContextMenu : Bool -> Json.Decode.Decoder ( MessageViewMsg, Bool )
decodeMessageContextMenu isThreadStarter =
    Json.Decode.map3
        (\x y target ->
            ( MessageView_AltPressedMessage isThreadStarter target.imageUrl target.linkUrl (Coord.xy (round x) (round y))
            , True
            )
        )
        (Json.Decode.field "clientX" Json.Decode.float)
        (Json.Decode.field "clientY" Json.Decode.float)
        decodeEventTarget


{-| Reads the "data-image-url"/"data-link-url" off the event's target (walking up
its ancestors). Falls back to no urls when there is no target (e.g. in tests).
-}
decodeEventTarget : Json.Decode.Decoder ContextMenuTarget
decodeEventTarget =
    Json.Decode.oneOf
        [ Json.Decode.field "target" (decodeContextMenuTarget 20)
        , Json.Decode.succeed emptyContextMenuTarget
        ]


type alias ContextMenuTarget =
    { imageUrl : Maybe String, linkUrl : Maybe String }


emptyContextMenuTarget : ContextMenuTarget
emptyContextMenuTarget =
    { imageUrl = Nothing, linkUrl = Nothing }


{-| Walks up from the event target through its ancestors looking for the nearest
"data-image-url"/"data-link-url" attributes. We have to climb the tree because
the element actually under the cursor is often a descendant of the one carrying
the attribute (e.g. the <canvas>/<img> that an animated-image-player web
component appends inside itself, or the favicon/label inside a link).
-}
decodeContextMenuTarget : Int -> Json.Decode.Decoder ContextMenuTarget
decodeContextMenuTarget depth =
    Json.Decode.map2
        (\here parent ->
            { imageUrl = orElseMaybe here.imageUrl parent.imageUrl
            , linkUrl = orElseMaybe here.linkUrl parent.linkUrl
            }
        )
        (Json.Decode.map2 ContextMenuTarget
            (Json.Decode.maybe (Json.Decode.at [ "dataset", "imageUrl" ] Json.Decode.string))
            (Json.Decode.maybe (Json.Decode.at [ "dataset", "linkUrl" ] Json.Decode.string))
        )
        (if depth <= 0 then
            Json.Decode.succeed emptyContextMenuTarget

         else
            Json.Decode.oneOf
                [ Json.Decode.field "parentElement" (Json.Decode.lazy (\() -> decodeContextMenuTarget (depth - 1)))
                , Json.Decode.succeed emptyContextMenuTarget
                ]
        )


orElseMaybe : Maybe a -> Maybe a -> Maybe a
orElseMaybe first second =
    case first of
        Just _ ->
            first

        Nothing ->
            second


messageContainer :
    Bool
    -> Time.Zone
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict userId { a | name : PersonName }
    -> HighlightMessage
    -> Id ChannelMessageId
    -> Bool
    -> userId
    -> FrontendCurrentUser
    -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
    -> Maybe (FrontendGenericThread userId)
    -> IsHovered
    -> Element MessageViewMsg
    -> Element MessageViewMsg
messageContainer isThreadStarter timezone customEmojis allUsers highlight messageIndex canEdit currentUserId currentUser reactions maybeThread isHovered messageContent =
    let
        maybeReactions : Maybe (Element MessageViewMsg)
        maybeReactions =
            reactionEmojiView isHovered currentUserId customEmojis allUsers (isHoveredToAnimationMode isHovered) reactions
    in
    Ui.column
        ([ Ui.Font.color MyUi.font1
         , Ui.Events.onMouseEnter MessageView_MouseEnteredMessage
         , Ui.Events.onMouseLeave MessageView_MouseExitedMessage
         , Ui.Events.on
            "touchstart"
            (Json.Decode.map2
                (\toMsg target -> toMsg target.imageUrl target.linkUrl)
                (Touch.decodeTouchEvent
                    (\time touches imageUrl linkUrl ->
                        MessageView_TouchStart
                            time
                            isThreadStarter
                            imageUrl
                            linkUrl
                            (NonemptyDict.map
                                (\_ touch -> { touch | target = channelMessageHtmlId messageIndex |> Just })
                                touches
                            )
                    )
                )
                decodeEventTarget
            )
         , Ui.Events.preventDefaultOn "contextmenu" (decodeMessageContextMenu isThreadStarter)
         , Ui.paddingWith
            { left = messagePaddingX
            , right = messagePaddingX
            , top = 4
            , bottom =
                if maybeReactions == Nothing then
                    8

                else
                    4
            }
         , Ui.spacing 4
         , channelMessageHtmlId messageIndex |> Dom.idToString |> Ui.id
         ]
            ++ (case isHovered of
                    IsNotHovered ->
                        case highlight of
                            NoHighlight ->
                                []

                            ReplyToHighlight ->
                                [ Ui.background MyUi.replyToColor ]

                            MentionHighlight ->
                                [ Ui.background MyUi.mentionColor ]

                            UrlHighlight ->
                                [ Ui.background MyUi.replyToColor ]

                    IsHovered ->
                        [ case highlight of
                            NoHighlight ->
                                Ui.background MyUi.hoverHighlight

                            ReplyToHighlight ->
                                Ui.background MyUi.hoverAndReplyToColor

                            MentionHighlight ->
                                Ui.background MyUi.hoverAndMentionColor

                            UrlHighlight ->
                                Ui.background MyUi.hoverAndReplyToColor
                        , MessageView.miniView currentUser isThreadStarter canEdit customEmojis |> Ui.inFront
                        ]

                    IsHoveredButNoMenu ->
                        case highlight of
                            NoHighlight ->
                                [ Ui.background MyUi.hoverHighlight ]

                            ReplyToHighlight ->
                                [ Ui.background MyUi.hoverAndReplyToColor ]

                            MentionHighlight ->
                                [ Ui.background MyUi.hoverAndMentionColor ]

                            UrlHighlight ->
                                [ Ui.background MyUi.hoverAndReplyToColor ]

                    IsHoveredWhileSelectingAnchor ->
                        []
               )
        )
        (messageContent
            :: Maybe.Extra.toList maybeReactions
            ++ (case maybeThread of
                    Just thread ->
                        [ previewThreadLastMessage timezone customEmojis allUsers messageIndex thread
                        ]

                    Nothing ->
                        []
               )
        )


threadMessageContainer :
    HighlightMessage
    -> Id ThreadMessageId
    -> Bool
    -> userId
    -> FrontendCurrentUser
    -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict userId { a | name : PersonName }
    -> IsHovered
    -> Element MessageViewMsg
    -> Element MessageViewMsg
threadMessageContainer highlight messageIndex canEdit currentUserId currentUser reactions customEmojis allUsers isHovered messageContent =
    let
        maybeReactions : Maybe (Element MessageViewMsg)
        maybeReactions =
            reactionEmojiView isHovered currentUserId customEmojis allUsers (isHoveredToAnimationMode isHovered) reactions
    in
    Ui.column
        ([ Ui.Font.color MyUi.font1
         , Ui.Events.onMouseEnter MessageView_MouseEnteredMessage
         , Ui.Events.onMouseLeave MessageView_MouseExitedMessage
         , Ui.Events.on
            "touchstart"
            (Json.Decode.map2
                (\toMsg target -> toMsg target.imageUrl target.linkUrl)
                (Touch.decodeTouchEvent
                    (\time touches imageUrl linkUrl ->
                        MessageView_TouchStart
                            time
                            False
                            imageUrl
                            linkUrl
                            (NonemptyDict.map
                                (\_ touch -> { touch | target = threadMessageHtmlId messageIndex |> Just })
                                touches
                            )
                    )
                )
                decodeEventTarget
            )
         , Ui.Events.preventDefaultOn "contextmenu" (decodeMessageContextMenu False)
         , Ui.paddingWith
            { left = messagePaddingX
            , right = messagePaddingX
            , top = 4
            , bottom =
                if maybeReactions == Nothing then
                    8

                else
                    4
            }
         , Ui.spacing 4
         , threadMessageHtmlId messageIndex |> Dom.idToString |> Ui.id
         ]
            ++ (case isHovered of
                    IsNotHovered ->
                        case highlight of
                            NoHighlight ->
                                []

                            ReplyToHighlight ->
                                [ Ui.background MyUi.replyToColor ]

                            MentionHighlight ->
                                [ Ui.background MyUi.mentionColor ]

                            UrlHighlight ->
                                [ Ui.background MyUi.replyToColor ]

                    IsHovered ->
                        [ case highlight of
                            NoHighlight ->
                                Ui.background MyUi.hoverHighlight

                            ReplyToHighlight ->
                                Ui.background MyUi.hoverAndReplyToColor

                            MentionHighlight ->
                                Ui.background MyUi.hoverAndMentionColor

                            UrlHighlight ->
                                Ui.background MyUi.hoverAndReplyToColor
                        , MessageView.miniView currentUser False canEdit customEmojis |> Ui.inFront
                        ]

                    IsHoveredButNoMenu ->
                        case highlight of
                            NoHighlight ->
                                [ Ui.background MyUi.hoverHighlight ]

                            ReplyToHighlight ->
                                [ Ui.background MyUi.hoverAndReplyToColor ]

                            MentionHighlight ->
                                [ Ui.background MyUi.hoverAndMentionColor ]

                            UrlHighlight ->
                                [ Ui.background MyUi.hoverAndReplyToColor ]

                    IsHoveredWhileSelectingAnchor ->
                        []
               )
        )
        (messageContent :: Maybe.Extra.toList maybeReactions)


previewThreadLastMessage :
    Time.Zone
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict userId { a | name : PersonName }
    -> Id ChannelMessageId
    -> FrontendGenericThread userId
    -> Element MessageViewMsg
previewThreadLastMessage timezone customEmojis allUsers messageId thread =
    let
        lastMessage =
            Array.Extra.last thread.messages
    in
    Html.button
        [ Html.Attributes.style "white-space" "nowrap"
        , Html.Attributes.style "text-overflow" "ellipsis"
        , Html.Attributes.style "overflow" "hidden"
        , Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.background1)
        , Html.Attributes.style "border" ("1px solid " ++ MyUi.colorToStyle MyUi.border1)
        , Html.Attributes.style "padding" "4px 8px 4px 8px"
        , Html.Attributes.style "width" "fit-content"
        , Html.Attributes.style "max-width" "calc(min(100% - 16px, 800px))"
        , Html.Attributes.style "min-width" "250px"
        , Html.Attributes.style "margin" "0"
        , Html.Attributes.style "color" "inherit"
        , Html.Attributes.style "font-size" "inherit"
        , Html.Attributes.style "text-align" "left"
        , Html.Attributes.id ("guild_threadStarterIndicator_" ++ Id.toString messageId)
        , Html.Events.onClick MessageView_PressedViewThreadLink
        , Html.Attributes.style "cursor" "pointer"
        ]
        (Html.div
            [ Html.Attributes.style "display" "flex"
            , Html.Attributes.style "align-content" "center"
            , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3)
            ]
            [ Icons.hashtag
            , case Array.length thread.messages of
                1 ->
                    Html.text "1 message"

                count ->
                    Html.text (String.fromInt count ++ " messages")
            , Html.div [ Html.Attributes.style "flex-grow" "1" ] []
            , case lastMessage of
                Just (MessageLoaded message) ->
                    messagePreviewTimestamp (Message.createdAt message) timezone

                _ ->
                    Html.text ""
            ]
            :: (case lastMessage of
                    Just (MessageLoaded last) ->
                        case last of
                            UserTextMessage data ->
                                Html.span
                                    [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3)
                                    , Html.Attributes.style "padding" "0 6px 0 2px"
                                    ]
                                    [ Html.text (User.toString data.createdBy allUsers) ]
                                    :: RichText.preview
                                        (\_ -> MessageView_NoOp)
                                        { revealedSpoilers = SeqSet.empty
                                        , users = allUsers
                                        , attachedFiles = data.attachedFiles
                                        , customEmojis = customEmojis
                                        , domainWhitelist = SeqSet.empty
                                        , timezone = timezone
                                        }
                                        data.content

                            UserJoinedMessage _ userId _ _ ->
                                [ Html.span
                                    []
                                    [ Html.b [] [ User.toString userId allUsers |> Html.text ]
                                    , Html.text " joined!"
                                    ]
                                ]

                            DeletedMessage _ ->
                                [ Html.i
                                    [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font3) ]
                                    [ Html.text LocalState.messageDeleted ]
                                ]

                            CallStarted _ endedAt userId _ _ ->
                                [ Html.span
                                    []
                                    [ Html.b [] [ User.toString userId allUsers |> Html.text ]
                                    , case endedAt of
                                        Just _ ->
                                            Html.text "'s call ended"

                                        Nothing ->
                                            Html.text " started a call"
                                    ]
                                ]

                            GameStarted _ userId _ _ _ ->
                                [ Html.span
                                    []
                                    [ Html.b [] [ User.toString userId allUsers |> Html.text ]
                                    , Html.text " started a Go match"
                                    ]
                                ]

                    _ ->
                        []
               )
        )
        |> Ui.html


channelColumnNotMobile :
    LocalUser
    -> Int
    -> Id GuildId
    -> FrontendGuild
    -> ChannelRoute
    -> GuildChannelNameHover
    -> Element FrontendMsg
channelColumnNotMobile localUser time guildId guild channelRoute channelNameHover =
    channelColumn False (Time.millisToPosix time) localUser guildId guild channelRoute channelNameHover True


discordChannelColumnNotMobile :
    Int
    -> LocalUser
    -> DiscordGuildRouteData
    -> DiscordFrontendGuild
    -> GuildChannelNameHover
    -> Element FrontendMsg
discordChannelColumnNotMobile time localUser routeData guild channelNameHover =
    discordChannelColumn False (Time.millisToPosix time) localUser routeData guild channelNameHover True


channelColumnCanScrollMobile :
    LocalUser
    -> Int
    -> Id GuildId
    -> FrontendGuild
    -> ChannelRoute
    -> GuildChannelNameHover
    -> Element FrontendMsg
channelColumnCanScrollMobile localUser time guildId guild channelRoute channelNameHover =
    channelColumn True (Time.millisToPosix time) localUser guildId guild channelRoute channelNameHover True


channelColumnCannotScrollMobile :
    LocalUser
    -> Int
    -> Id GuildId
    -> FrontendGuild
    -> ChannelRoute
    -> GuildChannelNameHover
    -> Element FrontendMsg
channelColumnCannotScrollMobile localUser time guildId guild channelRoute channelNameHover =
    channelColumn True (Time.millisToPosix time) localUser guildId guild channelRoute channelNameHover False


discordChannelColumnCanScrollMobile :
    Int
    -> LocalUser
    -> DiscordGuildRouteData
    -> DiscordFrontendGuild
    -> GuildChannelNameHover
    -> Element FrontendMsg
discordChannelColumnCanScrollMobile time localUser guildId guild channelNameHover =
    discordChannelColumn True (Time.millisToPosix time) localUser guildId guild channelNameHover True


discordChannelColumnCannotScrollMobile :
    Int
    -> LocalUser
    -> DiscordGuildRouteData
    -> DiscordFrontendGuild
    -> GuildChannelNameHover
    -> Element FrontendMsg
discordChannelColumnCannotScrollMobile time localUser guildId guild channelNameHover =
    discordChannelColumn True (Time.millisToPosix time) localUser guildId guild channelNameHover False


channelColumnContainer : List (Element msg) -> Element msg -> Element msg
channelColumnContainer header content =
    Ui.el
        [ Ui.height Ui.fill, MyUi.htmlStyle "padding-top" MyUi.insetTop ]
        (Ui.column
            [ Ui.height Ui.fill
            , Ui.background MyUi.background2
            , MyUi.htmlStyle "border-radius" ("calc(" ++ MyUi.insetTop ++ " * 0.5) 0 0 0")
            , Ui.borderWith { left = 1, right = 0, bottom = 0, top = 1 }
            , Ui.borderColor MyUi.border1
            ]
            [ Ui.row
                [ Ui.Font.bold
                , MyUi.htmlStyle "padding" ("0 4px 0 calc(max(" ++ MyUi.insetTop ++ " * 0.25, 8px))")
                , Ui.spacing 8
                , Ui.Font.color MyUi.font1
                , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
                , Ui.borderColor MyUi.border1
                , Ui.height (Ui.px MyUi.channelHeaderHeight)
                , MyUi.noShrinking
                , Ui.clipWithEllipsis
                ]
                header
            , content
            ]
        )


bounceScroll : Bool -> Ui.Attribute msg
bounceScroll isMobile =
    Ui.attrIf
        isMobile
        (Ui.inFront (Ui.el [ Ui.height (Ui.px 1), Ui.alignBottom, Ui.move { x = 0, y = 1, z = 0 } ] Ui.none))


channelColumn :
    Bool
    -> Time.Posix
    -> LocalUser
    -> Id GuildId
    -> FrontendGuild
    -> ChannelRoute
    -> GuildChannelNameHover
    -> Bool
    -> Element FrontendMsg
channelColumn isMobile time localUser guildId guild channelRoute channelNameHover canScroll2 =
    let
        guildName : String
        guildName =
            GuildName.toString guild.name

        directMentions : Maybe (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater)
        directMentions =
            SeqDict.get guildId localUser.user.directMentions

        newChannelButton : Element FrontendMsg
        newChannelButton =
            case MembersAndOwner.isMember localUser.session.userId guild.membersAndOwner of
                IsOwner ->
                    let
                        isSelected =
                            channelRoute == NewChannelRoute
                    in
                    rowLinkButton
                        (Dom.id "guild_newChannel")
                        (GuildRoute guildId NewChannelRoute)
                        [ Ui.paddingXY 4 8
                        , Ui.Font.color MyUi.font3
                        , Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
                        , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
                        , if isSelected then
                            Ui.Font.color MyUi.font1

                          else
                            Ui.Font.color MyUi.font3
                        ]
                        [ Ui.el [ Ui.width (Ui.px 22) ] (Ui.html Icons.plusIcon)
                        , Ui.text " Add new channel"
                        ]

                _ ->
                    Ui.none
    in
    channelColumnContainer
        [ Ui.el [ MyUi.hoverText guildName ] (Ui.text guildName)
        , elLinkButton
            (Dom.id "guild_inviteLinkCreatorRoute")
            (GuildRoute guildId GuildSettingsRoute)
            [ Ui.Font.color MyUi.font2
            , Ui.width (Ui.px 40)
            , Ui.alignRight
            , Ui.paddingXY 8 0
            , Ui.height Ui.fill
            , Ui.contentCenterY
            ]
            (Ui.html Icons.inviteUserIcon)
        ]
        (Ui.column
            [ scrollable canScroll2
            , Ui.heightMin 0
            , Ui.paddingXY 0 8
            , Ui.attrIf isMobile (Ui.height Ui.fill)
            , bounceScroll isMobile
            ]
            ((List.map
                (\( channelId, channel ) ->
                    let
                        hasNotifications : ChannelNotificationType
                        hasNotifications =
                            channelOrThreadHasNotifications
                                directMentions
                                (SeqSet.member guildId localUser.user.notifyOnAllMessages)
                                channelId
                                NoThread
                                (SeqDict.get (GuildOrDmId (GuildOrDmId_Guild guildId channelId)) localUser.user.lastViewed)
                                channel
                    in
                    ( channelSortName hasNotifications channel
                    , Ui.column
                        []
                        [ channelColumnRow
                            isMobile
                            hasNotifications
                            channelNameHover
                            channelRoute
                            guildId
                            channelId
                            channel
                        , channelColumnThreads
                            isMobile
                            time
                            channelRoute
                            directMentions
                            localUser
                            guildId
                            channelId
                            channel
                            (case channelRoute of
                                ChannelRoute channelIdB (ViewThreadWithFriends threadMessageIndex _ _) _ ->
                                    if channelIdB == channelId then
                                        SeqDict.insert threadMessageIndex Thread.frontendInit channel.threads

                                    else
                                        channel.threads

                                _ ->
                                    channel.threads
                            )
                        ]
                    )
                )
                (SeqDict.toList guild.channels)
                |> List.sortBy Tuple.first
                |> List.map Tuple.second
             )
                ++ [ newChannelButton ]
            )
        )


channelSortName : ChannelNotificationType -> { a | name : ChannelName } -> String
channelSortName hasNotifications channel =
    (case hasNotifications of
        NoNotification ->
            "c"

        NewMessage _ ->
            "b"

        NewMessageForUser _ ->
            "a"
    )
        ++ ChannelName.toString channel.name


discordChannelColumn :
    Bool
    -> Time.Posix
    -> LocalUser
    -> DiscordGuildRouteData
    -> DiscordFrontendGuild
    -> GuildChannelNameHover
    -> Bool
    -> Element FrontendMsg
discordChannelColumn isMobile time localUser routeData guild channelNameHover canScroll2 =
    let
        guildName : String
        guildName =
            GuildName.toString guild.name

        directMentions : Maybe (NonemptyDict ( Discord.Id Discord.ChannelId, ThreadRoute ) OneOrGreater)
        directMentions =
            SeqDict.get routeData.guildId localUser.user.discordDirectMentions
    in
    channelColumnContainer
        [ Ui.row
            [ MyUi.hoverText guildName
            , Ui.spacing 4
            ]
            [ Ui.el
                [ Ui.background (Ui.rgb 88 101 242)
                , Ui.rounded 99
                , Ui.padding 3
                , Ui.border 1
                , Ui.borderColor MyUi.background1
                , Ui.width Ui.shrink
                , MyUi.noShrinking
                ]
                (Ui.html Icons.discord)
            , Ui.text guildName
            ]
        , elLinkButton
            (Dom.id "guild_inviteLinkCreatorRoute")
            (DiscordGuildRoute
                { currentDiscordUserId = routeData.currentDiscordUserId
                , guildId = routeData.guildId
                , channelRoute = DiscordChannel_GuildSettingsRoute
                }
            )
            [ Ui.Font.color MyUi.font2
            , Ui.width (Ui.px 40)
            , Ui.alignRight
            , Ui.paddingXY 8 0
            , Ui.height Ui.fill
            , Ui.contentCenterY
            ]
            (Ui.html Icons.inviteUserIcon)
        ]
        (Ui.column
            [ scrollable canScroll2
            , Ui.heightMin 0
            , Ui.paddingXY 0 8
            , Ui.attrIf isMobile (Ui.height Ui.fill)
            , bounceScroll isMobile
            ]
            (List.map
                (\( channelId, channel ) ->
                    let
                        hasNotifications : ChannelNotificationType
                        hasNotifications =
                            channelOrThreadHasNotifications
                                directMentions
                                (SeqSet.member routeData.guildId localUser.user.discordNotifyOnAllMessages)
                                channelId
                                NoThread
                                (SeqDict.get (DiscordGuildOrDmId (DiscordGuildOrDmId_Guild routeData.currentDiscordUserId routeData.guildId channelId)) localUser.user.lastViewed)
                                channel
                    in
                    ( channelSortName hasNotifications channel
                    , Ui.column
                        []
                        [ discordChannelColumnRow
                            isMobile
                            hasNotifications
                            channelNameHover
                            routeData
                            channelId
                            channel
                        , discordChannelColumnThreads
                            isMobile
                            time
                            routeData
                            directMentions
                            localUser
                            channelId
                            channel
                            (case routeData.channelRoute of
                                DiscordChannel_ChannelRoute channelIdB (ViewThreadWithFriends threadMessageIndex _ _) _ ->
                                    if channelIdB == channelId then
                                        SeqDict.insert threadMessageIndex Thread.discordFrontendInit channel.threads

                                    else
                                        channel.threads

                                _ ->
                                    channel.threads
                            )
                        ]
                    )
                )
                (SeqDict.toList guild.channels)
                |> List.sortBy Tuple.first
                |> List.map Tuple.second
            )
        )


channelColumnThreads :
    Bool
    -> Time.Posix
    -> ChannelRoute
    -> Maybe (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater)
    -> LocalUser
    -> Id GuildId
    -> Id ChannelId
    -> FrontendChannel
    -> SeqDict (Id ChannelMessageId) FrontendThread
    -> Element FrontendMsg
channelColumnThreads isMobile now channelRoute directMentions localUser guildId channelId channel threads =
    let
        threads2 : List ( Id ChannelMessageId, ChannelNotificationType, Bool )
        threads2 =
            List.filterMap
                (\( threadMessageIndex, thread ) ->
                    let
                        isSelected : Bool
                        isSelected =
                            case channelRoute of
                                ChannelRoute a (ViewThreadWithFriends b _ _) _ ->
                                    a == channelId && b == threadMessageIndex

                                _ ->
                                    False

                        hasNotifications : ChannelNotificationType
                        hasNotifications =
                            channelOrThreadHasNotifications
                                directMentions
                                (SeqSet.member guildId localUser.user.notifyOnAllMessages)
                                channelId
                                (ViewThread threadMessageIndex)
                                (SeqDict.get
                                    ( GuildOrDmId (GuildOrDmId_Guild guildId channelId), threadMessageIndex )
                                    localUser.user.lastViewedThreads
                                )
                                thread
                    in
                    case ( hasNotifications, isSelected, Array.Extra.last thread.messages ) of
                        ( NoNotification, False, Just (MessageLoaded message) ) ->
                            if Duration.from (Message.createdAt message) now |> Quantity.lessThan Duration.week then
                                Just ( threadMessageIndex, hasNotifications, isSelected )

                            else
                                Nothing

                        _ ->
                            Just ( threadMessageIndex, hasNotifications, isSelected )
                )
                (SeqDict.toList threads)

        count =
            List.length threads2
    in
    List.indexedMap
        (\index ( threadMessageIndex, hasNotifications, isSelected ) ->
            channelColumnThreadsHelper
                isMobile
                isSelected
                hasNotifications
                index
                count
                (MouseEnteredChannelName guildId channelId (ViewThread threadMessageIndex))
                (MouseExitedChannelName guildId channelId (ViewThread threadMessageIndex))
                (Dom.id ("guild_viewThread_" ++ Id.toString channelId ++ "_" ++ Id.toString threadMessageIndex))
                (GuildRoute guildId (ChannelRoute channelId (ViewThreadWithFriends threadMessageIndex Nothing HideMembersTab) Nothing))
                (threadPreviewText (LocalState.allUsers localUser) threadMessageIndex channel)
        )
        threads2
        |> Ui.column []


channelColumnThreadsHelper :
    Bool
    -> Bool
    -> ChannelNotificationType
    -> Int
    -> Int
    -> FrontendMsg
    -> FrontendMsg
    -> HtmlId
    -> Route
    -> String
    -> Element FrontendMsg
channelColumnThreadsHelper isMobile isSelected hasNotifications index visibleThreadCount onMouseEnter onMouseLeave htmlId route name =
    Ui.row
        [ Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
        , Ui.attrIf (not isMobile) (Ui.Events.onMouseEnter onMouseEnter)
        , Ui.attrIf (not isMobile) (Ui.Events.onMouseLeave onMouseLeave)
        , Ui.clipWithEllipsis
        , Ui.height (Ui.px MyUi.channelHeaderHeight)
        , MyUi.hoverText name
        , Ui.contentCenterY
        , MyUi.noShrinking
        ]
        [ elLinkButton
            htmlId
            route
            [ Ui.height Ui.fill
            , Ui.contentCenterY
            , Ui.paddingWith { left = 28, right = 8, top = 0, bottom = 0 }
            , Ui.el
                [ (if isSelected && not isMobile then
                    NoNotification

                   else
                    hasNotifications
                  )
                    |> GuildIcon.notificationView 4 5 MyUi.background2
                , Ui.move { x = 0, y = 0, z = 0 }
                , Ui.Font.color MyUi.font3
                , Ui.width Ui.shrink
                ]
                (Ui.html
                    (if visibleThreadCount == 1 then
                        Icons.threadSingleSegment

                     else if visibleThreadCount - 1 == index then
                        Icons.threadBottomSegment

                     else if index == 0 then
                        Icons.threadTopSegment

                     else
                        Icons.threadMiddleSegment
                    )
                )
                |> Ui.inFront
            , if isSelected then
                Ui.Font.color MyUi.font1

              else
                Ui.Font.color MyUi.font3
            , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
            ]
            (Ui.text name)
        ]


discordChannelColumnThreads :
    Bool
    -> Time.Posix
    -> DiscordGuildRouteData
    -> Maybe (NonemptyDict ( Discord.Id Discord.ChannelId, ThreadRoute ) OneOrGreater)
    -> LocalUser
    -> Discord.Id Discord.ChannelId
    -> DiscordFrontendChannel
    -> SeqDict (Id ChannelMessageId) DiscordFrontendThread
    -> Element FrontendMsg
discordChannelColumnThreads isMobile now routeData directMentions localUser channelId channel threads =
    let
        threads2 : List ( Id ChannelMessageId, ChannelNotificationType, Bool )
        threads2 =
            List.filterMap
                (\( threadMessageIndex, thread ) ->
                    let
                        isSelected : Bool
                        isSelected =
                            case routeData.channelRoute of
                                DiscordChannel_ChannelRoute a (ViewThreadWithFriends b _ _) _ ->
                                    a == channelId && b == threadMessageIndex

                                _ ->
                                    False

                        hasNotifications : ChannelNotificationType
                        hasNotifications =
                            channelOrThreadHasNotifications
                                directMentions
                                (SeqSet.member routeData.guildId localUser.user.discordNotifyOnAllMessages)
                                channelId
                                (ViewThread threadMessageIndex)
                                (SeqDict.get
                                    ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild routeData.currentDiscordUserId routeData.guildId channelId)
                                    , threadMessageIndex
                                    )
                                    localUser.user.lastViewedThreads
                                )
                                thread
                    in
                    case ( hasNotifications, isSelected, Array.Extra.last thread.messages ) of
                        ( NoNotification, False, Just (MessageLoaded message) ) ->
                            if Duration.from (Message.createdAt message) now |> Quantity.lessThan Duration.week then
                                Just ( threadMessageIndex, hasNotifications, isSelected )

                            else
                                Nothing

                        _ ->
                            Just ( threadMessageIndex, hasNotifications, isSelected )
                )
                (SeqDict.toList threads)

        count : Int
        count =
            List.length threads2
    in
    List.indexedMap
        (\index ( threadMessageIndex, hasNotifications, isSelected ) ->
            channelColumnThreadsHelper
                isMobile
                isSelected
                hasNotifications
                index
                count
                (MouseEnteredDiscordChannelName routeData.guildId channelId (ViewThread threadMessageIndex))
                (MouseExitedDiscordChannelName routeData.guildId channelId (ViewThread threadMessageIndex))
                (Dom.id ("guild_viewThread_" ++ Discord.idToString channelId ++ "_" ++ Id.toString threadMessageIndex))
                (DiscordGuildRoute
                    { currentDiscordUserId = routeData.currentDiscordUserId
                    , guildId = routeData.guildId
                    , channelRoute =
                        DiscordChannel_ChannelRoute
                            channelId
                            (ViewThreadWithFriends threadMessageIndex Nothing HideMembersTab)
                            Nothing
                    }
                )
                (threadPreviewText (LinkedAndOtherDiscordUsers.allDiscordUsers localUser.discordUsers) threadMessageIndex channel)
        )
        threads2
        |> Ui.column []


channelColumnRow :
    Bool
    -> ChannelNotificationType
    -> GuildChannelNameHover
    -> ChannelRoute
    -> Id GuildId
    -> Id ChannelId
    -> FrontendChannel
    -> Element FrontendMsg
channelColumnRow isMobile hasNotification channelNameHover channelRoute guildId channelId channel =
    let
        isSelected : Bool
        isSelected =
            case channelRoute of
                ChannelRoute a (NoThreadWithFriends _ _) _ ->
                    a == channelId

                EditChannelRoute a ->
                    a == channelId

                _ ->
                    False

        isHover : Bool
        isHover =
            channelNameHover == GuildChannelNameHover guildId channelId NoThread
    in
    Ui.row
        [ Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
        , Ui.attrIf
            (not isMobile)
            (Ui.Events.onMouseEnter (MouseEnteredChannelName guildId channelId NoThread))
        , Ui.attrIf
            (not isMobile)
            (Ui.Events.onMouseLeave (MouseExitedChannelName guildId channelId NoThread))
        , Ui.clipWithEllipsis
        , Ui.height (Ui.px MyUi.channelHeaderHeight)
        , MyUi.hoverText (ChannelName.toString channel.name)
        , Ui.contentCenterY
        , MyUi.noShrinking
        ]
        [ elLinkButton
            (Dom.id ("guild_openChannel_" ++ Id.toString channelId))
            (GuildRoute guildId (ChannelRoute channelId (NoThreadWithFriends Nothing HideMembersTab) Nothing))
            [ Ui.height Ui.fill
            , Ui.contentCenterY
            , Ui.paddingWith
                { left = 26
                , right =
                    if isHover then
                        0

                    else
                        8
                , top = 0
                , bottom = 0
                }
            , Ui.el
                [ (if isSelected && not isMobile then
                    NoNotification

                   else
                    hasNotification
                  )
                    |> GuildIcon.notificationView 0 -3 MyUi.background2
                , Ui.width (Ui.px 20)
                , Ui.move { x = 4, y = 0, z = 0 }
                , Ui.centerY
                ]
                (Ui.html Icons.hashtag)
                |> Ui.inFront
            , if isSelected then
                Ui.Font.color MyUi.font1

              else
                Ui.Font.color MyUi.font3
            , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
            ]
            (Ui.text (ChannelName.toString channel.name))
        , if isHover then
            elLinkButton
                (Dom.id ("guild_editChannel_" ++ Id.toString channelId))
                (GuildRoute guildId (EditChannelRoute channelId))
                [ Ui.alignRight
                , Ui.width (Ui.px 26)
                , Ui.contentCenterY
                , Ui.height Ui.fill
                , Ui.paddingWith { left = 0, right = 2, top = 0, bottom = 0 }
                , Ui.Font.color MyUi.font3
                , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
                ]
                (Ui.html Icons.gear)

          else
            Ui.none
        ]


discordChannelColumnRow :
    Bool
    -> ChannelNotificationType
    -> GuildChannelNameHover
    -> DiscordGuildRouteData
    -> Discord.Id Discord.ChannelId
    -> DiscordFrontendChannel
    -> Element FrontendMsg
discordChannelColumnRow isMobile hasNotifications channelNameHover routeData channelId channel =
    let
        isSelected : Bool
        isSelected =
            case routeData.channelRoute of
                DiscordChannel_ChannelRoute a (NoThreadWithFriends _ _) _ ->
                    a == channelId

                DiscordChannel_EditChannelRoute a ->
                    a == channelId

                _ ->
                    False

        isHover : Bool
        isHover =
            channelNameHover == DiscordGuildChannelNameHover routeData.guildId channelId NoThread
    in
    Ui.row
        [ Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
        , Ui.attrIf
            (not isMobile)
            (Ui.Events.onMouseEnter (MouseEnteredDiscordChannelName routeData.guildId channelId NoThread))
        , Ui.attrIf
            (not isMobile)
            (Ui.Events.onMouseLeave (MouseExitedDiscordChannelName routeData.guildId channelId NoThread))
        , Ui.clipWithEllipsis
        , Ui.height (Ui.px MyUi.channelHeaderHeight)
        , MyUi.hoverText (ChannelName.toString channel.name)
        , Ui.contentCenterY
        , MyUi.noShrinking
        ]
        [ elLinkButton
            (Dom.id ("guild_openChannel_" ++ Discord.idToString channelId))
            (DiscordGuildRoute
                { currentDiscordUserId = routeData.currentDiscordUserId
                , guildId = routeData.guildId
                , channelRoute =
                    DiscordChannel_ChannelRoute
                        channelId
                        (NoThreadWithFriends Nothing HideMembersTab)
                        Nothing
                }
            )
            [ Ui.height Ui.fill
            , Ui.contentCenterY
            , Ui.paddingWith
                { left = 26
                , right =
                    if isHover then
                        0

                    else
                        8
                , top = 0
                , bottom = 0
                }
            , Ui.el
                [ (if isSelected && not isMobile then
                    NoNotification

                   else
                    hasNotifications
                  )
                    |> GuildIcon.notificationView 0 -3 MyUi.background2
                , Ui.width (Ui.px 20)
                , Ui.move { x = 4, y = 0, z = 0 }
                , Ui.centerY
                ]
                (Ui.html Icons.hashtag)
                |> Ui.inFront
            , if isSelected then
                Ui.Font.color MyUi.font1

              else
                Ui.Font.color MyUi.font3
            , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
            ]
            (Ui.text (ChannelName.toString channel.name))
        , if isHover then
            elLinkButton
                (Dom.id ("guild_editChannel_" ++ Discord.idToString channelId))
                (DiscordGuildRoute
                    { currentDiscordUserId = routeData.currentDiscordUserId
                    , guildId = routeData.guildId
                    , channelRoute = DiscordChannel_EditChannelRoute channelId
                    }
                )
                [ Ui.alignRight
                , Ui.width (Ui.px 26)
                , Ui.contentCenterY
                , Ui.height Ui.fill
                , Ui.paddingWith { left = 0, right = 2, top = 0, bottom = 0 }
                , Ui.Font.color MyUi.font3
                , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
                ]
                (Ui.html Icons.gear)

          else
            Ui.none
        ]


friendsColumnLazy :
    Bool
    -> Bool
    -> Time.Posix
    -> DmChannelSelection
    -> LocalState
    -> Element FrontendMsg
friendsColumnLazy canScroll2 isMobile currentTime openedOtherUserId local =
    let
        msInMinute =
            1000 * 60

        currentTimeRoundedToMinute : Int
        currentTimeRoundedToMinute =
            Time.posixToMillis currentTime // msInMinute |> (*) msInMinute
    in
    case openedOtherUserId of
        NoDmChannelSelected ->
            Ui.Lazy.lazy6
                friendsColumn_NoDmChannelSelected
                canScroll2
                isMobile
                currentTimeRoundedToMinute
                local.dmChannels
                local.discordDmChannels
                local.localUser

        SelectedDmChannel dmRouteData ->
            Ui.Lazy.lazy6
                (if isMobile then
                    friendsColumn_SelectedDmChannel_Mobile

                 else
                    friendsColumn_SelectedDmChannel_NotMobile
                )
                canScroll2
                currentTimeRoundedToMinute
                dmRouteData
                local.dmChannels
                local.discordDmChannels
                local.localUser

        SelectedDiscordDmChannel discordDmRouteData ->
            Ui.Lazy.lazy6
                (if isMobile then
                    friendsColumn_SelectedDiscordDmChannel_Mobile

                 else
                    friendsColumn_SelectedDiscordDmChannel_NotMobile
                )
                canScroll2
                currentTimeRoundedToMinute
                discordDmRouteData
                local.dmChannels
                local.discordDmChannels
                local.localUser


friendsColumn_NoDmChannelSelected : Bool -> Bool -> Int -> SeqDict (Id UserId) FrontendDmChannel -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel -> LocalUser -> Element FrontendMsg
friendsColumn_NoDmChannelSelected canScroll2 isMobile currentTime dmChannels discordDmChannels localUser =
    friendsColumn canScroll2 isMobile currentTime NoDmChannelSelected dmChannels discordDmChannels localUser


friendsColumn_SelectedDiscordDmChannel_Mobile : Bool -> Int -> DiscordDmRouteData -> SeqDict (Id UserId) FrontendDmChannel -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel -> LocalUser -> Element FrontendMsg
friendsColumn_SelectedDiscordDmChannel_Mobile canScroll2 currentTime discordDmRoute dmChannels discordDmChannels localUser =
    friendsColumn canScroll2 True currentTime (SelectedDiscordDmChannel discordDmRoute) dmChannels discordDmChannels localUser


friendsColumn_SelectedDiscordDmChannel_NotMobile : Bool -> Int -> DiscordDmRouteData -> SeqDict (Id UserId) FrontendDmChannel -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel -> LocalUser -> Element FrontendMsg
friendsColumn_SelectedDiscordDmChannel_NotMobile canScroll2 currentTime discordDmRoute dmChannels discordDmChannels localUser =
    friendsColumn canScroll2 False currentTime (SelectedDiscordDmChannel discordDmRoute) dmChannels discordDmChannels localUser


friendsColumn_SelectedDmChannel_Mobile : Bool -> Int -> DmRouteData -> SeqDict (Id UserId) FrontendDmChannel -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel -> LocalUser -> Element FrontendMsg
friendsColumn_SelectedDmChannel_Mobile canScroll2 currentTime dmRoute dmChannels discordDmChannels localUser =
    friendsColumn canScroll2 True currentTime (SelectedDmChannel dmRoute) dmChannels discordDmChannels localUser


friendsColumn_SelectedDmChannel_NotMobile : Bool -> Int -> DmRouteData -> SeqDict (Id UserId) FrontendDmChannel -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel -> LocalUser -> Element FrontendMsg
friendsColumn_SelectedDmChannel_NotMobile canScroll2 currentTime dmRoute dmChannels discordDmChannels localUser =
    friendsColumn canScroll2 False currentTime (SelectedDmChannel dmRoute) dmChannels discordDmChannels localUser


friendsColumn :
    Bool
    -> Bool
    -> Int
    -> DmChannelSelection
    -> SeqDict (Id UserId) FrontendDmChannel
    -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel
    -> LocalUser
    -> Element FrontendMsg
friendsColumn canScroll2 isMobile currentTime openedOtherUserId dmChannels discordDmChannels localUser =
    let
        _ =
            Debug.log "friendsColumn rerendered" ()

        dmChannelsIncludingCurrentUser : SeqDict (Id UserId) FrontendDmChannel
        dmChannelsIncludingCurrentUser =
            SeqDict.update
                localUser.session.userId
                (\maybe -> Maybe.withDefault DmChannel.frontendInit maybe |> Just)
                dmChannels

        discordDmChannelsIncludingLinkedUsers : SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel
        discordDmChannelsIncludingLinkedUsers =
            discordDmChannels
    in
    channelColumnContainer
        [ Ui.el
            [ Ui.Font.bold
            , Ui.paddingXY 8 8
            , Ui.Font.color MyUi.font1
            ]
            (Ui.text "Direct messages")
        ]
        ((List.filterMap
            (\( otherUserId, dmChannel ) ->
                case User.getUser otherUserId localUser of
                    Just otherUser ->
                        ( case Array.Extra.last dmChannel.messages of
                            Just (MessageLoaded message2) ->
                                Message.createdAt message2

                            _ ->
                                Time.millisToPosix 0
                        , Ui.Lazy.lazy6
                            (if isMobile then
                                friendLabelMobile

                             else
                                friendLabelNotMobile
                            )
                            currentTime
                            (case openedOtherUserId of
                                SelectedDmChannel dmRoute ->
                                    DmChannel.otherUserId localUser.session.userId dmRoute.channelId == Just otherUserId

                                _ ->
                                    False
                            )
                            localUser
                            otherUserId
                            otherUser
                            dmChannel
                        )
                            |> Just

                    Nothing ->
                        Nothing
            )
            (SeqDict.toList dmChannelsIncludingCurrentUser)
            ++ List.map
                (\( channelId, dmChannel ) ->
                    ( case Array.Extra.last dmChannel.messages of
                        Just (MessageLoaded message2) ->
                            Message.createdAt message2

                        _ ->
                            Time.millisToPosix 0
                    , Ui.Lazy.lazy5
                        (if isMobile then
                            discordFriendLabelMobile

                         else
                            discordFriendLabelNotMobile
                        )
                        currentTime
                        (case openedOtherUserId of
                            SelectedDiscordDmChannel routeData ->
                                routeData.channelId == channelId

                            _ ->
                                False
                        )
                        channelId
                        dmChannel
                        localUser
                    )
                )
                (SeqDict.toList discordDmChannelsIncludingLinkedUsers)
         )
            |> List.sortBy (\( time, _ ) -> Time.posixToMillis time |> negate)
            |> List.map Tuple.second
            |> Ui.column [ scrollable canScroll2, Ui.heightMin 0 ]
        )


friendLabelMobile :
    Int
    -> Bool
    -> LocalUser
    -> Id UserId
    -> FrontendUser
    -> FrontendDmChannel
    -> Element FrontendMsg
friendLabelMobile time isSelected localUser otherUserId otherUser channel =
    friendLabel True (Time.millisToPosix time) isSelected localUser otherUserId otherUser channel


friendLabelNotMobile :
    Int
    -> Bool
    -> LocalUser
    -> Id UserId
    -> FrontendUser
    -> FrontendDmChannel
    -> Element FrontendMsg
friendLabelNotMobile time isSelected localUser otherUserId otherUser channel =
    friendLabel False (Time.millisToPosix time) isSelected localUser otherUserId otherUser channel


type SomeoneIsTyping
    = SomeoneIsTyping
    | SomeoneIsEditing
    | NoOneIsTyping


someoneIsTyping : Time.Posix -> SeqDict userId (LastTypedAt messageId) -> SomeoneIsTyping
someoneIsTyping time lastTypedAt =
    SeqDict.foldl
        (\_ a state ->
            case state of
                SomeoneIsTyping ->
                    state

                _ ->
                    if Duration.from a.time time |> Quantity.lessThan (Quantity.plus Duration.second typingDebouncerDelay) then
                        case a.messageIndex of
                            Just _ ->
                                SomeoneIsEditing

                            Nothing ->
                                SomeoneIsTyping

                    else
                        state
        )
        NoOneIsTyping
        lastTypedAt


friendLabel :
    Bool
    -> Time.Posix
    -> Bool
    -> LocalUser
    -> Id UserId
    -> FrontendUser
    -> FrontendDmChannel
    -> Element FrontendMsg
friendLabel isMobile time isSelected localUser otherUserId otherUser channel =
    let
        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            LocalState.allUsers localUser

        message : MessageState ChannelMessageId (Id UserId)
        message =
            Array.Extra.last channel.messages |> Maybe.withDefault MessageUnloaded

        messagePreview : String
        messagePreview =
            case someoneIsTyping time (SeqDict.remove localUser.session.userId channel.lastTypedAt) of
                SomeoneIsTyping ->
                    "Typing..."

                SomeoneIsEditing ->
                    "Editing..."

                NoOneIsTyping ->
                    case message of
                        MessageLoaded message2 ->
                            case message2 of
                                UserTextMessage a ->
                                    (if a.createdBy == localUser.session.userId then
                                        "You: "

                                     else
                                        ""
                                    )
                                        ++ RichText.toString True allUsers a.content

                                UserJoinedMessage _ userId _ _ ->
                                    User.toString userId allUsers
                                        ++ " joined!"

                                DeletedMessage _ ->
                                    LocalState.messageDeleted

                                CallStarted _ endedAt _ _ _ ->
                                    LocalState.callStartedText endedAt

                                GameStarted _ _ _ _ game ->
                                    LocalState.gameStartedText game

                        MessageUnloaded ->
                            ""
    in
    rowLinkButton
        (Dom.id ("guild_friendLabel_" ++ Id.toString otherUserId))
        (Route.DmRoute
            { channelId = DmChannel.channelIdFromUserIds localUser.session.userId otherUserId
            , threadRoute = NoThreadWithFriends Nothing HideMembersTab
            , tab = Nothing
            }
        )
        [ Ui.clipWithEllipsis
        , Ui.spacing 8
        , Ui.padding 4
        , MyUi.hoverText messagePreview
        , Ui.Font.color
            (if isSelected then
                MyUi.font1

             else
                MyUi.font3
            )
        , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
        , Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
        ]
        [ User.profileImage otherUserId otherUser.icon
        , Ui.column
            []
            [ Ui.el [ Ui.Font.bold ] (Ui.text (PersonName.toString otherUser.name))
            , friendLabelMessagePreview time messagePreview message
            ]
        ]


friendLabelMessagePreview : Time.Posix -> String -> MessageState messageId userId -> Element msg
friendLabelMessagePreview time messagePreview message =
    Ui.row
        [ Ui.Font.size 13, Ui.spacing 4 ]
        [ Ui.el [] (Ui.text messagePreview)
        , case message of
            MessageLoaded message2 ->
                MyUi.timeElapsedShort time (Message.createdAt message2)
                    |> Ui.text
                    |> Ui.el [ Ui.alignRight, Ui.Font.italic, Ui.opacity 0.7 ]

            MessageUnloaded ->
                Ui.none
        ]


discordFriendLabelMobile :
    Int
    -> Bool
    -> Discord.Id Discord.PrivateChannelId
    -> DiscordFrontendDmChannel
    -> LocalUser
    -> Element FrontendMsg
discordFriendLabelMobile time isSelected dmChannelId channel localUser =
    discordFriendLabel True (Time.millisToPosix time) isSelected dmChannelId channel localUser


discordFriendLabelNotMobile :
    Int
    -> Bool
    -> Discord.Id Discord.PrivateChannelId
    -> DiscordFrontendDmChannel
    -> LocalUser
    -> Element FrontendMsg
discordFriendLabelNotMobile time isSelected dmChannelId channel localUser =
    discordFriendLabel False (Time.millisToPosix time) isSelected dmChannelId channel localUser


discordFriendLabel :
    Bool
    -> Time.Posix
    -> Bool
    -> Discord.Id Discord.PrivateChannelId
    -> DiscordFrontendDmChannel
    -> LocalUser
    -> Element FrontendMsg
discordFriendLabel isMobile time isSelected dmChannelId channel localUser =
    let
        _ =
            Debug.log "rerender discord friendLabel" ()

        message : MessageState ChannelMessageId (Discord.Id Discord.UserId)
        message =
            Array.Extra.last channel.messages |> Maybe.withDefault MessageUnloaded

        messagePreview : String
        messagePreview =
            case someoneIsTyping time (SeqDict.diff channel.lastTypedAt (LinkedAndOtherDiscordUsers.linkedUsers localUser.discordUsers)) of
                SomeoneIsTyping ->
                    "Typing..."

                SomeoneIsEditing ->
                    "Editing..."

                NoOneIsTyping ->
                    case message of
                        MessageLoaded message2 ->
                            case message2 of
                                UserTextMessage a ->
                                    (if LinkedAndOtherDiscordUsers.isLinkedUser a.createdBy localUser.discordUsers then
                                        "You: "

                                     else
                                        ""
                                    )
                                        ++ RichText.toString
                                            True
                                            (LinkedAndOtherDiscordUsers.allDiscordUsers localUser.discordUsers)
                                            a.content

                                UserJoinedMessage _ userId _ _ ->
                                    User.toString
                                        userId
                                        (LinkedAndOtherDiscordUsers.allDiscordUsers localUser.discordUsers)
                                        ++ " joined!"

                                DeletedMessage _ ->
                                    LocalState.messageDeleted

                                CallStarted _ endedAt _ _ _ ->
                                    LocalState.callStartedText endedAt

                                GameStarted _ _ _ _ game ->
                                    LocalState.gameStartedText game

                        MessageUnloaded ->
                            ""

        maybeCurrentUserId : Maybe (Discord.Id Discord.UserId)
        maybeCurrentUserId =
            List.Extra.findMap
                (\( userId, _ ) ->
                    if NonemptyDict.member userId channel.members then
                        Just userId

                    else
                        Nothing
                )
                (SeqDict.toList (LinkedAndOtherDiscordUsers.linkedUsers localUser.discordUsers))
    in
    case maybeCurrentUserId of
        Just currentUserId ->
            let
                members2 : List (Discord.Id Discord.UserId)
                members2 =
                    NonemptyDict.remove currentUserId channel.members |> SeqDict.keys

                notification : ChannelNotificationType
                notification =
                    if isSelected then
                        NoNotification

                    else
                        case discordDmHasNotifications localUser dmChannelId channel of
                            Just ( _, count ) ->
                                NewMessageForUser count

                            Nothing ->
                                NoNotification
            in
            MyUi.rowButton
                ("guild_discordFriendLabel_" ++ Discord.idToString dmChannelId |> Dom.id)
                (PressedLink
                    (DiscordDmRoute
                        { currentDiscordUserId = currentUserId
                        , channelId = dmChannelId
                        , viewingMessage = Nothing
                        , showMembersTab = HideMembersTab
                        , tab = Nothing
                        }
                    )
                )
                [ Ui.clipWithEllipsis
                , Ui.spacing 8
                , MyUi.hoverText messagePreview
                , Ui.padding 4
                , Ui.Font.color
                    (if isSelected then
                        MyUi.font1

                     else
                        MyUi.font3
                    )
                , MyUi.hover isMobile [ Ui.Anim.fontColor MyUi.font1 ]
                , Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
                ]
                (case members2 of
                    [] ->
                        case User.getDiscordUser currentUserId localUser of
                            Just otherUser ->
                                [ Ui.el
                                    [ GuildIcon.notificationView 4 -3 MyUi.background2 notification, Ui.width Ui.shrink ]
                                    (User.discordProfileImage currentUserId otherUser.icon)
                                , Ui.column
                                    []
                                    [ Ui.el [ Ui.Font.bold ] (Ui.text (PersonName.toString otherUser.name))
                                    , friendLabelMessagePreview time messagePreview message
                                    ]
                                ]

                            Nothing ->
                                []

                    rest ->
                        [ List.filterMap
                            (\userId ->
                                case User.getDiscordUser userId localUser of
                                    Just user ->
                                        Just ( userId, user.icon )

                                    Nothing ->
                                        Nothing
                            )
                            members2
                            |> User.multipleProfileImages
                            |> Ui.el [ GuildIcon.notificationView 4 -3 MyUi.background2 notification, Ui.width Ui.shrink ]
                        , Ui.column
                            []
                            [ List.filterMap
                                (\userId ->
                                    case User.getDiscordUser userId localUser of
                                        Just otherUser ->
                                            PersonName.toString otherUser.name |> Just

                                        Nothing ->
                                            Nothing
                                )
                                rest
                                |> String.join ", "
                                |> Ui.text
                                |> Ui.el [ Ui.Font.bold ]
                            , friendLabelMessagePreview time messagePreview message
                            ]
                        ]
                )

        Nothing ->
            Ui.text "Something went wrong"


newChannelFormInit : NewChannelForm
newChannelFormInit =
    { name = "", description = "", pressedSubmit = False }


newGuildFormInit : NewGuildForm
newGuildFormInit =
    { name = "", pressedSubmit = False }


editChannelFormInit : FrontendChannel -> EditChannelForm
editChannelFormInit channel =
    { name = ChannelName.toString channel.name
    , description = ChannelDescription.toString channel.description
    , deleteConfirmation = ""
    , showDeleteConfirmation = False
    , pressedSubmit = False
    }


editChannelFormView : Bool -> Id GuildId -> Id ChannelId -> FrontendChannel -> EditChannelForm -> Element FrontendMsg
editChannelFormView isMobile2 guildId channelId channel form =
    let
        isEmpty : Bool
        isEmpty =
            Array.isEmpty channel.messages

        channelNameString : String
        channelNameString =
            ChannelName.toString channel.name

        channelDescriptionString : String
        channelDescriptionString =
            ChannelDescription.toString channel.description

        hasChanges : Bool
        hasChanges =
            form.name /= channelNameString || form.description /= channelDescriptionString

        confirmationMatches : Bool
        confirmationMatches =
            form.deleteConfirmation == channelNameString

        ( deleteOnPress, deleteEnabled ) =
            if isEmpty then
                ( PressedDeleteChannel guildId channelId, True )

            else if not form.showDeleteConfirmation then
                ( EditChannelFormChanged guildId channelId { form | showDeleteConfirmation = True }, True )

            else if confirmationMatches then
                ( PressedDeleteChannel guildId channelId, True )

            else
                ( FrontendNoOp, False )
    in
    Ui.column
        [ Ui.Font.color MyUi.font1, Ui.alignTop ]
        [ ChannelHeader.channelHeader isMobile2 False (Ui.text ("Edit #" ++ channelNameString)) Nothing
        , Ui.column
            [ Ui.padding 16, Ui.spacing 16 ]
            [ channelNameInput form |> Ui.map (EditChannelFormChanged guildId channelId)
            , channelDescriptionInput form |> Ui.map (EditChannelFormChanged guildId channelId)
            , if hasChanges then
                Ui.row
                    [ Ui.spacing 16 ]
                    [ MyUi.elButton
                        (Dom.id "guild_resetEditChannel")
                        (PressedResetEditChannelChanges guildId channelId)
                        [ Ui.paddingXY 16 8
                        , Ui.background MyUi.cancelButtonBackground
                        , Ui.width Ui.shrink
                        , Ui.rounded 8
                        , Ui.Font.color MyUi.buttonFontColor
                        , Ui.Font.bold
                        , Ui.borderColor MyUi.buttonBorder
                        , Ui.border 1
                        ]
                        (Ui.text "Reset")
                    , submitButton
                        (Dom.id "guild_submitEditChannel")
                        (PressedSubmitEditChannelChanges guildId channelId form)
                        "Save changes"
                    ]

              else
                Ui.none
            , Ui.el [ Ui.height (Ui.px 1), Ui.background MyUi.border2 ] Ui.none
            , if not isEmpty && form.showDeleteConfirmation then
                deleteConfirmationInput channelNameString form
                    |> Ui.map (EditChannelFormChanged guildId channelId)

              else
                Ui.none
            , MyUi.elButton
                (Dom.id "guild_deleteChannel")
                deleteOnPress
                [ Ui.paddingXY 16 8
                , Ui.background
                    (if deleteEnabled then
                        MyUi.deleteButtonBackground

                     else
                        MyUi.disabledButtonBackground
                    )
                , Ui.width Ui.shrink
                , Ui.rounded 8
                , Ui.Font.color MyUi.deleteButtonFont
                , Ui.Font.bold
                , Ui.borderColor MyUi.buttonBorder
                , Ui.border 1
                ]
                (Ui.text "Delete channel")
            ]
        ]


deleteConfirmationInput : String -> EditChannelForm -> Element EditChannelForm
deleteConfirmationInput channelNameString form =
    let
        confirmLabel =
            Ui.Input.label
                "deleteChannelConfirmation"
                [ Ui.Font.color MyUi.font2, Ui.paddingXY 2 0 ]
                (Ui.text ("Type \"" ++ channelNameString ++ "\" to confirm deletion"))
    in
    Ui.column
        []
        [ confirmLabel.element
        , Ui.Input.text
            [ Ui.padding 6
            , Ui.background MyUi.inputBackground
            , Ui.borderColor MyUi.inputBorder
            , Ui.widthMax 500
            ]
            { onChange = \text -> { form | deleteConfirmation = text }
            , text = form.deleteConfirmation
            , placeholder = Nothing
            , label = confirmLabel.id
            }
        ]


newChannelFormView : Bool -> Id GuildId -> NewChannelForm -> Element FrontendMsg
newChannelFormView isMobile2 guildId form =
    Ui.column
        [ Ui.Font.color MyUi.font1, Ui.alignTop ]
        [ ChannelHeader.channelHeader isMobile2 False (Ui.text "Create new channel") Nothing
        , Ui.column
            [ Ui.spacing 16, Ui.padding 16 ]
            [ channelNameInput form |> Ui.map (NewChannelFormChanged guildId)
            , channelDescriptionInput form |> Ui.map (NewChannelFormChanged guildId)
            , submitButton (Dom.id "guild_createChannel") (PressedSubmitNewChannel guildId form) "Create channel"
            ]
        ]


submitButton : HtmlId -> msg -> String -> Element msg
submitButton htmlId onPress text =
    MyUi.elButton
        htmlId
        onPress
        [ Ui.paddingXY 16 8
        , Ui.background MyUi.buttonBackground
        , Ui.width Ui.shrink
        , Ui.rounded 8
        , Ui.Font.bold
        , Ui.borderColor MyUi.buttonBorder
        , Ui.border 1
        ]
        (Ui.text text)


channelNameInput : { a | name : String, pressedSubmit : Bool } -> Element { a | name : String, pressedSubmit : Bool }
channelNameInput form =
    let
        nameLabel =
            Ui.Input.label
                "newChannelName"
                [ Ui.Font.color MyUi.font2, Ui.paddingXY 2 0 ]
                (Ui.text "Channel name")
    in
    Ui.column
        []
        [ nameLabel.element
        , Ui.Input.text
            [ Ui.padding 6
            , Ui.background MyUi.inputBackground
            , Ui.borderColor MyUi.inputBorder
            , Ui.widthMax 500
            ]
            { onChange = \text -> { form | name = text }
            , text = form.name
            , placeholder = Nothing
            , label = nameLabel.id
            }
        , case ( form.pressedSubmit, ChannelName.fromString form.name ) of
            ( True, Err error ) ->
                Ui.el [ Ui.paddingXY 2 0, Ui.Font.color MyUi.errorColor ] (Ui.text error)

            _ ->
                Ui.none
        ]


channelDescriptionInput : { a | description : String, pressedSubmit : Bool } -> Element { a | description : String, pressedSubmit : Bool }
channelDescriptionInput form =
    let
        descriptionLabel =
            Ui.Input.label
                "channelDescription"
                [ Ui.Font.color MyUi.font2, Ui.paddingXY 2 0 ]
                (Ui.text "Channel description")
    in
    Ui.column
        []
        [ descriptionLabel.element
        , Ui.Input.multiline
            [ Ui.padding 6
            , Ui.background MyUi.inputBackground
            , Ui.borderColor MyUi.inputBorder
            , Ui.widthMax 500
            ]
            { onChange = \text -> { form | description = text }
            , text = form.description
            , placeholder = Nothing
            , label = descriptionLabel.id
            , spellcheck = True
            }
        , case ( form.pressedSubmit, ChannelDescription.fromString form.description ) of
            ( True, Err error ) ->
                Ui.el [ Ui.paddingXY 2 0, Ui.Font.color MyUi.errorColor ] (Ui.text error)

            _ ->
                Ui.none
        ]


newGuildFormView : NewGuildForm -> Element FrontendMsg
newGuildFormView form =
    Ui.column
        [ Ui.Font.color MyUi.font1
        , Ui.paddingXY 0 16
        , Ui.alignTop
        , Ui.spacing 16
        , Ui.height Ui.fill
        , Ui.background MyUi.background1
        , MyUi.htmlStyle "padding-top" MyUi.insetTop
        ]
        [ Ui.el [ Ui.Font.size 24, Ui.paddingXY 16 0 ] (Ui.text "Create new guild")
        , guildNameInput form |> Ui.map NewGuildFormChanged
        , Ui.row
            [ Ui.spacing 16, Ui.paddingXY 16 0 ]
            [ MyUi.elButton
                (Dom.id "guild_cancelNewGuild")
                PressedCancelNewGuild
                [ Ui.paddingXY 16 8
                , Ui.background MyUi.cancelButtonBackground
                , Ui.width Ui.shrink
                , Ui.rounded 8
                , Ui.Font.color MyUi.buttonFontColor
                , Ui.Font.bold
                , Ui.borderColor MyUi.buttonBorder
                , Ui.border 1
                ]
                (Ui.text "Cancel")
            , submitButton (Dom.id "guild_createGuildSubmit") (PressedSubmitNewGuild form) "Create guild"
            ]
        ]


guildNameInput : NewGuildForm -> Element NewGuildForm
guildNameInput form =
    let
        nameLabel =
            Ui.Input.label
                "newGuildName"
                [ Ui.Font.color MyUi.font2, Ui.paddingXY 2 0 ]
                (Ui.text "Guild name")
    in
    Ui.column
        [ Ui.paddingXY 16 0 ]
        [ nameLabel.element
        , Ui.Input.text
            [ Ui.padding 6
            , Ui.background MyUi.inputBackground
            , Ui.borderColor MyUi.inputBorder
            , Ui.widthMax 500
            ]
            { onChange = \text -> { form | name = text }
            , text = form.name
            , placeholder = Nothing
            , label = nameLabel.id
            }
        , case ( form.pressedSubmit, GuildName.fromString form.name ) of
            ( True, Err error ) ->
                Ui.el [ Ui.paddingXY 2 0, Ui.Font.color MyUi.errorColor ] (Ui.text error)

            _ ->
                Ui.none
        ]


fileUploadPreview :
    (Id FileId -> msg)
    -> (Id FileId -> msg)
    -> ({ fileId : Id FileId, removeSpoiler : Bool } -> msg)
    -> Maybe (Nonempty (RichText userId))
    -> NonemptyDict (Id FileId) FileStatus
    -> Element msg
fileUploadPreview onPressDelete onPressInfo onPressSpoiler richText filesToUpload2 =
    let
        previewSize : number
        previewSize =
            150

        isSpoilered : SeqDict (Id FileId) Bool
        isSpoilered =
            case richText of
                Just richText2 ->
                    RichText.attachments richText2
                        |> List.map (\a -> ( a.attachmentId, a.isSpoilered ))
                        |> SeqDict.fromList

                Nothing ->
                    SeqDict.empty
    in
    Ui.row
        [ Ui.spacing 2
        , Ui.move { x = 0, y = -previewSize, z = 0 }
        , Ui.width Ui.shrink
        , Ui.paddingXY 8 0
        ]
        (List.map
            (\( fileStatusId, fileStatus ) ->
                let
                    isSpoilered2 : Bool
                    isSpoilered2 =
                        SeqDict.get fileStatusId isSpoilered |> Maybe.withDefault False
                in
                Ui.el
                    [ Ui.width (Ui.px previewSize)
                    , Ui.height (Ui.px previewSize)
                    , Ui.Shadow.shadows
                        [ { x = 0
                          , y = -2
                          , size = 0
                          , blur = 8
                          , color = Ui.rgba 0 0 0 0.5
                          }
                        ]
                    , Ui.background MyUi.background1
                    , Ui.borderColor MyUi.background1
                    , Ui.border 1
                    , Ui.rounded 8
                    , MyUi.elButton
                        (Dom.id ("fileStatus_delete_" ++ Id.toString fileStatusId))
                        (onPressDelete fileStatusId)
                        [ Ui.width (Ui.px 42)
                        , Ui.height (Ui.px 42)
                        , Ui.rounded 16
                        , Ui.move { x = -3, y = -3, z = 0 }
                        ]
                        (Ui.el
                            [ Ui.width (Ui.px 34)
                            , Ui.height (Ui.px 34)
                            , Ui.rounded 16
                            , Ui.contentCenterX
                            , Ui.contentCenterY
                            , Ui.background MyUi.deleteButtonBackground
                            ]
                            (Ui.html Icons.delete)
                        )
                        |> Ui.inFront
                    , MyUi.elButton
                        (Dom.id ("fileStatus_spoiler_" ++ Id.toString fileStatusId))
                        (onPressSpoiler { fileId = fileStatusId, removeSpoiler = isSpoilered2 })
                        [ Ui.width (Ui.px 42)
                        , Ui.height (Ui.px 42)
                        , Ui.rounded 16
                        , Ui.move { x = -3, y = 40, z = 0 }
                        ]
                        (Ui.el
                            [ Ui.width (Ui.px 34)
                            , Ui.height (Ui.px 34)
                            , Ui.rounded 16
                            , Ui.contentCenterX
                            , Ui.contentCenterY
                            , Ui.background MyUi.buttonBackground
                            ]
                            (Ui.html
                                (if isSpoilered2 then
                                    Icons.closedEye

                                 else
                                    Icons.openEye
                                )
                            )
                        )
                        |> Ui.inFront
                    , case fileStatus of
                        FileStatus.FileUploaded fileData ->
                            case fileData.imageMetadata of
                                Just metadata ->
                                    if FileStatus.imageHasMetadata metadata then
                                        MyUi.elButton
                                            (Dom.id ("fileStatus_info_" ++ Id.toString fileStatusId))
                                            (onPressInfo fileStatusId)
                                            [ Ui.width (Ui.px 42)
                                            , Ui.height (Ui.px 42)
                                            , Ui.rounded 16
                                            , Ui.move { x = -3, y = 77, z = 0 }
                                            ]
                                            (Ui.el
                                                [ Ui.width (Ui.px 34)
                                                , Ui.height (Ui.px 34)
                                                , Ui.rounded 16
                                                , Ui.contentCenterX
                                                , Ui.contentCenterY
                                                , Ui.background MyUi.buttonBackground
                                                ]
                                                (case metadata.gpsLocation of
                                                    Just _ ->
                                                        Ui.html Icons.map

                                                    Nothing ->
                                                        Ui.html Icons.info
                                                )
                                            )
                                            |> Ui.inFront

                                    else
                                        Ui.noAttr

                                Nothing ->
                                    Ui.noAttr

                        FileStatus.FileUploading _ _ _ ->
                            Ui.noAttr

                        FileStatus.FileError _ _ _ _ ->
                            Ui.noAttr
                    , Ui.el
                        [ Ui.alignBottom
                        , Ui.padding 4
                        , Ui.Font.bold
                        , Ui.Shadow.font
                            { offset = ( 0, 0 )
                            , blur = 3
                            , color = Ui.rgb 0 0 0
                            }
                        ]
                        (Ui.text ("[!" ++ Id.toString fileStatusId ++ "]"))
                        |> Ui.inFront
                    , case fileStatus of
                        FileStatus.FileUploading _ fileSize _ ->
                            FileStatus.progressToString fileSize
                                |> Ui.text
                                |> Ui.el
                                    [ Ui.alignRight
                                    , Ui.Font.size 14
                                    , Ui.paddingRight 8
                                    , Ui.Shadow.font
                                        { offset = ( 0, 0 )
                                        , blur = 3
                                        , color = Ui.rgb 0 0 0
                                        }
                                    ]
                                |> Ui.inFront

                        FileStatus.FileUploaded _ ->
                            Ui.noAttr

                        FileStatus.FileError _ _ _ _ ->
                            Ui.noAttr
                    ]
                    (case fileStatus of
                        FileStatus.FileUploading _ _ _ ->
                            Ui.none

                        FileStatus.FileUploaded fileData ->
                            case FileStatus.contentTypeType fileData.contentType of
                                FileStatus.Image ->
                                    Html.img
                                        [ Html.Attributes.src
                                            (case fileData.imageMetadata of
                                                Just metadata ->
                                                    FileStatus.thumbnailUrl metadata.imageSize fileData.contentType fileData.fileHash

                                                Nothing ->
                                                    FileStatus.fileUrl fileData.contentType fileData.fileHash
                                            )
                                        , Html.Attributes.style "object-fit" "cover"
                                        , Html.Attributes.width (previewSize - 2)
                                        , Html.Attributes.height (previewSize - 2)
                                        , Html.Attributes.style "display" "flex"
                                        , Html.Attributes.style "align-self" "center"
                                        , Html.Attributes.style "border-radius" "8px"
                                        ]
                                        []
                                        |> Ui.html

                                FileStatus.Text ->
                                    Ui.el
                                        [ Ui.width (Ui.px 42)
                                        , Ui.centerX
                                        , Ui.centerY
                                        , Ui.Font.color MyUi.font3
                                        ]
                                        (Ui.html Icons.document)

                                FileStatus.Video ->
                                    Ui.el
                                        [ Ui.centerX
                                        , Ui.centerY
                                        , Ui.Font.color MyUi.font3
                                        , Ui.move { x = 6, y = 0, z = 0 }
                                        ]
                                        (Ui.html (Icons.camera 42))

                                FileStatus.Audio ->
                                    Ui.el
                                        [ Ui.width (Ui.px 42)
                                        , Ui.centerX
                                        , Ui.centerY
                                        , Ui.Font.color MyUi.font3
                                        ]
                                        (Ui.html Icons.volume)

                                _ ->
                                    Ui.el
                                        [ Ui.Font.bold
                                        , Ui.Font.letterSpacing -1
                                        , Ui.Font.lineHeight 1.1
                                        , Ui.centerX
                                        , Ui.centerY
                                        , MyUi.prewrap
                                        , Ui.Font.color MyUi.font3
                                        ]
                                        (Ui.text "0110\n0001")

                        FileStatus.FileError _ _ _ _ ->
                            Ui.el
                                [ Ui.centerX
                                , Ui.centerY
                                , Ui.width Ui.shrink
                                ]
                                (Ui.html Icons.x)
                    )
            )
            (NonemptyDict.toList filesToUpload2)
        )
