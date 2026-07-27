module Evergreen.V336.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V336.Discord
import Evergreen.V336.FileStatus
import Evergreen.V336.Id
import Evergreen.V336.Message
import Evergreen.V336.PersonName
import Evergreen.V336.Ports
import Evergreen.V336.SessionIdHash
import Evergreen.V336.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V336.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V336.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V336.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V336.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId)
    | Viewing_None


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V336.PersonName.PersonName
    , icon : Maybe Evergreen.V336.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V336.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V336.Id.Id messageId) (Evergreen.V336.Message.Message messageId (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.Message.Message Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))))
    | ViewDmThread (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ThreadMessageId) (Evergreen.V336.Message.Message Evergreen.V336.Id.ThreadMessageId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))))
    | ViewDiscordDm (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.Message.Message Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))))
    | ViewChannel (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.Message.Message Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))))
    | ViewChannelThread (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ThreadMessageId) (Evergreen.V336.Message.Message Evergreen.V336.Id.ThreadMessageId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V336.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V336.Id.ThreadMessageId))
    | StopViewingChannel
