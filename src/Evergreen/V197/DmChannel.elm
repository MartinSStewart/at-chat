module Evergreen.V197.DmChannel exposing (..)

import Array
import Evergreen.V197.Discord
import Evergreen.V197.Id
import Evergreen.V197.Message
import Evergreen.V197.NonemptyDict
import Evergreen.V197.OneToOne
import Evergreen.V197.Thread
import Evergreen.V197.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V197.Message.MessageState Evergreen.V197.Id.ChannelMessageId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))
    , visibleMessages : Evergreen.V197.VisibleMessages.VisibleMessages Evergreen.V197.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) (Evergreen.V197.Thread.LastTypedAt Evergreen.V197.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) Evergreen.V197.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V197.Message.MessageState Evergreen.V197.Id.ChannelMessageId (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId))
    , visibleMessages : Evergreen.V197.VisibleMessages.VisibleMessages Evergreen.V197.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Thread.LastTypedAt Evergreen.V197.Id.ChannelMessageId)
    , members :
        Evergreen.V197.NonemptyDict.NonemptyDict
            (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V197.Message.Message Evergreen.V197.Id.ChannelMessageId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) (Evergreen.V197.Thread.LastTypedAt Evergreen.V197.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) Evergreen.V197.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V197.Message.Message Evergreen.V197.Id.ChannelMessageId (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (Evergreen.V197.Thread.LastTypedAt Evergreen.V197.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V197.OneToOne.OneToOne (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId)
    , members :
        Evergreen.V197.NonemptyDict.NonemptyDict
            (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId)
            { messagesSent : Int
            }
    }
