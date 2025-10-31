module DmChannel exposing
    ( DiscordDmChannel
    , DmChannel
    , DmChannelId(..)
    , FrontendDiscordDmChannel
    , FrontendDmChannel
    , channelIdFromUserIds
    , discordDmChannelToFrontend
    , discordInit
    , frontendInit
    , getArray
    , init
    , latestMessageId
    , latestThreadMessageId
    , loadMessages
    , otherUserId
    , setArray
    , threadToFrontend
    , toDiscordFrontendHelper
    , toFrontend
    , toFrontendHelper
    )

import Array exposing (Array)
import Discord.Id
import Id exposing (ChannelMessageId, Id(..), ThreadMessageId, ThreadRoute(..), UserId)
import Message exposing (Message, MessageState(..))
import OneToOne exposing (OneToOne)
import SeqDict exposing (SeqDict)
import Thread exposing (BackendThread, DiscordBackendThread, FrontendThread, LastTypedAt)
import VisibleMessages exposing (VisibleMessages)


type alias DmChannel =
    { messages : Array (Message ChannelMessageId (Id UserId))
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array (Message ChannelMessageId (Discord.Id.Id Discord.Id.UserId))
    , lastTypedAt : SeqDict (Discord.Id.Id Discord.Id.UserId) (LastTypedAt ChannelMessageId)
    , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ChannelMessageId)
    }


type alias FrontendDiscordDmChannel =
    { messages : Array (MessageState ChannelMessageId (Discord.Id.Id Discord.Id.UserId))
    , visibleMessages : VisibleMessages ChannelMessageId
    , lastTypedAt : SeqDict (Discord.Id.Id Discord.Id.UserId) (LastTypedAt ChannelMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array (MessageState ChannelMessageId (Id UserId))
    , visibleMessages : VisibleMessages ChannelMessageId
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) FrontendThread
    }


{-| OpaqueVariants
-}
type DmChannelId
    = DirectMessageChannelId (Id UserId) (Id UserId)


init : DmChannel
init =
    { messages = Array.empty
    , lastTypedAt = SeqDict.empty
    , threads = SeqDict.empty
    }


discordInit : DiscordDmChannel
discordInit =
    { messages = Array.empty
    , lastTypedAt = SeqDict.empty
    , linkedMessageIds = OneToOne.empty
    }


frontendInit : FrontendDmChannel
frontendInit =
    { messages = Array.empty
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
            (\threadId thread -> threadToFrontend (Just (ViewThread threadId) == threadRoute) thread)
            dmChannel.threads
    }


threadToFrontend : Bool -> BackendThread -> FrontendThread
threadToFrontend preloadMessages thread =
    { messages = loadMessages preloadMessages thread.messages
    , visibleMessages = VisibleMessages.init preloadMessages thread
    , lastTypedAt = thread.lastTypedAt
    }


latestMessageId : { a | messages : Array b } -> Id ChannelMessageId
latestMessageId channel =
    Array.length channel.messages - 1 |> Id.fromInt


latestThreadMessageId : { a | messages : Array b } -> Id ThreadMessageId
latestThreadMessageId thread =
    Array.length thread.messages - 1 |> Id.fromInt


loadMessages : Bool -> Array (Message messageId userId) -> Array (MessageState messageId userId)
loadMessages preloadMessages messages =
    let
        messageCount : Int
        messageCount =
            Array.length messages
    in
    if preloadMessages then
        Array.initialize
            messageCount
            (\index ->
                if messageCount - index <= VisibleMessages.pageSize then
                    case Array.get index messages of
                        Just message ->
                            MessageLoaded message

                        Nothing ->
                            MessageUnloaded

                else
                    MessageUnloaded
            )

    else
        -- Load the latest message for each channel/thread in case it's needed for a preview somewhere
        Array.repeat messageCount MessageUnloaded
            |> Array.set
                (messageCount - 1)
                (case Array.get (messageCount - 1) messages of
                    Just message ->
                        MessageLoaded message

                    Nothing ->
                        MessageUnloaded
                )


toFrontendHelper :
    Bool
    -> { a | messages : Array (Message messageId userId), threads : SeqDict (Id messageId) BackendThread }
    -> Array (MessageState messageId userId)
toFrontendHelper preloadMessages channel =
    SeqDict.foldl
        (\threadId _ messages ->
            setArray
                threadId
                (case getArray threadId channel.messages of
                    Just message ->
                        MessageLoaded message

                    Nothing ->
                        MessageUnloaded
                )
                messages
        )
        (loadMessages preloadMessages channel.messages)
        channel.threads


discordDmChannelToFrontend : Bool -> DiscordDmChannel -> FrontendDiscordDmChannel
discordDmChannelToFrontend preloadMessages dmChannel =
    { messages = toDiscordFrontendHelper preloadMessages { messages = dmChannel.messages, threads = SeqDict.empty }
    , visibleMessages = VisibleMessages.init preloadMessages dmChannel
    , lastTypedAt = dmChannel.lastTypedAt
    }


toDiscordFrontendHelper :
    Bool
    -> { a | messages : Array (Message messageId userId), threads : SeqDict (Id messageId) DiscordBackendThread }
    -> Array (MessageState messageId userId)
toDiscordFrontendHelper preloadMessages channel =
    SeqDict.foldl
        (\threadId _ messages ->
            setArray
                threadId
                (case getArray threadId channel.messages of
                    Just message ->
                        MessageLoaded message

                    Nothing ->
                        MessageUnloaded
                )
                messages
        )
        (loadMessages preloadMessages channel.messages)
        channel.threads


getArray : Id messageId -> Array a -> Maybe a
getArray id array =
    Array.get (Id.toInt id) array


setArray : Id messageId -> a -> Array a -> Array a
setArray id message array =
    Array.set (Id.toInt id) message array


channelIdFromUserIds : Id UserId -> Id UserId -> DmChannelId
channelIdFromUserIds (Id userIdA) (Id userIdB) =
    DirectMessageChannelId (min userIdA userIdB |> Id) (max userIdA userIdB |> Id)


otherUserId : Id UserId -> DmChannelId -> Maybe (Id UserId)
otherUserId userId (DirectMessageChannelId userIdA userIdB) =
    if userId == userIdA then
        Just userIdB

    else if userId == userIdB then
        Just userIdA

    else
        Nothing
