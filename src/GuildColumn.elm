module GuildColumn exposing
    ( canScroll
    , channelOrThreadHasNotifications
    , discordDmHasNotifications
    , elLinkButton
    , guildColumnLazy
    , rowLinkButton
    )

import Discord
import DmChannel exposing (DiscordFrontendDmChannel, FrontendDmChannel)
import DmChannelId
import Effect.Browser.Dom as Dom exposing (HtmlId)
import FileStatus exposing (FileHash)
import GuildIcon exposing (ChannelNotificationType(..))
import Html.Attributes
import Id exposing (AnyGuildOrDmId(..), ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, ThreadMessageId, ThreadRoute(..), UserId)
import IdArray exposing (IdArray)
import LinkedAndOtherDiscordUsers exposing (DiscordFrontendCurrentUser)
import List.Extra
import List.Nonempty
import LocalState exposing (DiscordFrontendGuild, FrontendGuild, LocalState)
import MembersAndOwner exposing (IsMember(..))
import Message exposing (MessageState)
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
            , Ui.width (Ui.px GuildIcon.fullWidth)
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
                ++ [ GuildIcon.addGuildButton (Dom.id "guild_createGuild") False PressedCreateGuild ]
            )
        )


discordGuildIcon : LocalUser -> Route -> Discord.Id Discord.GuildId -> DiscordFrontendGuild -> Element FrontendMsg_
discordGuildIcon localUser route guildId guild =
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
                    localUser.user.lastViewed
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


{-| In the case of a channel, it's just the channel, not the threads it contains
-}
channelOrThreadHasNotifications :
    Maybe (NonemptyDict ( channelId, ThreadRoute ) OneOrGreater)
    -> Bool
    -> channelId
    -> ThreadRoute
    -> Maybe (Id messageId)
    -> { a | messages : IdArray messageId (MessageState messageId userId) }
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


newMessageCount : Maybe (Id messageId) -> { b | messages : IdArray messageId (MessageState messageId userId) } -> Int
newMessageCount maybeLastViewed channel =
    case maybeLastViewed of
        Just lastViewed ->
            IdArray.length channel.messages - 1 - Id.toInt lastViewed

        Nothing ->
            IdArray.length channel.messages


channelNewMessageCount :
    AnyGuildOrDmId
    -> FrontendCurrentUser
    ->
        { b
            | messages : IdArray ChannelMessageId (MessageState ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : IdArray ThreadMessageId (MessageState ThreadMessageId userId) }
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


elLinkButton : HtmlId -> Route -> List (Ui.Attribute FrontendMsg_) -> Element FrontendMsg_ -> Element FrontendMsg_
elLinkButton htmlId route attributes content =
    MyUi.elButton htmlId (PressedLink route) attributes content


rowLinkButton : HtmlId -> Route -> List (Ui.Attribute FrontendMsg_) -> List (Element FrontendMsg_) -> Element FrontendMsg_
rowLinkButton htmlId route attributes content =
    MyUi.rowButton htmlId (PressedLink route) attributes content
