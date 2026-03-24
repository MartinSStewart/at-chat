module Evergreen.V169.UserSession exposing (..)

import Effect.Http
import Evergreen.V169.Discord
import Evergreen.V169.Id
import Evergreen.V169.Message
import Evergreen.V169.SessionIdHash
import Evergreen.V169.UserAgent
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
    { userId : Evergreen.V169.Id.Id Evergreen.V169.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute )
    , userAgent : Evergreen.V169.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V169.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V169.Id.AnyGuildOrDmId, Evergreen.V169.Id.ThreadRoute )
    , userAgent : Evergreen.V169.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Message.Message Evergreen.V169.Id.ChannelMessageId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId))))
    | ViewDmThread (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ThreadMessageId) (Evergreen.V169.Message.Message Evergreen.V169.Id.ThreadMessageId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId))))
    | ViewDiscordDm (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Message.Message Evergreen.V169.Id.ChannelMessageId (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId))))
    | ViewChannel (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Message.Message Evergreen.V169.Id.ChannelMessageId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId))))
    | ViewChannelThread (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ThreadMessageId) (Evergreen.V169.Message.Message Evergreen.V169.Id.ThreadMessageId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Evergreen.V169.Message.Message Evergreen.V169.Id.ChannelMessageId (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId))))
    | ViewDiscordChannelThread (Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ThreadMessageId) (Evergreen.V169.Message.Message Evergreen.V169.Id.ThreadMessageId (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId))))
    | StopViewingChannel
