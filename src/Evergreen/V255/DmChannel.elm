module Evergreen.V255.DmChannel exposing (..)

import Array
import Evergreen.V255.Discord
import Evergreen.V255.Go
import Evergreen.V255.Id
import Evergreen.V255.Message
import Evergreen.V255.NonemptyDict
import Evergreen.V255.OneToOne
import Evergreen.V255.SecretId
import Evergreen.V255.Thread
import Evergreen.V255.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V255.Message.MessageState Evergreen.V255.Id.ChannelMessageId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId))
    , visibleMessages : Evergreen.V255.VisibleMessages.VisibleMessages Evergreen.V255.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) (Evergreen.V255.Thread.LastTypedAt Evergreen.V255.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) Evergreen.V255.Thread.FrontendThread
    , goMatches :
        SeqDict.SeqDict
            (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId)
            { setup : Evergreen.V255.Go.ValidatedSetup
            , actions : Array.Array Evergreen.V255.Go.ActionWithTime
            , publicLink : Maybe (Evergreen.V255.SecretId.SecretId Evergreen.V255.Id.GoMatchPublicId)
            }
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V255.Message.MessageState Evergreen.V255.Id.ChannelMessageId (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId))
    , visibleMessages : Evergreen.V255.VisibleMessages.VisibleMessages Evergreen.V255.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Thread.LastTypedAt Evergreen.V255.Id.ChannelMessageId)
    , members :
        Evergreen.V255.NonemptyDict.NonemptyDict
            (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V255.Message.Message Evergreen.V255.Id.ChannelMessageId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) (Evergreen.V255.Thread.LastTypedAt Evergreen.V255.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) Evergreen.V255.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) ( Evergreen.V255.Go.ValidatedSetup, Array.Array Evergreen.V255.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V255.Message.Message Evergreen.V255.Id.ChannelMessageId (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (Evergreen.V255.Thread.LastTypedAt Evergreen.V255.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V255.OneToOne.OneToOne (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId)
    , members :
        Evergreen.V255.NonemptyDict.NonemptyDict
            (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId)
            { messagesSent : Int
            }
    }
