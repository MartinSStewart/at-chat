module GuildColumn exposing
    ( canScroll
    , channelOrThreadHasNotifications
    , discordDmCurrentUserId
    , discordDmHasNotifications
    , discordGuildCurrentUserId
    , elLinkButton
    , guildColumnLazy
    , newMessageCount
    , rowLinkButton
    )

import Discord
import DmChannel exposing (DiscordFrontendDmChannel, FrontendDmChannel)
import DmChannelId
import Effect.Browser.Dom as Dom exposing (HtmlId)
import FileStatus exposing (FileHash)
import GuildIcon exposing (ChannelNotificationType(..))
import Html.Attributes
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, ThreadMessageId, ThreadRoute(..), UserId)
import LinkedAndOtherDiscordUsers
import List.Extra
import LocalState exposing (DiscordFrontendGuild, FrontendGuild, LocalState)
import MembersAndOwner exposing (IsMember(..))
import Message exposing (Message)
import MessageArray exposing (MessageArray)
import MuteSettings exposing (IsMuted(..))
import MyUi
import NonemptyDict exposing (NonemptyDict)
import OneOrGreater exposing (OneOrGreater)
import Route exposing (ChannelRoute(..), DiscordChannelRoute(..), Route(..), ShowMembersTab(..), ThreadRouteWithFriends(..))
import SeqDict exposing (SeqDict)
import SeqSet
import Types exposing (Drag(..), FrontendMsg_(..), LoadedFrontend)
import Ui exposing (Element)
import Ui.Gradient
import Ui.Lazy
import User exposing (FrontendCurrentUser, LocalUser)


canScroll : Bool -> Drag -> Bool
canScroll isMobile drag =
    if isMobile then
        case drag of
            Dragging dragging ->
                not dragging.horizontalStart

            _ ->
                True

    else
        -- On desktop there's no horizontal drag gesture, so keep scrolling
        -- enabled to stop scrollbars flickering while other drags happen.
        True


guildColumnLazy : Bool -> LoadedFrontend -> LocalState -> Element FrontendMsg_
guildColumnLazy isMobile model local =
    Ui.Lazy.lazy6
        (case ( canScroll isMobile model.drag, isMobile ) of
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
    -> Element FrontendMsg_
guildColumnCanScrollMobile route localUser dmChannels discordDmChannels guilds discordGuilds =
    guildColumn True route localUser dmChannels discordDmChannels guilds discordGuilds True


guildColumnCanScrollNotMobile :
    Route
    -> LocalUser
    -> SeqDict (Id UserId) FrontendDmChannel
    -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel
    -> SeqDict (Id GuildId) FrontendGuild
    -> SeqDict (Discord.Id Discord.GuildId) DiscordFrontendGuild
    -> Element FrontendMsg_
guildColumnCanScrollNotMobile route localUser dmChannels discordDmChannels guilds discordGuilds =
    guildColumn False route localUser dmChannels discordDmChannels guilds discordGuilds True


guildColumnCannotScrollMobile :
    Route
    -> LocalUser
    -> SeqDict (Id UserId) FrontendDmChannel
    -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel
    -> SeqDict (Id GuildId) FrontendGuild
    -> SeqDict (Discord.Id Discord.GuildId) DiscordFrontendGuild
    -> Element FrontendMsg_
guildColumnCannotScrollMobile route localUser dmChannels discordDmChannels guilds discordGuilds =
    guildColumn True route localUser dmChannels discordDmChannels guilds discordGuilds False


guildColumnCannotScrollNotMobile :
    Route
    -> LocalUser
    -> SeqDict (Id UserId) FrontendDmChannel
    -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel
    -> SeqDict (Id GuildId) FrontendGuild
    -> SeqDict (Discord.Id Discord.GuildId) DiscordFrontendGuild
    -> Element FrontendMsg_
guildColumnCannotScrollNotMobile route localUser dmChannels discordDmChannels guilds discordGuilds =
    guildColumn False route localUser dmChannels discordDmChannels guilds discordGuilds False


guildColumn :
    Bool
    -> Route
    -> LocalUser
    -> SeqDict (Id UserId) FrontendDmChannel
    -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel
    -> SeqDict (Id GuildId) FrontendGuild
    -> SeqDict (Discord.Id Discord.GuildId) DiscordFrontendGuild
    -> Bool
    -> Element FrontendMsg_
guildColumn isMobile route localUser dmChannels discordDmChannels guilds discordGuilds canScroll2 =
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
            , Ui.width (Ui.px MyUi.guildIconFullWidth)
            , Ui.height Ui.fill
            , Ui.background MyUi.background1
            , MyUi.scrollable canScroll2
            , MyUi.htmlStyle "overflow-x" "hidden"
            , Ui.htmlAttribute (Html.Attributes.class "disable-scrollbars")
            , MyUi.htmlStyle "padding" ("calc(max(6px, " ++ MyUi.insetTop ++ ")) 0 4px 0")
            , MyUi.bounceScroll isMobile
            ]
            (List.map
                (\( otherUserId, dmChannel ) ->
                    Ui.Lazy.lazy4 dmGuildIcon route localUser otherUserId dmChannel
                )
                (SeqDict.toList dmChannels)
                ++ List.map
                    (\( channelId, dmChannel ) ->
                        Ui.Lazy.lazy4 discordDmGuildIcon route localUser channelId dmChannel
                    )
                    (SeqDict.toList discordDmChannels)
                ++ GuildIcon.showFriendsButton (route == HomePageRoute) (PressedLink HomePageRoute)
                :: List.map
                    (\( guildId, guild ) -> Ui.Lazy.lazy4 guildIcon localUser route guildId guild)
                    (SeqDict.toList guilds)
                ++ List.map
                    (\( guildId, guild ) -> Ui.Lazy.lazy4 discordGuildIcon localUser route guildId guild)
                    (SeqDict.toList discordGuilds)
                ++ [ GuildIcon.addGuildButton
                        (Dom.id "guild_createGuild")
                        (route == NewGuildRoute)
                        (PressedLink NewGuildRoute)
                   ]
            )
        )


