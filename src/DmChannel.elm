module DmChannel exposing
    ( DmChannel
    , DmChannelId(..)
    , LastTypedAt
    , Thread
    , channelIdFromUserIds
    , init
    , otherUserId
    , threadInit
    )

import Array exposing (Array)
import Discord.Id
import Id exposing (ChannelMessageId, Id(..), ThreadMessageId, UserId)
import Message exposing (Message)
import OneToOne exposing (OneToOne)
import SeqDict exposing (SeqDict)
import Time


type alias DmChannel =
    { messages : Array Message
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) Thread
    , linkedThreadIds : OneToOne (Discord.Id.Id Discord.Id.ChannelId) (Id ChannelMessageId)
    }


type alias Thread =
    { messages : Array Message
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ThreadMessageId)
    , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ThreadMessageId)
    }


threadInit : Thread
threadInit =
    { messages = Array.empty
    , lastTypedAt = SeqDict.empty
    , linkedMessageIds = OneToOne.empty
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
