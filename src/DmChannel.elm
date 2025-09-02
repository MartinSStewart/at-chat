module DmChannel exposing
    ( DmChannel
    , DmChannelId(..)
    , FrontendDmChannel
    , FrontendThread
    , LastTypedAt
    , Thread
    , channelIdFromUserIds
    , frontendInit
    , frontendThreadInit
    , getArray
    , init
    , otherUserId
    , pageSize
    , setArray
    , threadInit
    , threadToFrontend
    , toFrontend
    , toFrontendHelper
    )

import Array exposing (Array)
import Discord.Id
import Id exposing (ChannelMessageId, Id(..), ThreadMessageId, ThreadRoute(..), UserId)
import Message exposing (Message, MessageState(..))
import OneToOne exposing (OneToOne)
import SeqDict exposing (SeqDict)
import Time


type alias DmChannel =
    { messages : Array (Message ChannelMessageId)
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) Thread
    , linkedThreadIds : OneToOne (Discord.Id.Id Discord.Id.ChannelId) (Id ChannelMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array (MessageState ChannelMessageId)
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) FrontendThread
    }


type alias Thread =
    { messages : Array (Message ThreadMessageId)
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ThreadMessageId)
    , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ThreadMessageId)
    }


type alias FrontendThread =
    { messages : Array (MessageState ThreadMessageId)
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ThreadMessageId)
    }


threadInit : Thread
threadInit =
    { messages = Array.empty
    , lastTypedAt = SeqDict.empty
    , linkedMessageIds = OneToOne.empty
    }


frontendThreadInit : FrontendThread
frontendThreadInit =
    { messages = Array.empty
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
    , lastTypedAt = SeqDict.empty
    , threads = SeqDict.empty
    }


toFrontend : Maybe ThreadRoute -> DmChannel -> FrontendDmChannel
toFrontend threadRoute dmChannel =
    { messages = toFrontendHelper (Just NoThread == threadRoute) dmChannel
    , lastTypedAt = dmChannel.lastTypedAt
    , threads =
        SeqDict.map
            (\threadId thread -> threadToFrontend (Just (ViewThread threadId) == threadRoute) thread)
            dmChannel.threads
    }


threadToFrontend : Bool -> Thread -> FrontendThread
threadToFrontend preloadMessages thread =
    { messages = loadMessages preloadMessages thread.messages
    , lastTypedAt = thread.lastTypedAt
    }


loadMessages : Bool -> Array (Message messageId) -> Array (MessageState messageId)
loadMessages preloadMessages messages =
    let
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


pageSize : number
pageSize =
    20


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
