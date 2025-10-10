module UserSession exposing
    ( FrontendUserSession
    , NotificationMode(..)
    , PushSubscription(..)
    , SetViewing(..)
    , SubscribeData
    , ToBeFilledInByBackend(..)
    , UserSession
    , init
    , routeToViewing
    , setCurrentlyViewing
    , setViewingToCurrentlyViewing
    , toFrontend
    )

import Effect.Http as Http
import Effect.Lamdera exposing (SessionId)
import Id exposing (ChannelId, ChannelMessageId, GuildId, GuildOrDmIdNoThread(..), Id, ThreadMessageId, ThreadRoute(..), UserId)
import Message exposing (Message)
import Route exposing (ChannelRoute(..), Route(..), ThreadRouteWithFriends(..))
import SeqDict exposing (SeqDict)
import SessionIdHash exposing (SessionIdHash)
import Url exposing (Url)
import UserAgent exposing (UserAgent)


type alias UserSession =
    { userId : Id UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , currentlyViewing : Maybe ( GuildOrDmIdNoThread, ThreadRoute )
    , userAgent : UserAgent
    , sessionIdHash : SessionIdHash
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
    = ViewDm (Id UserId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId))))
    | ViewDmThread (Id UserId) (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId))))
    | ViewChannel (Id GuildId) (Id ChannelId) (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId))))
    | ViewChannelThread (Id GuildId) (Id ChannelId) (Id ChannelMessageId) (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId))))
    | StopViewingChannel


setViewingToCurrentlyViewing : SetViewing -> Maybe ( GuildOrDmIdNoThread, ThreadRoute )
setViewingToCurrentlyViewing viewing =
    case viewing of
        ViewDm otherUserId _ ->
            Just ( GuildOrDmId_Dm otherUserId, NoThread )

        ViewDmThread otherUserId threadId _ ->
            Just ( GuildOrDmId_Dm otherUserId, ViewThread threadId )

        ViewChannel guildId channelId _ ->
            Just ( GuildOrDmId_Guild guildId channelId, NoThread )

        ViewChannelThread guildId channelId threadId _ ->
            Just ( GuildOrDmId_Guild guildId channelId, ViewThread threadId )

        StopViewingChannel ->
            Nothing


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


init : SessionId -> Id UserId -> Maybe ( GuildOrDmIdNoThread, ThreadRoute ) -> UserAgent -> UserSession
init sessionId userId currentlyViewing userAgent =
    { userId = userId
    , notificationMode = NoNotifications
    , pushSubscription = NotSubscribed
    , currentlyViewing = currentlyViewing
    , userAgent = userAgent
    , sessionIdHash = SessionIdHash.fromSessionId sessionId
    }


setCurrentlyViewing :
    Maybe ( GuildOrDmIdNoThread, ThreadRoute )
    -> { a | currentlyViewing : Maybe ( GuildOrDmIdNoThread, ThreadRoute ) }
    -> { a | currentlyViewing : Maybe ( GuildOrDmIdNoThread, ThreadRoute ) }
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


routeToViewing : Route -> SetViewing
routeToViewing route =
    case route of
        HomePageRoute ->
            StopViewingChannel

        AdminRoute _ ->
            StopViewingChannel

        GuildRoute guildId channelRoute ->
            case channelRoute of
                ChannelRoute channelId threadRoute ->
                    case threadRoute of
                        NoThreadWithFriends _ _ ->
                            ViewChannel guildId channelId EmptyPlaceholder

                        ViewThreadWithFriends threadId _ _ ->
                            ViewChannelThread guildId channelId threadId EmptyPlaceholder

                NewChannelRoute ->
                    StopViewingChannel

                EditChannelRoute _ ->
                    StopViewingChannel

                InviteLinkCreatorRoute ->
                    StopViewingChannel

                JoinRoute _ ->
                    StopViewingChannel

        DmRoute otherUserId threadRoute ->
            case threadRoute of
                NoThreadWithFriends _ _ ->
                    ViewDm otherUserId EmptyPlaceholder

                ViewThreadWithFriends threadId _ _ ->
                    ViewDmThread otherUserId threadId EmptyPlaceholder

        AiChatRoute ->
            StopViewingChannel

        SlackOAuthRedirect _ ->
            StopViewingChannel

        TextEditorRoute ->
            StopViewingChannel
