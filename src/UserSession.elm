module UserSession exposing
    ( FrontendUserSession
    , NotificationMode(..)
    , PushSubscription(..)
    , SetViewing(..)
    , SubscribeData
    , ToBeFilledInByBackend(..)
    , UserSession
    , init
    , routeToViewing
    , setCurrentlyViewing
    , setViewingToCurrentlyViewing
    , toFrontend
    )

import Discord.Id
import DiscordDmChannelId exposing (DiscordDmChannelId)
import Effect.Http as Http
import Effect.Lamdera exposing (SessionId)
import Id exposing (AnyGuildOrDmIdNoThread(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, ThreadMessageId, ThreadRoute(..), UserId)
import Message exposing (Message)
import Route exposing (ChannelRoute(..), DiscordChannelRoute(..), Route(..), ThreadRouteWithFriends(..))
import SeqDict exposing (SeqDict)
import SessionIdHash exposing (SessionIdHash)
import Url exposing (Url)
import UserAgent exposing (UserAgent)


type alias UserSession =
    { userId : Id UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( AnyGuildOrDmIdNoThread (Discord.Id.Id Discord.Id.UserId), ThreadRoute )
    , userAgent : UserAgent
    , sessionIdHash : SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( AnyGuildOrDmIdNoThread (Discord.Id.Id Discord.Id.UserId), ThreadRoute )
    , userAgent : UserAgent
    }


type PushSubscription
    = NotSubscribed
    | Subscribed SubscribeData
    | SubscriptionError Http.Error


type alias SubscribeData =
    { endpoint : Url, auth : String, p256dh : String }


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type SetViewing
    = ViewDm (Id UserId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId))))
    | ViewDmThread (Id UserId) (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId))))
    | ViewDiscordDm DiscordDmChannelId (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId))))
    | ViewDiscordDmThread DiscordDmChannelId (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId))))
    | ViewChannel (Id GuildId) (Id ChannelId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId))))
    | ViewChannelThread (Id GuildId) (Id ChannelId) (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId))))
    | ViewDiscordChannel (Discord.Id.Id Discord.Id.GuildId) (Discord.Id.Id Discord.Id.ChannelId) (Discord.Id.Id Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Discord.Id.Id Discord.Id.UserId))))
    | ViewDiscordChannelThread (Discord.Id.Id Discord.Id.GuildId) (Discord.Id.Id Discord.Id.ChannelId) (Discord.Id.Id Discord.Id.UserId) (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Discord.Id.Id Discord.Id.UserId))))
    | StopViewingChannel


setViewingToCurrentlyViewing : SetViewing -> Maybe ( AnyGuildOrDmIdNoThread (Discord.Id.Id Discord.Id.UserId), ThreadRoute )
setViewingToCurrentlyViewing viewing =
    case viewing of
        ViewDm otherUserId _ ->
            Just ( GuildOrDmId_Dm otherUserId |> GuildOrDmId, NoThread )

        ViewDmThread otherUserId threadId _ ->
            Just ( GuildOrDmId_Dm otherUserId |> GuildOrDmId, ViewThread threadId )

        ViewDiscordDm otherUserId _ ->
            Just ( DiscordGuildOrDmId_Dm otherUserId |> DiscordGuildOrDmId, NoThread )

        ViewDiscordDmThread otherUserId threadId _ ->
            Just ( DiscordGuildOrDmId_Dm otherUserId |> DiscordGuildOrDmId, ViewThread threadId )

        ViewChannel guildId channelId _ ->
            Just ( GuildOrDmId_Guild guildId channelId |> GuildOrDmId, NoThread )

        ViewChannelThread guildId channelId threadId _ ->
            Just ( GuildOrDmId_Guild guildId channelId |> GuildOrDmId, ViewThread threadId )

        ViewDiscordChannel guildId channelId discordUserId _ ->
            Just ( DiscordGuildOrDmId_Guild discordUserId guildId channelId |> DiscordGuildOrDmId, NoThread )

        ViewDiscordChannelThread guildId channelId discordUserId threadId _ ->
            Just ( DiscordGuildOrDmId_Guild discordUserId guildId channelId |> DiscordGuildOrDmId, ViewThread threadId )

        StopViewingChannel ->
            Nothing


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


