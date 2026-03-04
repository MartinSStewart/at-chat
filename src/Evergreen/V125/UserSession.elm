module Evergreen.V125.UserSession exposing (..)

import Effect.Http
import Evergreen.V125.Discord.Id
import Evergreen.V125.Id
import Evergreen.V125.Message
import Evergreen.V125.SessionIdHash
import Evergreen.V125.UserAgent
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
    { userId : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute )
    , userAgent : Evergreen.V125.UserAgent.UserAgent
    , sessionIdHash : Evergreen.V125.SessionIdHash.SessionIdHash
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute )
    , userAgent : Evergreen.V125.UserAgent.UserAgent
    }


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


type SetViewing
    = ViewDm (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Message.Message Evergreen.V125.Id.ChannelMessageId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId))))
    | ViewDmThread (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ThreadMessageId) (Evergreen.V125.Message.Message Evergreen.V125.Id.ThreadMessageId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId))))
    | ViewDiscordDm (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Message.Message Evergreen.V125.Id.ChannelMessageId (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId))))
    | ViewChannel (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Message.Message Evergreen.V125.Id.ChannelMessageId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId))))
    | ViewChannelThread (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ThreadMessageId) (Evergreen.V125.Message.Message Evergreen.V125.Id.ThreadMessageId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId))))
    | ViewDiscordChannel (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Message.Message Evergreen.V125.Id.ChannelMessageId (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId))))
    | ViewDiscordChannelThread (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ThreadMessageId) (Evergreen.V125.Message.Message Evergreen.V125.Id.ThreadMessageId (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId))))
    | StopViewingChannel
