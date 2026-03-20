module Evergreen.V160.UserSession exposing (..)

import Effect.Http
import Evergreen.V160.Discord
import Evergreen.V160.Id
import Evergreen.V160.Message
import Evergreen.V160.SessionIdHash
import Evergreen.V160.UserAgent
import SeqDict
import Url


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type alias SubscribeData =
    { endpoint : Url.Url
    , auth : String
    , p256dh : String
    }


type PushSubscription
    = NotSubscribed
    | Subscribed SubscribeData
    | SubscriptionError Effect.Http.Error


type alias UserSession =
    { userId : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute )
    , userAgent : Evergreen.V160.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V160.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V160.Id.AnyGuildOrDmId, Evergreen.V160.Id.ThreadRoute )
    , userAgent : Evergreen.V160.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Message.Message Evergreen.V160.Id.ChannelMessageId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId))))
    | ViewDmThread (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ThreadMessageId) (Evergreen.V160.Message.Message Evergreen.V160.Id.ThreadMessageId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId))))
    | ViewDiscordDm (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Message.Message Evergreen.V160.Id.ChannelMessageId (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId))))
    | ViewChannel (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Message.Message Evergreen.V160.Id.ChannelMessageId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId))))
    | ViewChannelThread (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ThreadMessageId) (Evergreen.V160.Message.Message Evergreen.V160.Id.ThreadMessageId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Evergreen.V160.Message.Message Evergreen.V160.Id.ChannelMessageId (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ThreadMessageId) (Evergreen.V160.Message.Message Evergreen.V160.Id.ThreadMessageId (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId))))
    | StopViewingChannel
