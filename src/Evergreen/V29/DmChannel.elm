module Evergreen.V29.DmChannel exposing (..)

import Array
import Evergreen.V29.Discord.Id
import Evergreen.V29.Id
import Evergreen.V29.Message
import Evergreen.V29.OneToOne
import SeqDict
import Time


type alias LastTypedAt =
    { time : Time.Posix
    , messageIndex : Maybe Int
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V29.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) LastTypedAt
    , linkedMessageIds : Evergreen.V29.OneToOne.OneToOne (Evergreen.V29.Discord.Id.Id Evergreen.V29.Discord.Id.MessageId) Int
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
