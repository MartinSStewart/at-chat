module Evergreen.V338.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V338.Discord
import Evergreen.V338.FileStatus
import Evergreen.V338.Id
import Evergreen.V338.Message
import Evergreen.V338.PersonName
import Evergreen.V338.Ports
import Evergreen.V338.SessionIdHash
import Evergreen.V338.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V338.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V338.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V338.Id.Id Evergreen.V338.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V338.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V338.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId)
    | Viewing_None


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V338.PersonName.PersonName
    , icon : Maybe Evergreen.V338.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V338.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V338.Id.Id messageId) (Evergreen.V338.Message.Message messageId (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.Message.Message Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))))
    | ViewDmThread (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ThreadMessageId) (Evergreen.V338.Message.Message Evergreen.V338.Id.ThreadMessageId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))))
    | ViewDiscordDm (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.Message.Message Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))))
    | ViewChannel (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Evergreen.V338.Message.Message Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))))
    | ViewChannelThread (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ThreadMessageId) (Evergreen.V338.Message.Message Evergreen.V338.Id.ThreadMessageId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V338.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V338.Id.ThreadMessageId))
    | StopViewingChannel
