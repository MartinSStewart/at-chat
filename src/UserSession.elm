module UserSession exposing
    ( FrontendUserSession
    , NotificationMode(..)
    , PushSubscription(..)
    , SetViewing(..)
    , SubscribeData
    , ToBeFilledInByBackend(..)
    , UserSession
    , init
    , setCurrentlyViewing
    , setViewingToCurrentlyViewing
    , toFrontend
    )

import Effect.Http as Http
import Id exposing (ChannelId, ChannelMessageId, GuildId, GuildOrDmIdNoThread(..), Id, ThreadMessageId, ThreadRoute(..), UserId)
import Message exposing (Message)
import SeqDict exposing (SeqDict)
import Url exposing (Url)
import UserAgent exposing (UserAgent)


type alias UserSession =
    { userId : Id UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( GuildOrDmIdNoThread, ThreadRoute )
    , userAgent : UserAgent
    }


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : Maybe ( GuildOrDmIdNoThread, ThreadRoute )
    , userAgent : UserAgent
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


init : Id UserId -> Maybe ( GuildOrDmIdNoThread, ThreadRoute ) -> UserAgent -> UserSession
init userId currentlyViewing userAgent =
    { userId = userId
    , notificationMode = NoNotifications
    , pushSubscription = NotSubscribed
    , currentlyViewing = currentlyViewing
    , userAgent = userAgent
    }


setCurrentlyViewing : Maybe ( GuildOrDmIdNoThread, ThreadRoute ) -> UserSession -> UserSession
setCurrentlyViewing viewing session =
    { session | currentlyViewing = viewing }


toFrontend : Id UserId -> UserSession -> Maybe FrontendUserSession
toFrontend currentUserId userSession =
    if currentUserId == userSession.userId then
        { notificationMode = userSession.notificationMode
        , currentlyViewing = userSession.currentlyViewing
        , userAgent = userSession.userAgent
        }
            |> Just

    else
        Nothing
