module DmChannel exposing
    ( DiscordFrontendThread
    , DiscordThread
    , DmChannel
    , DmChannelId(..)
    , ExternalChannelId(..)
    , ExternalMessageId(..)
    , FrontendDmChannel
    , FrontendThread
    , LastTypedAt
    , Thread
    , channelIdFromUserIds
    , discordFrontendThreadInit
    , discordThreadInit
    , frontendInit
    , frontendThreadInit
    , getArray
    , init
    , latestMessageId
    , latestThreadMessageId
    , loadMessages
    , otherUserId
    , setArray
    , threadInit
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
import Slack
import Time
import VisibleMessages exposing (VisibleMessages)


type alias DmChannel =
    { messages : Array (Message ChannelMessageId (Id UserId))
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) Thread
    }


type alias FrontendDmChannel =
    { messages : Array (MessageState ChannelMessageId (Id UserId))
    , visibleMessages : VisibleMessages ChannelMessageId
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) FrontendThread
    }


type alias Thread =
    { messages : Array (Message ThreadMessageId (Id UserId))
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ThreadMessageId)
    }


type alias DiscordThread =
    { messages : Array (Message ThreadMessageId (Discord.Id.Id Discord.Id.UserId))
    , lastTypedAt : SeqDict (Discord.Id.Id Discord.Id.UserId) (LastTypedAt ThreadMessageId)
    , linkedMessages : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ThreadMessageId)
    }


type alias FrontendThread =
    { messages : Array (MessageState ThreadMessageId (Id UserId))
    , visibleMessages : VisibleMessages ThreadMessageId
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array (MessageState ThreadMessageId (Discord.Id.Id Discord.Id.UserId))
    , visibleMessages : VisibleMessages ThreadMessageId
    , linkedMessages : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ThreadMessageId)
    , lastTypedAt : SeqDict (Discord.Id.Id Discord.Id.UserId) (LastTypedAt ThreadMessageId)
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
    }


frontendThreadInit : FrontendThread
frontendThreadInit =
    { messages = Array.empty
    , visibleMessages = VisibleMessages.empty
    , lastTypedAt = SeqDict.empty
    }


discordThreadInit : DiscordThread
discordThreadInit =
    { messages = Array.empty
    , lastTypedAt = SeqDict.empty
    , linkedMessages = OneToOne.empty
    }


discordFrontendThreadInit : DiscordFrontendThread
discordFrontendThreadInit =
    { messages = Array.empty
    , visibleMessages = VisibleMessages.empty
    , lastTypedAt = SeqDict.empty
    , linkedMessages = OneToOne.empty
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
    , threads = SeqDict.empty
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


threadToFrontend : Bool -> Thread -> FrontendThread
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
    -> { a | messages : Array (Message messageId userId), threads : SeqDict (Id messageId) Thread }
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


toDiscordFrontendHelper :
    Bool
    -> { a | messages : Array (Message messageId userId), threads : SeqDict (Id messageId) DiscordThread }
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