{-| Find the linked Discord user that is a member of this Discord guild (i.e. "us").
-}
discordGuildCurrentUserId : LocalUser -> DiscordFrontendGuild -> Maybe (Discord.Id Discord.UserId)
discordGuildCurrentUserId localUser guild =
    SeqDict.filter
        (\linkedUserId _ ->
            MembersAndOwner.isMember linkedUserId guild.membersAndOwner /= IsNotMember
        )
        (LinkedAndOtherDiscordUsers.linkedUsers localUser.discordUsers)
        |> SeqDict.keys
        |> List.head


discordGuildIcon : LocalUser -> Route -> Discord.Id Discord.GuildId -> DiscordFrontendGuild -> Element FrontendMsg_
discordGuildIcon localUser route guildId guild =
    case discordGuildCurrentUserId localUser guild of
        Just discordUserId ->
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
                (GuildIcon.discordView
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

        Nothing ->
            Ui.none


guildIcon : LocalUser -> Route -> Id GuildId -> FrontendGuild -> Element FrontendMsg_
guildIcon localUser route guildId guild =
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


dmGuildIcon : Route -> LocalUser -> Id UserId -> FrontendDmChannel -> Element FrontendMsg_
dmGuildIcon route localUser otherUserId dmChannel =
    let
        dmIcon =
            case dmHasNotifications localUser.user otherUserId dmChannel of
                Just count ->
                    elLinkButton
                        (Dom.id ("guildsColumn_openDm_" ++ Id.toString otherUserId))
                        (DmRoute
                            { channelId = DmChannelId.fromUserIds localUser.session.userId otherUserId
                            , threadRoute = NoThreadWithFriends Nothing HideMembersTab
                            , tab = Nothing
                            }
                        )
                        []
                        (case User.getUser otherUserId localUser of
                            Just otherUser ->
                                GuildIcon.userView (NewMessageForUser count) otherUser.icon otherUserId

                            Nothing ->
                                GuildIcon.userView (NewMessageForUser count) Nothing otherUserId
                        )

                Nothing ->
                    Ui.none
    in
    case route of
        DmRoute dmRoute ->
            if Just otherUserId == DmChannelId.otherUserId localUser.session.userId dmRoute.channelId then
                Ui.none

            else
                dmIcon

        _ ->
            dmIcon


discordDmGuildIcon :
    Route
    -> LocalUser
    -> Discord.Id Discord.PrivateChannelId
    -> DiscordFrontendDmChannel
    -> Element FrontendMsg_
discordDmGuildIcon route localUser channelId dmChannel =
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

                Nothing ->
                    Ui.none
    in
    case route of
        DiscordDmRoute dmRoute ->
            if dmRoute.channelId == channelId then
                Ui.none

            else
                dmIcon

        _ ->
            dmIcon


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
                    localUser.user.lastViewedMessage
                )
                dmChannel
                |> OneOrGreater.fromInt
                |> Maybe.map (Tuple.pair currentUserId)

        Nothing ->
            Nothing


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