init : SessionId -> Id UserId -> Maybe ( AnyGuildOrDmIdNoThread (Discord.Id.Id Discord.Id.UserId), ThreadRoute ) -> UserAgent -> UserSession
init sessionId userId currentlyViewing userAgent =
    { userId = userId
    , notificationMode = NoNotifications
    , pushSubscription = NotSubscribed
    , currentlyViewing = currentlyViewing
    , userAgent = userAgent
    , sessionIdHash = SessionIdHash.fromSessionId sessionId
    }


setCurrentlyViewing :
    Maybe ( AnyGuildOrDmIdNoThread a, ThreadRoute )
    -> { a | currentlyViewing : Maybe ( AnyGuildOrDmIdNoThread a, ThreadRoute ) }
    -> { a | currentlyViewing : Maybe ( AnyGuildOrDmIdNoThread a, ThreadRoute ) }
setCurrentlyViewing viewing session =
    { session | currentlyViewing = viewing }


toFrontend : Id UserId -> UserSession -> Maybe FrontendUserSession
toFrontend currentUserId userSession =
    if currentUserId == userSession.userId then
        { notificationMode = userSession.notificationMode
        , currentlyViewing = userSession.currentlyViewing
        , userAgent = userSession.userAgent
        }
            |> Just

    else
        Nothing


routeToViewing : Maybe (Discord.Id.Id Discord.Id.UserId) -> Route -> SetViewing
routeToViewing currentDiscordUserId route =
    case route of
        HomePageRoute ->
            StopViewingChannel

        AdminRoute _ ->
            StopViewingChannel

        GuildRoute guildId channelRoute ->
            case channelRoute of
                ChannelRoute channelId threadRoute ->
                    case threadRoute of
                        NoThreadWithFriends _ _ ->
                            ViewChannel guildId channelId EmptyPlaceholder

                        ViewThreadWithFriends threadId _ _ ->
                            ViewChannelThread guildId channelId threadId EmptyPlaceholder

                NewChannelRoute ->
                    StopViewingChannel

                EditChannelRoute _ ->
                    StopViewingChannel

                GuildSettingsRoute ->
                    StopViewingChannel

                JoinRoute _ ->
                    StopViewingChannel

        DiscordGuildRoute guildId channelRoute ->
            case channelRoute of
                DiscordChannel_ChannelRoute channelId threadRoute ->
                    case ( threadRoute, currentDiscordUserId ) of
                        ( NoThreadWithFriends _ _, Just discordUserId ) ->
                            ViewDiscordChannel guildId channelId discordUserId EmptyPlaceholder

                        ( ViewThreadWithFriends threadId _ _, Just discordUserId ) ->
                            ViewDiscordChannelThread guildId channelId discordUserId threadId EmptyPlaceholder

                        _ ->
                            StopViewingChannel

                DiscordChannel_NewChannelRoute ->
                    StopViewingChannel

                DiscordChannel_EditChannelRoute _ ->
                    StopViewingChannel

                DiscordChannel_GuildSettingsRoute ->
                    StopViewingChannel

        DmRoute otherUserId threadRoute ->
            case threadRoute of
                NoThreadWithFriends _ _ ->
                    ViewDm otherUserId EmptyPlaceholder

                ViewThreadWithFriends threadId _ _ ->
                    ViewDmThread otherUserId threadId EmptyPlaceholder

        DiscordDmRoute dmChannelId threadRoute ->
            case threadRoute of
                NoThreadWithFriends _ _ ->
                    ViewDiscordDm dmChannelId EmptyPlaceholder

                ViewThreadWithFriends threadId _ _ ->
                    ViewDiscordDmThread dmChannelId threadId EmptyPlaceholder

        AiChatRoute ->
            StopViewingChannel

        SlackOAuthRedirect _ ->
            StopViewingChannel

        TextEditorRoute ->
            StopViewingChannel
