module UserSession exposing
    ( FrontendUserSession
    , NotificationMode(..)
    , PushSubscription(..)
    , SetViewing(..)
    , ToBeFilledInByBackend(..)
    , UserSession
    , init
    , setCurrentlyViewing
    , setViewingToCurrentlyViewing
    , toFrontend
    )

import Discord
import Effect.Http as Http
import Effect.Lamdera exposing (SessionId)
import Effect.Time as Time
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, ThreadMessageId, ThreadRoute(..), UserId)
import Message exposing (Message)
import Ports exposing (SubscribeData)
import SeqDict exposing (SeqDict)
import SessionIdHash exposing (SessionIdHash)
import UserAgent exposing (UserAgent)


type alias UserSession =
    { userId : Id UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( AnyGuildOrDmId, ThreadRoute )
    , userAgent : UserAgent
    , sessionIdHash : SessionIdHash
    , signedInAt : Time.Posix
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( AnyGuildOrDmId, ThreadRoute )
    , userAgent : UserAgent
    }


type PushSubscription
    = NotSubscribed
    | Subscribed SubscribeData Time.Posix
    | SubscriptionError Http.Error
    | SubscriptionJsException String Time.Posix


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type SetViewing
    = ViewDm (Id UserId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId))))
    | ViewDmThread (Id UserId) (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId))))
    | ViewDiscordDm (Discord.Id Discord.UserId) (Discord.Id Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Discord.Id Discord.UserId))))
    | ViewChannel (Id GuildId) (Id ChannelId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId))))
    | ViewChannelThread (Id GuildId) (Id ChannelId) (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId))))
    | ViewDiscordChannel (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId) (Discord.Id Discord.UserId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Discord.Id Discord.UserId))))
    | ViewDiscordChannelThread (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId) (Discord.Id Discord.UserId) (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Discord.Id Discord.UserId))))
    | StopViewingChannel


setViewingToCurrentlyViewing : SetViewing -> Maybe ( AnyGuildOrDmId, ThreadRoute )
setViewingToCurrentlyViewing viewing =
    case viewing of
        ViewDm otherUserId _ ->
            Just ( GuildOrDmId_Dm otherUserId |> GuildOrDmId, NoThread )

        ViewDmThread otherUserId threadId _ ->
            Just ( GuildOrDmId_Dm otherUserId |> GuildOrDmId, ViewThread threadId )

        ViewDiscordDm currentUserId channelId _ ->
            Just ( DiscordGuildOrDmId_Dm { currentUserId = currentUserId, channelId = channelId } |> DiscordGuildOrDmId, NoThread )

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


init : Time.Posix -> SessionId -> Id UserId -> Maybe ( AnyGuildOrDmId, ThreadRoute ) -> UserAgent -> UserSession
init time sessionId userId currentlyViewing userAgent =
    { userId = userId
    , notificationMode = NoNotifications
    , pushSubscription = NotSubscribed
    , currentlyViewing = currentlyViewing
    , userAgent = userAgent
    , sessionIdHash = SessionIdHash.fromSessionId sessionId
    , signedInAt = time
    }


setCurrentlyViewing :
    Maybe ( AnyGuildOrDmId, ThreadRoute )
    -> { a | currentlyViewing : Maybe ( AnyGuildOrDmId, ThreadRoute ) }
    -> { a | currentlyViewing : Maybe ( AnyGuildOrDmId, ThreadRoute ) }
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
