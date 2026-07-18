module Evergreen.V328.UserSession exposing (..)

import Effect.Http
import Effect.Lamdera
import Effect.Time
import Evergreen.V328.Discord
import Evergreen.V328.FileStatus
import Evergreen.V328.Id
import Evergreen.V328.Message
import Evergreen.V328.PersonName
import Evergreen.V328.Ports
import Evergreen.V328.SessionIdHash
import Evergreen.V328.UserAgent
import SeqDict


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type PushSubscription
    = NotSubscribed
    | Subscribed Evergreen.V328.Ports.SubscribeData Effect.Time.Posix
    | SubscriptionError Evergreen.V328.Ports.SubscribeData Effect.Http.Error
    | SubscriptionJsException String Effect.Time.Posix


type alias UserSession =
    { userId : Evergreen.V328.Id.Id Evergreen.V328.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : Evergreen.V328.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V328.SessionIdHash.SessionIdHash
    , signedInAt : Effect.Time.Posix
    }


type Viewing
    = Viewing_Dm (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) (Maybe ChannelHeaderTab)
    | Viewing_DmThread (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId)
    | Viewing_DiscordDm (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId)
    | Viewing_Channel (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelId) (Maybe ChannelHeaderTab)
    | Viewing_ChannelThread (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId)
    | Viewing_DiscordChannel (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId)
    | Viewing_DiscordChannelThread (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId)
    | Viewing_None


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type alias DiscordFrontendUser =
    { name : Evergreen.V328.PersonName.PersonName
    , icon : Maybe Evergreen.V328.FileStatus.FileHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict.SeqDict Effect.Lamdera.ClientId Viewing
    , userAgent : Evergreen.V328.UserAgent.UserAgent
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict.SeqDict (Evergreen.V328.Id.Id messageId) (Evergreen.V328.Message.Message messageId (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId))
    , newUsers : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) DiscordFrontendUser
    }


type SetViewing
    = ViewDm (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) (Evergreen.V328.Message.Message Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId))))
    | ViewDmThread (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ThreadMessageId) (Evergreen.V328.Message.Message Evergreen.V328.Id.ThreadMessageId (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId))))
    | ViewDiscordDm (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) (Evergreen.V328.Message.Message Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId))))
    | ViewChannel (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelId) (Maybe ChannelHeaderTab) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) (Evergreen.V328.Message.Message Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId))))
    | ViewChannelThread (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ThreadMessageId) (Evergreen.V328.Message.Message Evergreen.V328.Id.ThreadMessageId (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V328.Id.ChannelMessageId))
    | ViewDiscordChannelThread (Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId) (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) (ToBeFilledInByBackend (ViewDiscordGuildData Evergreen.V328.Id.ThreadMessageId))
    | StopViewingChannel
