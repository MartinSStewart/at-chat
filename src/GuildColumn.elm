module GuildColumn exposing
    ( canChangeUnreadNotificationCount
    , channelOrThreadHasNotifications
    , discordDmCurrentUserId
    , discordDmHasNotifications
    , discordGuildCurrentUserId
    , elLinkButton
    , guildColumnLazy
    , newMessageCount
    , rowLinkButton
    , unreadNotificationCount
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
import MessageArray exposing (MessageArray)
import MuteSettings exposing (IsMuted(..))
import MyUi
import NonemptyDict exposing (NonemptyDict)
import OneOrGreater exposing (OneOrGreater)
import Route exposing (ChannelRoute(..), ChannelsVisibleOnMobile(..), DiscordChannelRoute(..), Route(..), ShowChannelSettings(..), ThreadRouteWithFriends(..))
import SeqDict exposing (SeqDict)
import SeqSet
import Types exposing (FrontendMsg_(..), LoadedFrontend, LocalChange(..))
import Ui exposing (Element)
import Ui.Gradient
import Ui.Lazy
import User exposing (FrontendCurrentUser, LocalUser)
import UserColor


guildColumnLazy : Bool -> LoadedFrontend -> LocalState -> Element FrontendMsg_
guildColumnLazy isMobile model local =
    Ui.Lazy.lazy6
        (case ( MyUi.canScroll isMobile model.drag, isMobile ) of
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
                ++ GuildIcon.showFriendsButton (isHomePageRoute route) (PressedLink (HomePageRoute Nothing))
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


isHomePageRoute : Route -> Bool
isHomePageRoute route =
    case route of
        HomePageRoute _ ->
            True

        _ ->
            False


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
                                        ViewThreadWithFriends threadId Nothing HideChannelSettings

                                    NoThread ->
                                        NoThreadWithFriends Nothing HideChannelSettings
                                )
                                Nothing

                        Nothing ->
                            DiscordChannel_ChannelRoute
                                (LocalState.discordAnnouncementChannel guild)
                                (NoThreadWithFriends Nothing HideChannelSettings)
                                Nothing
                 , channelsVisible = ChannelsVisibleOnMobile
                 , overlay = Nothing
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
                                ViewThreadWithFriends threadId Nothing HideChannelSettings

                            NoThread ->
                                NoThreadWithFriends Nothing HideChannelSettings
                        )
                        Nothing

                Nothing ->
                    ChannelRoute
                        (LocalState.announcementChannel guild)
                        (NoThreadWithFriends Nothing HideChannelSettings)
                        Nothing
            )
            ChannelsVisibleOnMobile
            Nothing
        )
        []
        (GuildIcon.view
            (case route of
                GuildRoute a _ _ _ ->
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
                            , threadRoute = NoThreadWithFriends Nothing HideChannelSettings
                            , tab = Nothing
                            , channelsVisible = ChannelsHiddenOnMobile
                            , overlay = Nothing
                            }
                        )
                        []
                        (case User.getUser otherUserId localUser of
                            Just otherUser ->
                                GuildIcon.userView (NewMessageForUser count) otherUser.icon otherUser.color

                            Nothing ->
                                GuildIcon.userView (NewMessageForUser count) Nothing UserColor.default
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
                            , showMembersTab = HideChannelSettings
                            , tab = Nothing
                            , channelsVisible = ChannelsHiddenOnMobile
                            , overlay = Nothing
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
    channelNewMessageCount (GuildOrDmId (GuildOrDmId_Dm { otherUserId = otherUserId })) currentUser dmChannel |> OneOrGreater.fromInt


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
    -> { a | messages : MessageArray messageId userId }
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
    -> { a | messages : MessageArray messageId userId }
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


newMessageCount : Maybe (Id messageId) -> { b | messages : MessageArray messageId userId } -> Int
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
            | messages : MessageArray ChannelMessageId userId
            , threads : SeqDict (Id ChannelMessageId) { c | messages : MessageArray ThreadMessageId userId }
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
                    GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId })
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
                    DiscordGuildOrDmId (DiscordGuildOrDmId_Guild { currentUserId = currentDiscordUserId, guildId = guildId, channelId = channelId })
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


{-| How many unread messages are announced with a red circle in the guild column, i.e.
direct mentions, DMs and guilds the user asked to hear about every message in. Messages
that only get the plain white circle are left out, as are muted guilds, channels and
threads. This is what the app icon badge shows (see Ports.setAppBadge).
-}
unreadNotificationCount : LocalState -> Int
unreadNotificationCount local =
    let
        currentUser : FrontendCurrentUser
        currentUser =
            local.localUser.user

        dmCount : Int
        dmCount =
            SeqDict.foldl
                (\otherUserId dmChannel total ->
                    case dmHasNotifications currentUser otherUserId dmChannel of
                        Just count ->
                            total + OneOrGreater.toInt count

                        Nothing ->
                            total
                )
                0
                local.dmChannels

        discordDmCount : Int
        discordDmCount =
            SeqDict.foldl
                (\channelId dmChannel total ->
                    case discordDmHasNotifications local.localUser channelId dmChannel of
                        Just ( _, count ) ->
                            total + OneOrGreater.toInt count

                        Nothing ->
                            total
                )
                0
                local.discordDmChannels

        guildCount : Int
        guildCount =
            SeqDict.foldl
                (\guildId guild total ->
                    total + redNotificationCount (guildHasNotifications currentUser guildId guild)
                )
                0
                local.guilds

        discordGuildCount : Int
        discordGuildCount =
            SeqDict.foldl
                (\guildId guild total ->
                    case discordGuildCurrentUserId local.localUser guild of
                        Just currentDiscordUserId ->
                            total
                                + redNotificationCount
                                    (discordGuildHasNotifications currentDiscordUserId currentUser guildId guild)

                        Nothing ->
                            total
                )
                0
                local.discordGuilds
    in
    dmCount + discordDmCount + guildCount + discordGuildCount