dmHasNotifications : FrontendCurrentUser -> Id UserId -> FrontendDmChannel -> Maybe OneOrGreater
dmHasNotifications currentUser otherUserId dmChannel =
    channelNewMessageCount (GuildOrDmId (GuildOrDmId_Dm otherUserId)) currentUser dmChannel |> OneOrGreater.fromInt


{-| In the case of a channel, it's just the channel, not the threads it contains. A muted
channel or thread never shows a notification, not even for a direct mention.
-}
channelOrThreadHasNotifications :
    IsMuted
    -> Maybe (NonemptyDict ( channelId, ThreadRoute ) OneOrGreater)
    -> Bool
    -> channelId
    -> ThreadRoute
    -> Maybe (Id messageId)
    -> { a | messages : MessageArray messageId (Message messageId userId) }
    -> ChannelNotificationType
channelOrThreadHasNotifications isMuted maybeDirectMentions notifyOnAllMessages channelId threadRoute maybeLastViewed channel =
    case isMuted of
        IsMuted ->
            NoNotification

        IsNotMuted ->
            channelOrThreadHasNotificationsHelper
                maybeDirectMentions
                notifyOnAllMessages
                channelId
                threadRoute
                maybeLastViewed
                channel


channelOrThreadHasNotificationsHelper :
    Maybe (NonemptyDict ( channelId, ThreadRoute ) OneOrGreater)
    -> Bool
    -> channelId
    -> ThreadRoute
    -> Maybe (Id messageId)
    -> { a | messages : MessageArray messageId (Message messageId userId) }
    -> ChannelNotificationType
channelOrThreadHasNotificationsHelper maybeDirectMentions notifyOnAllMessages channelId threadRoute maybeLastViewed channel =
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


newMessageCount : Maybe (Id messageId) -> { b | messages : MessageArray messageId (Message messageId userId) } -> Int
newMessageCount maybeLastViewed channel =
    case maybeLastViewed of
        Just lastViewed ->
            MessageArray.length channel.messages - 1 - Id.toInt lastViewed

        Nothing ->
            MessageArray.length channel.messages


channelNewMessageCount :
    AnyGuildOrDmId
    -> FrontendCurrentUser
    ->
        { b
            | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : MessageArray ThreadMessageId (Message ThreadMessageId userId) }
        }
    -> Int
channelNewMessageCount guildOrDmId currentUser channel =
    SeqDict.foldl
        (\threadId thread count ->
            newMessageCount
                (SeqDict.get ( guildOrDmId, threadId ) currentUser.lastViewedThreadMessage)
                thread
                + count
        )
        (newMessageCount (SeqDict.get guildOrDmId currentUser.lastViewedMessage) channel)
        channel.threads


{-| Muted channels and threads are left out, so that a guild the user has muted parts of
doesn't light up its icon for messages they said they don't want to hear about.
-}
guildNewMessageCount : FrontendCurrentUser -> Id GuildId -> FrontendGuild -> Int
guildNewMessageCount currentUser guildId guild =
    SeqDict.foldl
        (\channelId channel count ->
            let
                guildOrDmId : AnyGuildOrDmId
                guildOrDmId =
                    GuildOrDmId (GuildOrDmId_Guild guildId channelId)
            in
            SeqDict.foldl
                (\threadId thread count2 ->
                    case MuteSettings.isChannelMuted currentUser.muteSettings guildId channelId (ViewThread threadId) of
                        IsMuted ->
                            count2

                        IsNotMuted ->
                            count2
                                + newMessageCount
                                    (SeqDict.get ( guildOrDmId, threadId ) currentUser.lastViewedThreadMessage)
                                    thread
                )
                (case MuteSettings.isChannelMuted currentUser.muteSettings guildId channelId NoThread of
                    IsMuted ->
                        count

                    IsNotMuted ->
                        count + newMessageCount (SeqDict.get guildOrDmId currentUser.lastViewedMessage) channel
                )
                channel.threads
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
            let
                guildOrDmId : AnyGuildOrDmId
                guildOrDmId =
                    DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId)
            in
            SeqDict.foldl
                (\threadId thread count2 ->
                    case MuteSettings.isDiscordChannelMuted currentUser.muteSettings guildId channelId (ViewThread threadId) of
                        IsMuted ->
                            count2

                        IsNotMuted ->
                            count2
                                + newMessageCount
                                    (SeqDict.get ( guildOrDmId, threadId ) currentUser.lastViewedThreadMessage)
                                    thread
                )
                (case MuteSettings.isDiscordChannelMuted currentUser.muteSettings guildId channelId NoThread of
                    IsMuted ->
                        count

                    IsNotMuted ->
                        count + newMessageCount (SeqDict.get guildOrDmId currentUser.lastViewedMessage) channel
                )
                channel.threads
        )
        0
        guild.channels


