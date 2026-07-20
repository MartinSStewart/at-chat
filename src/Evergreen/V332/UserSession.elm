module Evergreen.V332.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V332.Discord
import Evergreen.V332.FileStatus
import Evergreen.V332.Id
import Evergreen.V332.Message
import Evergreen.V332.PersonName
import Evergreen.V332.Ports
import Evergreen.V332.SessionIdHash
import Evergreen.V332.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V332.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V332.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V332.Id.Id Evergreen.V332.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V332.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V332.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId)
    | Viewing_None


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V332.PersonName.PersonName
    , icon : Maybe Evergreen.V332.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V332.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V332.Id.Id messageId) (Evergreen.V332.Message.Message messageId (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.Message.Message Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))))
    | ViewDmThread (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ThreadMessageId) (Evergreen.V332.Message.Message Evergreen.V332.Id.ThreadMessageId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))))
    | ViewDiscordDm (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.Message.Message Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))))
    | ViewChannel (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.Message.Message Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))))
    | ViewChannelThread (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ThreadMessageId) (Evergreen.V332.Message.Message Evergreen.V332.Id.ThreadMessageId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V332.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V332.Id.ThreadMessageId))
    | StopViewingChannel
