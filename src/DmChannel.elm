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
import Id exposing (Id(..), UserId)
import Message exposing (Message)
import OneToOne exposing (OneToOne)
import SeqDict exposing (SeqDict)
import Time


type alias DmChannel =
    { messages : Array Message
    , lastTypedAt : SeqDict (Id UserId) LastTypedAt
    , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) Int
    , threads : SeqDict Int Thread
    }


type alias Thread =
    { messages : Array Message
    , lastTypedAt : SeqDict (Id UserId) LastTypedAt
    , linkedId : Maybe (Discord.Id.Id Discord.Id.ChannelId)
    , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) Int
    }


threadInit : Thread
threadInit =
    { messages = Array.empty
    , lastTypedAt = SeqDict.empty
    , linkedId = Nothing
    , linkedMessageIds = OneToOne.empty
    }


{-| OpaqueVariants
-}
type DmChannelId
    = DirectMessageChannelId (Id UserId) (Id UserId)


type alias LastTypedAt =
    { time : Time.Posix, messageIndex : Maybe Int }


init : DmChannel
init =
    { messages = Array.empty
    , lastTypedAt = SeqDict.empty
    , linkedMessageIds = OneToOne.empty
    , threads = SeqDict.empty
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