guildHasNotifications : FrontendCurrentUser -> Id GuildId -> FrontendGuild -> ChannelNotificationType
guildHasNotifications currentUser guildId guild =
    case MuteSettings.isGuildSpecificallyMute currentUser.muteSettings guildId of
        IsMuted ->
            NoNotification

        IsNotMuted ->
            if SeqSet.member guildId currentUser.notifyOnAllMessages then
                case guildNewMessageCount currentUser guildId guild |> OneOrGreater.fromInt of
                    Just count ->
                        NewMessageForUser count

                    Nothing ->
                        NoNotification

            else
                case unmutedDirectMentions currentUser guildId (SeqDict.get guildId currentUser.directMentions) of
                    Just count ->
                        NewMessageForUser count

                    Nothing ->
                        case guildNewMessageCount currentUser guildId guild |> OneOrGreater.fromInt of
                            Just count ->
                                NewMessage count

                            Nothing ->
                                NoNotification


{-| Mentions in muted channels and threads don't count, the same way their messages don't.
-}
unmutedDirectMentions :
    FrontendCurrentUser
    -> Id GuildId
    -> Maybe (NonemptyDict ( Id ChannelId, ThreadRoute ) OneOrGreater)
    -> Maybe OneOrGreater
unmutedDirectMentions currentUser guildId maybeDirectMentions =
    case maybeDirectMentions of
        Just directMentions ->
            SeqDict.foldl
                (\( channelId, threadRoute ) count total ->
                    case MuteSettings.isChannelMuted currentUser.muteSettings guildId channelId threadRoute of
                        IsMuted ->
                            total

                        IsNotMuted ->
                            case total of
                                Just total2 ->
                                    OneOrGreater.plus count total2 |> Just

                                Nothing ->
                                    Just count
                )
                Nothing
                (NonemptyDict.toSeqDict directMentions)

        Nothing ->
            Nothing


{-| Mentions in muted Discord channels and threads don't count, the same way their messages
don't.
-}
unmutedDiscordDirectMentions :
    FrontendCurrentUser
    -> Discord.Id Discord.GuildId
    -> Maybe (NonemptyDict ( Discord.Id Discord.ChannelId, ThreadRoute ) OneOrGreater)
    -> Maybe OneOrGreater
unmutedDiscordDirectMentions currentUser guildId maybeDirectMentions =
    case maybeDirectMentions of
        Just directMentions ->
            SeqDict.foldl
                (\( channelId, threadRoute ) count total ->
                    case MuteSettings.isDiscordChannelMuted currentUser.muteSettings guildId channelId threadRoute of
                        IsMuted ->
                            total

                        IsNotMuted ->
                            case total of
                                Just total2 ->
                                    OneOrGreater.plus count total2 |> Just

                                Nothing ->
                                    Just count
                )
                Nothing
                (NonemptyDict.toSeqDict directMentions)

        Nothing ->
            Nothing


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
    case MuteSettings.isDiscordGuildSpecificallyMute currentUser.muteSettings guildId of
        IsMuted ->
            NoNotification

        IsNotMuted ->
            case unmutedDiscordDirectMentions currentUser guildId (SeqDict.get guildId currentUser.discordDirectMentions) of
                Just count ->
                    NewMessageForUser count

                Nothing ->
                    case discordGuildNewMessageCount currentDiscordUserId currentUser guildId guild |> OneOrGreater.fromInt of
                        Just count ->
                            NewMessage count

                        Nothing ->
                            NoNotification


elLinkButton : HtmlId -> Route -> List (Ui.Attribute FrontendMsg_) -> Element FrontendMsg_ -> Element FrontendMsg_
elLinkButton htmlId route attributes content =
    MyUi.elButton htmlId (PressedLink route) attributes content


rowLinkButton : HtmlId -> Route -> List (Ui.Attribute FrontendMsg_) -> List (Element FrontendMsg_) -> Element FrontendMsg_
rowLinkButton htmlId route attributes content =
    MyUi.rowButton htmlId (PressedLink route) attributes content
