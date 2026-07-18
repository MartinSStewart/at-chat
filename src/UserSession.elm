module UserSession exposing
    ( ChannelHeaderTab(..)
    , DiscordFrontendUser
    , FrontendUserSession
    , NotificationMode(..)
    , PushSubscription(..)
    , SetViewing(..)
    , ToBeFilledInByBackend(..)
    , UserSession
    , ViewDiscordGuildData
    , Viewing(..)
    , init
    , isViewing
    , setViewingToCurrentlyViewing
    , toFrontend
    )

import Discord
import Effect.Http as Http
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Time as Time
import FileStatus exposing (FileHash)
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, ThreadMessageId, ThreadRoute(..), UserId)
import Message exposing (Message)
import PersonName exposing (PersonName)
import Ports exposing (SubscribeData)
import SeqDict exposing (SeqDict)
import SessionIdHash exposing (SessionIdHash)
import UserAgent exposing (UserAgent)


type alias UserSession =
    { userId : Id UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : UserAgent
    , sessionIdHash : SessionIdHash
    , signedInAt : Time.Posix
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict ClientId Viewing
    , userAgent : UserAgent
    }


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Id ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type PushSubscription
    = NotSubscribed
    | Subscribed SubscribeData Time.Posix
    | SubscriptionError SubscribeData Http.Error
    | SubscriptionJsException String Time.Posix


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type SetViewing
    = ViewDm (Id UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId))))
    | ViewDmThread (Id UserId) (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId))))
    | ViewDiscordDm (Discord.Id Discord.UserId) (Discord.Id Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Discord.Id Discord.UserId))))
    | ViewChannel (Id GuildId) (Id ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId))))
    | ViewChannelThread (Id GuildId) (Id ChannelId) (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId))))
    | ViewDiscordChannel (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId) (Discord.Id Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData ChannelMessageId))
    | ViewDiscordChannelThread (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId) (Discord.Id Discord.UserId) (Id ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData ThreadMessageId))
    | StopViewingChannel


type Viewing
    = Viewing_Dm (Id UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Id UserId) (Id ChannelMessageId)
    | Viewing_DiscordDm (Discord.Id Discord.UserId) (Discord.Id Discord.PrivateChannelId)
    | Viewing_Channel (Id GuildId) (Id ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Id GuildId) (Id ChannelId) (Id ChannelMessageId)
    | Viewing_DiscordChannel (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId) (Discord.Id Discord.UserId)
    | Viewing_DiscordChannelThread (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId) (Discord.Id Discord.UserId) (Id ChannelMessageId)
    | Viewing_None


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict (Id messageId) (Message messageId (Discord.Id Discord.UserId))
    , newUsers : SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
    }


type alias DiscordFrontendUser =
    { name : PersonName
    , icon : Maybe FileHash
    }


setViewingToCurrentlyViewing : SetViewing -> Viewing
setViewingToCurrentlyViewing viewing =
    case viewing of
        ViewDm otherUserId tab _ ->
            Viewing_Dm otherUserId tab

        ViewDmThread otherUserId threadId _ ->
            Viewing_DmThread otherUserId threadId

        ViewDiscordDm currentUserId channelId _ ->
            Viewing_DiscordDm currentUserId channelId

        ViewChannel guildId channelId tab _ ->
            Viewing_Channel guildId channelId tab

        ViewChannelThread guildId channelId threadId _ ->
            Viewing_ChannelThread guildId channelId threadId

        ViewDiscordChannel guildId channelId discordUserId _ ->
            Viewing_DiscordChannel guildId channelId discordUserId

        ViewDiscordChannelThread guildId channelId discordUserId threadId _ ->
            Viewing_DiscordChannelThread guildId channelId discordUserId threadId

        StopViewingChannel ->
            Viewing_None


isViewing : AnyGuildOrDmId -> ThreadRoute -> Viewing -> Bool
isViewing guildOrDmId threadRoute viewing =
    case ( viewing, threadRoute ) of
        ( Viewing_Dm viewingUserId _, NoThread ) ->
            guildOrDmId == GuildOrDmId (GuildOrDmId_Dm viewingUserId)

        ( Viewing_DmThread viewingUserId viewingThreadId, ViewThread threadId ) ->
            guildOrDmId == GuildOrDmId (GuildOrDmId_Dm viewingUserId) && viewingThreadId == threadId

        ( Viewing_DiscordDm currentUserId channelId, NoThread ) ->
            guildOrDmId == DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId = currentUserId, channelId = channelId })

        ( Viewing_Channel guildId channelId _, NoThread ) ->
            guildOrDmId == GuildOrDmId (GuildOrDmId_Guild guildId channelId)

        ( Viewing_ChannelThread guildId channelId viewingThreadId, ViewThread threadId ) ->
            guildOrDmId == GuildOrDmId (GuildOrDmId_Guild guildId channelId) && viewingThreadId == threadId

        ( Viewing_DiscordChannel guildId channelId discordUserId, NoThread ) ->
            guildOrDmId == DiscordGuildOrDmId (DiscordGuildOrDmId_Guild discordUserId guildId channelId)

        ( Viewing_DiscordChannelThread guildId channelId discordUserId viewingThreadId, ViewThread threadId ) ->
            guildOrDmId == DiscordGuildOrDmId (DiscordGuildOrDmId_Guild discordUserId guildId channelId) && viewingThreadId == threadId

        _ ->
            False


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


init : Time.Posix -> SessionId -> Id UserId -> UserAgent -> UserSession
init time sessionId userId userAgent =
    { userId = userId
    , notificationMode = NoNotifications
    , pushSubscription = NotSubscribed
    , userAgent = userAgent
    , sessionIdHash = SessionIdHash.fromSessionId sessionId
    , signedInAt = time
    }


toFrontend : Id UserId -> SeqDict ClientId Viewing -> UserSession -> Maybe FrontendUserSession
toFrontend currentUserId currentlyViewing userSession =
    if currentUserId == userSession.userId then
        { notificationMode = userSession.notificationMode
        , currentlyViewing = currentlyViewing
        , userAgent = userSession.userAgent
        }
            |> Just

    else
        Nothing
