module DmChannel exposing
    ( DiscordDmChannel
    , DiscordFrontendDmChannel
    , DmChannel
    , DmChannelId(..)
    , FrontendDmChannel
    , backendInit
    , channelIdFromUserIds
    , frontendInit
    , getArray
    , latestMessageId
    , latestThreadMessageId
    , loadMessages
    , loadOlderMessages
    , otherUserId
    , setArray
    , toDiscordFrontendHelper
    , toFrontend
    , toFrontendHelper
    , userIdsFromChannelId
    )

import Array exposing (Array)
import ArrayWithOffset exposing (ArrayWithOffset)
import Discord
import Id exposing (ChannelMessageId, Id(..), ThreadMessageId, ThreadRoute(..), UserId)
import Message exposing (Message, MessageState(..))
import NonemptyDict exposing (NonemptyDict)
import OneToOne exposing (OneToOne)
import SeqDict exposing (SeqDict)
import Thread exposing (BackendThread, DiscordBackendThread, FrontendThread, LastTypedAt)
import UserSession exposing (ToBeFilledInByBackend(..))
import VisibleMessages exposing (VisibleMessages)


type alias DmChannel =
    { messages : Array (Message ChannelMessageId (Id UserId))
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array (Message ChannelMessageId (Discord.Id Discord.UserId))
    , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ChannelMessageId)
    , linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id ChannelMessageId)
    , members : NonemptyDict (Discord.Id Discord.UserId) { messagesSent : Int }
    }


type alias DiscordFrontendDmChannel =
    { messages : ArrayWithOffset ChannelMessageId (Discord.Id Discord.UserId)
    , visibleMessages : VisibleMessages ChannelMessageId
    , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ChannelMessageId)
    , members : NonemptyDict (Discord.Id Discord.UserId) { messagesSent : Int }
    }


type alias FrontendDmChannel =
    { messages : ArrayWithOffset ChannelMessageId (Id UserId)
    , visibleMessages : VisibleMessages ChannelMessageId
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) FrontendThread
    }


{-| OpaqueVariants
-}
type DmChannelId
    = DmChannelId (Id UserId) (Id UserId)


backendInit : DmChannel
backendInit =
    { messages = Array.empty
    , lastTypedAt = SeqDict.empty
    , threads = SeqDict.empty
    }


frontendInit : FrontendDmChannel
frontendInit =
    { messages = ArrayWithOffset.init
    , visibleMessages = VisibleMessages.empty
    , lastTypedAt = SeqDict.empty
    , threads = SeqDict.empty
    }


toFrontend : Maybe ThreadRoute -> DmChannel -> FrontendDmChannel
toFrontend threadRoute dmChannel =
    let
        preloadMessages =
            Just NoThread == threadRoute
    in
    { messages = toFrontendHelper preloadMessages dmChannel
    , visibleMessages = VisibleMessages.init preloadMessages dmChannel
    , lastTypedAt = dmChannel.lastTypedAt
    , threads =
        SeqDict.map
            (\threadId thread -> Thread.toFrontend (Just (ViewThread threadId) == threadRoute) thread)
            dmChannel.threads
    }


latestMessageId : { a | messages : Array b } -> Id ChannelMessageId
latestMessageId channel =
    Array.length channel.messages - 1 |> Id.fromInt


latestThreadMessageId : { a | messages : Array b } -> Id ThreadMessageId
latestThreadMessageId thread =
    Array.length thread.messages - 1 |> Id.fromInt


toFrontendHelper :
    Bool
    -> { a | messages : Array (Message messageId userId), threads : SeqDict (Id messageId) BackendThread }
    -> ArrayWithOffset messageId userId
toFrontendHelper preloadMessages channel =
    SeqDict.foldl
        (\threadId _ arrayWithOffset ->
            case getArray threadId channel.messages of
                Just message ->
                    ArrayWithOffset.set threadId message arrayWithOffset

                Nothing ->
                    arrayWithOffset
        )
        (Thread.loadMessages preloadMessages channel.messages)
        channel.threads


toDiscordFrontendHelper :
    Bool
    -> { a | messages : Array (Message messageId userId), threads : SeqDict (Id messageId) DiscordBackendThread }
    -> ArrayWithOffset messageId userId
toDiscordFrontendHelper preloadMessages channel =
    SeqDict.foldl
        (\threadId _ arrayWithOffset ->
            case getArray threadId channel.messages of
                Just message ->
                    ArrayWithOffset.set threadId message arrayWithOffset

                Nothing ->
                    arrayWithOffset
        )
        (Thread.loadMessages preloadMessages channel.messages)
        channel.threads


getArray : Id messageId -> Array a -> Maybe a
getArray id array =
    Array.get (Id.toInt id) array


setArray : Id messageId -> a -> Array a -> Array a
setArray id message array =
    Array.set (Id.toInt id) message array


channelIdFromUserIds : Id UserId -> Id UserId -> DmChannelId
channelIdFromUserIds (Id userIdA) (Id userIdB) =
    DmChannelId (min userIdA userIdB |> Id) (max userIdA userIdB |> Id)


userIdsFromChannelId : DmChannelId -> ( Id UserId, Id UserId )
userIdsFromChannelId (DmChannelId userIdA userIdB) =
    ( userIdA, userIdB )


otherUserId : Id UserId -> DmChannelId -> Maybe (Id UserId)
otherUserId userId (DmChannelId userIdA userIdB) =
    if userId == userIdA then
        Just userIdB

    else if userId == userIdB then
        Just userIdA

    else
        Nothing


loadOlderMessages :
    Id messageId
    -> ToBeFilledInByBackend (SeqDict (Id messageId) (Message messageId userId))
    -> { a | messages : ArrayWithOffset messageId userId, visibleMessages : VisibleMessages messageId }
    -> { a | messages : ArrayWithOffset messageId userId, visibleMessages : VisibleMessages messageId }
loadOlderMessages previousOldestVisibleMessage messagesLoaded channel =
    case messagesLoaded of
        FilledInByBackend messagesLoaded2 ->
            { channel
                | messages = SeqDict.foldl ArrayWithOffset.set channel.messages messagesLoaded2
                , visibleMessages = VisibleMessages.loadOlder previousOldestVisibleMessage channel.visibleMessages
            }

        EmptyPlaceholder ->
            channel


loadMessages :
    ToBeFilledInByBackend (SeqDict (Id messageId) (Message messageId userId))
    -> { a | messages : ArrayWithOffset messageId userId, visibleMessages : VisibleMessages messageId }
    -> { a | messages : ArrayWithOffset messageId userId, visibleMessages : VisibleMessages messageId }
loadMessages messagesLoaded channel =
    case messagesLoaded of
        FilledInByBackend messagesLoaded2 ->
            let
                channel2 : { a | messages : ArrayWithOffset messageId userId, visibleMessages : VisibleMessages messageId }
                channel2 =
                    { channel | messages = SeqDict.foldl ArrayWithOffset.set channel.messages messagesLoaded2 }
            in
            { channel2 | visibleMessages = VisibleMessages.subsequentLoads channel2 }

        EmptyPlaceholder ->
            channel
