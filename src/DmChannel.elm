module DmChannel exposing
    ( DiscordDmChannel
    , DiscordFrontendDmChannel
    , DmChannel
    , FrontendDmChannel
    , backendInit
    , frontendInit
    , latestFrontendMessageId
    , latestFrontendThreadMessageId
    , latestMessageId
    , latestThreadMessageId
    , loadMessages
    , loadOlderMessages
    , loadUnreadMessages
    , toDiscordFrontendHelper
    , toFrontend
    , toFrontendHelper
    , updateArray
    )

import Date exposing (Date)
import Discord
import DmChannelId exposing (DmChannelId, GuildOrFullDmId(..))
import Drawing exposing (Drawing)
import Game exposing (BackendGameData)
import Id exposing (ChannelMessageId, GamePublicId, Id, ThreadMessageId, ThreadRoute(..), UserId)
import IdArray exposing (IdArray)
import Message exposing (Message)
import MessageArray exposing (MessageArray)
import NonemptyDict exposing (NonemptyDict)
import OneToOne exposing (OneToOne)
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import Thread exposing (BackendThread, DiscordBackendThread, FrontendThread, LastTypedAt)
import UserSession exposing (ToBeFilledInByBackend(..))
import VisibleMessages exposing (VisibleMessages)


type alias DmChannel =
    { messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId))
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) BackendThread
    , games : SeqDict (Id ChannelMessageId) BackendGameData
    , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
    }


type alias DiscordDmChannel =
    { messages : IdArray ChannelMessageId (Message ChannelMessageId (Discord.Id Discord.UserId))
    , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ChannelMessageId)
    , linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id ChannelMessageId)
    , members : NonemptyDict (Discord.Id Discord.UserId) { messagesSent : Int }
    , dateDividerDrawings : SeqDict Date (Drawing (Discord.Id Discord.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : MessageArray ChannelMessageId (Message ChannelMessageId (Discord.Id Discord.UserId))
    , visibleMessages : VisibleMessages ChannelMessageId
    , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ChannelMessageId)
    , members : NonemptyDict (Discord.Id Discord.UserId) { messagesSent : Int }
    , dateDividerDrawings : SeqDict Date (Drawing (Discord.Id Discord.UserId))
    }


type alias FrontendDmChannel =
    { messages : MessageArray ChannelMessageId (Message ChannelMessageId (Id UserId))
    , visibleMessages : VisibleMessages ChannelMessageId
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) FrontendThread
    , games : SeqDict (Id ChannelMessageId) Game.MatchData
    , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
    }


backendInit : DmChannel
backendInit =
    { messages = IdArray.empty
    , lastTypedAt = SeqDict.empty
    , threads = SeqDict.empty
    , games = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    }


frontendInit : FrontendDmChannel
frontendInit =
    { messages = MessageArray.empty
    , visibleMessages = VisibleMessages.empty
    , lastTypedAt = SeqDict.empty
    , threads = SeqDict.empty
    , games = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    }


toFrontend :
    Maybe ThreadRoute
    -> DmChannelId
    -> OneToOne (SecretId GamePublicId) ( GuildOrFullDmId, Id ChannelMessageId )
    -> DmChannel
    -> FrontendDmChannel
toFrontend threadRoute dmChannelId goMatchPublicIds dmChannel =
    let
        preloadMessages =
            Just NoThread == threadRoute
    in
    { messages = toFrontendHelper preloadMessages dmChannel
    , visibleMessages = VisibleMessages.init preloadMessages (IdArray.length dmChannel.messages)
    , lastTypedAt = dmChannel.lastTypedAt
    , threads =
        SeqDict.map
            (\threadId thread -> Thread.toFrontend (Just (ViewThread threadId) == threadRoute) thread)
            dmChannel.threads
    , games =
        SeqDict.map
            (\matchId gameData ->
                Game.initMatchData gameData (OneToOne.first ( GuildOrFullDmId_Dm dmChannelId, matchId ) goMatchPublicIds)
            )
            dmChannel.games
    , dateDividerDrawings = dmChannel.dateDividerDrawings
    }


updateArray : Id messageId -> (a -> a) -> IdArray messageId a -> IdArray messageId a
updateArray id updateFunc array =
    case IdArray.get id array of
        Just value ->
            IdArray.set id (updateFunc value) array

        Nothing ->
            array