canChangeUnreadNotificationCount : LocalChange -> Bool
canChangeUnreadNotificationCount change =
    case change of
        Local_Invalid ->
            False

        Local_Admin _ ->
            True

        Local_SendMessage _ _ _ _ _ _ _ ->
            True

        Local_Discord_SendMessage _ _ _ _ _ _ ->
            True

        Local_NewChannel _ _ _ _ ->
            True

        Local_EditChannel _ _ _ _ ->
            False

        Local_DeleteChannel _ _ ->
            True

        Local_EditGuildName _ _ ->
            False

        Local_DeleteGuild _ ->
            True

        Local_LeaveGuild _ ->
            True

        Local_NewInviteLink _ _ _ ->
            False

        Local_DeleteInviteLink _ _ ->
            False

        Local_NewGuild _ _ _ ->
            True

        -- Typing is recorded on the channel rather than as a message. This is the change
        -- the badge was being recomputed for on nearly every keystroke.
        Local_MemberTyping _ _ ->
            False

        Local_AddReactionEmoji _ _ _ ->
            False

        Local_RemoveReactionEmoji _ _ _ ->
            False

        Local_SendEditMessage _ _ _ _ _ _ ->
            False

        Local_Discord_SendEditGuildMessage _ _ _ _ _ _ _ ->
            False

        Local_Discord_SendEditDmMessage _ _ _ _ _ ->
            False

        Local_MemberEditTyping _ _ _ ->
            False

        Local_SetLastViewed _ _ ->
            True

        -- The message is replaced with a DeletedMessage rather than dropped, so the
        -- channel is still the same number of messages long.
        Local_DeleteMessage _ _ ->
            False

        Local_CurrentlyViewing _ _ ->
            True

        Local_SetName _ ->
            False

        -- Loading fills in messages that were already being counted but weren't held in
        -- memory. MessageArray.setMany ignores anything outside the range the array
        -- already spans, so the number of messages can't move.
        Local_LoadChannelMessages _ _ _ ->
            False

        Local_LoadThreadMessages _ _ _ _ ->
            False

        Local_Discord_LoadChannelMessages _ _ _ ->
            False

        Local_Discord_LoadThreadMessages _ _ _ _ ->
            False

        Local_SetGuildNotificationLevel _ _ ->
            True

        Local_SetDiscordGuildNotificationLevel _ _ _ ->
            True

        Local_SetNotificationMode _ ->
            False

        Local_ExpandUserOptionSection _ ->
            False

        Local_CollapseUserOptionSection _ ->
            False

        Local_SetSheepGameQuestions _ ->
            False

        Local_SetEmailNotifications _ ->
            False

        Local_RegisterPushSubscription _ _ ->
            False

        Local_TextEditor _ ->
            False

        -- Which Discord users are linked decides which Discord guilds and DMs are ours to
        -- count in the first place.
        Local_UnlinkDiscordUser _ ->
            True

        Local_StartReloadingDiscordUser _ _ ->
            True

        Local_LinkDiscordAcknowledgementIsChecked _ ->
            False

        Local_SetDomainWhitelist _ _ ->
            False

        Local_SetEmojiSkinTone _ ->
            False

        Local_SetUserColor _ ->
            False

        Local_AddCustomEmojisToUser _ ->
            False

        Local_VoiceChatChange _ ->
            True

        -- Starting a match posts a message.
        Local_Game _ _ ->
            True

        -- A drawing hangs off a message or a date divider without adding one.
        Local_Drawing _ _ _ ->
            False

        Local_SetMuteChannel _ _ _ ->
            True

        Local_SetMuteThread _ _ _ _ ->
            True

        Local_SetMuteDiscordChannel _ _ _ _ ->
            True

        Local_SetMuteDiscordThread _ _ _ _ _ ->
            True

        Local_SetMuteGuild _ _ ->
            True

        Local_SetMuteDiscordGuild _ _ _ ->
            True

        Local_RequestE2ee _ ->
            False

        Local_DeclineE2eeRequestAsInitiator _ ->
            False

        Local_DeclineE2eeRequest _ ->
            False

        Local_SetPublicKey _ _ ->
            False

        Local_EncryptOldMessages _ _ ->
            False

        Local_DisableE2ee _ _ ->
            False

        Local_DecryptOldMessages _ _ _ ->
            False

        Local_SetE2eeRisksAccepted _ ->
            False

        Local_AcceptE2ee _ _ _ ->
            False

        Local_SendEncryptedMessage _ _ _ _ _ _ ->
            True

        Local_SendEncryptedEditMessage _ _ _ _ _ ->
            False


redNotificationCount : ChannelNotificationType -> Int
redNotificationCount notification =
    case notification of
        NoNotification ->
            0

        NewMessage _ ->
            0

        NewMessageForUser count ->
            OneOrGreater.toInt count


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
