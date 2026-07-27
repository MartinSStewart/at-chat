module Evergreen.V335.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V335.Discord
import Evergreen.V335.FileStatus
import Evergreen.V335.Id
import Evergreen.V335.Message
import Evergreen.V335.PersonName
import Evergreen.V335.Ports
import Evergreen.V335.SessionIdHash
import Evergreen.V335.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V335.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V335.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V335.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V335.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId)
    | Viewing_None


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V335.PersonName.PersonName
    , icon : Maybe Evergreen.V335.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V335.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V335.Id.Id messageId) (Evergreen.V335.Message.Message messageId (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.Message.Message Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))))
    | ViewDmThread (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ThreadMessageId) (Evergreen.V335.Message.Message Evergreen.V335.Id.ThreadMessageId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))))
    | ViewDiscordDm (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.Message.Message Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))))
    | ViewChannel (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.Message.Message Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))))
    | ViewChannelThread (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ThreadMessageId) (Evergreen.V335.Message.Message Evergreen.V335.Id.ThreadMessageId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V335.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V335.Id.ThreadMessageId))
    | StopViewingChannel
