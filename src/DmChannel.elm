module DmChannel exposing
    ( DmChannel
    , DmChannelId(..)
    , ExternalChannelId(..)
    , ExternalMessageId(..)
    , FrontendDmChannel
    , FrontendThread
    , LastTypedAt
    , Thread
    , VisibleMessages
    , channelIdFromUserIds
    , frontendInit
    , frontendThreadInit
    , getArray
    , incrementVisibleMessages
    , init
    , initVisibleMessages
    , latestMessageId
    , latestThreadMessageId
    , otherUserId
    , pageSize
    , setArray
    , threadInit
    , threadToFrontend
    , toFrontend
    , toFrontendHelper
    , visibleMessagesFirstLoad
    , visibleMessagesForNewChannel
    , visibleMessagesLoadOlder
    , visibleMessagesSlice
    )

import Array exposing (Array)
import Discord.Id
import Id exposing (ChannelMessageId, Id(..), ThreadMessageId, ThreadRoute(..), UserId)
import Message exposing (Message, MessageState(..))
import OneToOne exposing (OneToOne)
import SeqDict exposing (SeqDict)
import Slack
import Time


type alias DmChannel =
    { messages : Array (Message ChannelMessageId)
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , linkedMessageIds : OneToOne ExternalMessageId (Id ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) Thread
    , linkedThreadIds : OneToOne ExternalChannelId (Id ChannelMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array (MessageState ChannelMessageId)
    , visibleMessages : VisibleMessages ChannelMessageId
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) FrontendThread
    }


type alias Thread =
    { messages : Array (Message ThreadMessageId)
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ThreadMessageId)
    , linkedMessageIds : OneToOne ExternalMessageId (Id ThreadMessageId)
    }


type alias FrontendThread =
    { messages : Array (MessageState ThreadMessageId)
    , visibleMessages : VisibleMessages ThreadMessageId
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Discord.Id.Id Discord.Id.ChannelId)
    | SlackChannelId (Slack.Id Slack.ChannelId)


type ExternalMessageId
    = DiscordMessageId (Discord.Id.Id Discord.Id.MessageId)
    | SlackMessageId (Slack.Id Slack.MessageId)


threadInit : Thread
threadInit =
    { messages = Array.empty
    , lastTypedAt = SeqDict.empty
    , linkedMessageIds = OneToOne.empty
    }


frontendThreadInit : FrontendThread
frontendThreadInit =
    { messages = Array.empty
    , visibleMessages = visibleMessagesForNewChannel
    , lastTypedAt = SeqDict.empty
    }


{-| OpaqueVariants
-}
type DmChannelId
    = DirectMessageChannelId (Id UserId) (Id UserId)


type alias LastTypedAt messageId =
    { time : Time.Posix, messageIndex : Maybe (Id messageId) }


init : DmChannel
init =
    { messages = Array.empty
    , lastTypedAt = SeqDict.empty
    , linkedMessageIds = OneToOne.empty
    , threads = SeqDict.empty
    , linkedThreadIds = OneToOne.empty
    }


frontendInit : FrontendDmChannel
frontendInit =
    { messages = Array.empty
    , visibleMessages = visibleMessagesForNewChannel
    , lastTypedAt = SeqDict.empty
    , threads = SeqDict.empty
    }


type alias VisibleMessages messageId =
    { oldest : Id messageId, newest : Int }


toFrontend : Maybe ThreadRoute -> DmChannel -> FrontendDmChannel
toFrontend threadRoute dmChannel =
    let
        preloadMessages =
            Just NoThread == threadRoute
    in
    { messages = toFrontendHelper preloadMessages dmChannel
    , visibleMessages = initVisibleMessages preloadMessages dmChannel
    , lastTypedAt = dmChannel.lastTypedAt
    , threads =
        SeqDict.map
            (\threadId thread -> threadToFrontend (Just (ViewThread threadId) == threadRoute) thread)
            dmChannel.threads
    }


threadToFrontend : Bool -> Thread -> FrontendThread
threadToFrontend preloadMessages thread =
    { messages = loadMessages preloadMessages thread.messages
    , visibleMessages = initVisibleMessages preloadMessages thread
    , lastTypedAt = thread.lastTypedAt
    }


initVisibleMessages : Bool -> { a | messages : Array (Message messageId) } -> VisibleMessages messageId
initVisibleMessages preloadMessages channel =
    if preloadMessages then
        { oldest = Array.length channel.messages - pageSize - 1 |> max 0 |> Id.fromInt
        , newest = Array.length channel.messages
        }

    else
        visibleMessagesForNewChannel


visibleMessagesForNewChannel : VisibleMessages messageId
visibleMessagesForNewChannel =
    { oldest = Id.fromInt 0, newest = 0 }


incrementVisibleMessages : { a | messages : Array b } -> VisibleMessages messageId -> VisibleMessages messageId
incrementVisibleMessages channel visibleMessages =
    if visibleMessages.newest == Array.length channel.messages then
        { oldest = visibleMessages.oldest, newest = visibleMessages.newest + 1 }

    else
        visibleMessages


visibleMessagesLoadOlder : Id messageId -> VisibleMessages messageId -> VisibleMessages messageId
visibleMessagesLoadOlder previousOldestVisibleMessage visibleMessages =
    { oldest = Id.toInt previousOldestVisibleMessage - pageSize |> max 0 |> Id.fromInt
    , newest = visibleMessages.newest
    }


visibleMessagesFirstLoad : { a | messages : Array b } -> VisibleMessages messageId
visibleMessagesFirstLoad channel =
    { oldest = Array.length channel.messages - pageSize - 1 |> Id.fromInt
    , newest = Array.length channel.messages
    }


visibleMessagesSlice :
    { a | visibleMessages : VisibleMessages messageId, messages : Array (MessageState messageId) }
    -> Array (MessageState messageId)
visibleMessagesSlice { visibleMessages, messages } =
    Array.slice (Id.toInt visibleMessages.oldest) visibleMessages.newest messages


latestMessageId : { a | messages : Array b } -> Id ChannelMessageId
latestMessageId channel =
    Array.length channel.messages - 1 |> Id.fromInt


latestThreadMessageId : { a | messages : Array b } -> Id ThreadMessageId
latestThreadMessageId thread =
    Array.length thread.messages - 1 |> Id.fromInt


loadMessages : Bool -> Array (Message messageId) -> Array (MessageState messageId)
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
                if messageCount - index < pageSize then
                    case Array.get index messages of
                        Just message ->
                            MessageLoaded message

                        Nothing ->
                            MessageUnloaded

                else
                    MessageUnloaded
            )

    else
        Array.repeat messageCount MessageUnloaded
            |> Array.set
                (messageCount - 1)
                (case Array.get (messageCount - 1) messages of
                    Just message ->
                        MessageLoaded message

                    Nothing ->
                        MessageUnloaded
                )


pageSize : number
pageSize =
    30


toFrontendHelper :
    Bool
    -> { a | messages : Array (Message ChannelMessageId), threads : SeqDict (Id ChannelMessageId) Thread }
    -> Array (MessageState ChannelMessageId)
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
