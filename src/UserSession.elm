module UserSession exposing
    ( NotificationMode(..)
    , PushSubscription(..)
    , SetViewing(..)
    , SubscribeData
    , ToBeFilledInByBackend(..)
    , UserSession
    , init
    , setCurrentlyViewing
    , setViewingToCurrentlyViewing
    )

import Effect.Http as Http
import Id exposing (ChannelId, ChannelMessageId, GuildId, GuildOrDmIdNoThread(..), Id, ThreadMessageId, ThreadRoute(..), UserId)
import Message exposing (Message)
import SeqDict exposing (SeqDict)
import Url exposing (Url)


type alias UserSession =
    { userId : Id UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( GuildOrDmIdNoThread, ThreadRoute )
    }


type PushSubscription
    = NotSubscribed
    | Subscribed SubscribeData
    | SubscriptionError Http.Error


type alias SubscribeData =
    { endpoint : Url, auth : String, p256dh : String }


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type SetViewing
    = ViewDm (Id UserId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId)))
    | ViewDmThread (Id UserId) (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId)))
    | ViewChannel (Id GuildId) (Id ChannelId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId)))
    | ViewChannelThread (Id GuildId) (Id ChannelId) (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId)))
    | StopViewingChannel


setViewingToCurrentlyViewing : SetViewing -> Maybe ( GuildOrDmIdNoThread, ThreadRoute )
setViewingToCurrentlyViewing viewing =
    case viewing of
        ViewDm otherUserId _ ->
            Just ( GuildOrDmId_Dm otherUserId, NoThread )

        ViewDmThread otherUserId threadId _ ->
            Just ( GuildOrDmId_Dm otherUserId, ViewThread threadId )

        ViewChannel guildId channelId toBeFilledInByBackend ->
            Just ( GuildOrDmId_Guild guildId channelId, NoThread )

        ViewChannelThread guildId channelId threadId toBeFilledInByBackend ->
            Just ( GuildOrDmId_Guild guildId channelId, ViewThread threadId )

        StopViewingChannel ->
            Nothing


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


init : Id UserId -> Maybe ( GuildOrDmIdNoThread, ThreadRoute ) -> UserSession
init userId currentlyViewing =
    { userId = userId
    , notificationMode = NoNotifications
    , pushSubscription = NotSubscribed
    , currentlyViewing = currentlyViewing
    }


setCurrentlyViewing : Maybe ( GuildOrDmIdNoThread, ThreadRoute ) -> UserSession -> UserSession
setCurrentlyViewing viewing session =
    { session | currentlyViewing = viewing }