latestMessageId : { a | messages : IdArray ChannelMessageId b } -> Id ChannelMessageId
latestMessageId channel =
    IdArray.length channel.messages - 1 |> Id.fromInt


latestFrontendMessageId : { a | messages : MessageArray ChannelMessageId b } -> Id ChannelMessageId
latestFrontendMessageId channel =
    MessageArray.length channel.messages - 1 |> Id.fromInt


latestThreadMessageId : { a | messages : IdArray ThreadMessageId b } -> Id ThreadMessageId
latestThreadMessageId thread =
    IdArray.length thread.messages - 1 |> Id.fromInt


latestFrontendThreadMessageId : { a | messages : MessageArray ThreadMessageId b } -> Id ThreadMessageId
latestFrontendThreadMessageId thread =
    MessageArray.length thread.messages - 1 |> Id.fromInt


toFrontendHelper :
    Bool
    -> { a | messages : IdArray messageId (Message messageId userId), threads : SeqDict (Id messageId) BackendThread }
    -> MessageArray messageId (Message messageId userId)
toFrontendHelper preloadMessages channel =
    loadThreadStarters channel.threads channel.messages (Thread.loadMessages preloadMessages channel.messages)


toDiscordFrontendHelper :
    Bool
    -> { a | messages : IdArray messageId (Message messageId userId), threads : SeqDict (Id messageId) DiscordBackendThread }
    -> MessageArray messageId (Message messageId userId)
toDiscordFrontendHelper preloadMessages channel =
    loadThreadStarters channel.threads channel.messages (Thread.loadMessages preloadMessages channel.messages)


{-| The message a thread was started from is always loaded, even when the rest of
the channel isn't, so that the thread can be previewed.
-}
loadThreadStarters :
    SeqDict (Id messageId) thread
    -> IdArray messageId (Message messageId userId)
    -> MessageArray messageId (Message messageId userId)
    -> MessageArray messageId (Message messageId userId)
loadThreadStarters threads backendMessages messages =
    SeqDict.foldl
        (\threadId _ list ->
            case IdArray.get threadId backendMessages of
                Just message ->
                    ( threadId, message ) :: list

                Nothing ->
                    list
        )
        []
        threads
        |> (\threadStarters -> MessageArray.setMany threadStarters messages)


loadOlderMessages :
    Id messageId
    -> ToBeFilledInByBackend (SeqDict (Id messageId) (Message messageId userId))
    -> { a | messages : MessageArray messageId (Message messageId userId), visibleMessages : VisibleMessages messageId }
    -> { a | messages : MessageArray messageId (Message messageId userId), visibleMessages : VisibleMessages messageId }
loadOlderMessages previousOldestVisibleMessage messagesLoaded channel =
    case messagesLoaded of
        FilledInByBackend messagesLoaded2 ->
            { channel
                | messages =
                    MessageArray.setMany (SeqDict.toList messagesLoaded2) channel.messages
                , visibleMessages = VisibleMessages.loadOlder previousOldestVisibleMessage channel.visibleMessages
            }

        EmptyPlaceholder ->
            channel


{-| Loads the messages the unread overview shows. Unlike `loadMessages` this leaves
`visibleMessages` alone: these are messages of channels the user hasn't opened, so they
aren't the page of messages the channel view would scroll through.
-}
loadUnreadMessages :
    SeqDict (Id messageId) (Message messageId userId)
    -> { a | messages : MessageArray messageId (Message messageId userId) }
    -> { a | messages : MessageArray messageId (Message messageId userId) }
loadUnreadMessages messages channel =
    { channel | messages = MessageArray.setMany (SeqDict.toList messages) channel.messages }


loadMessages :
    ToBeFilledInByBackend (SeqDict (Id messageId) (Message messageId userId))
    -> { a | messages : MessageArray messageId (Message messageId userId), visibleMessages : VisibleMessages messageId }
    -> { a | messages : MessageArray messageId (Message messageId userId), visibleMessages : VisibleMessages messageId }
loadMessages messagesLoaded channel =
    case messagesLoaded of
        FilledInByBackend messagesLoaded2 ->
            { channel
                | messages =
                    MessageArray.setMany (SeqDict.toList messagesLoaded2) channel.messages
                , visibleMessages = VisibleMessages.firstLoad (MessageArray.length channel.messages)
            }

        EmptyPlaceholder ->
            channel
