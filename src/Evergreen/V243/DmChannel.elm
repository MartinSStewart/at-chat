module Evergreen.V243.DmChannel exposing (..)

import Array
import Evergreen.V243.Discord
import Evergreen.V243.Go
import Evergreen.V243.Id
import Evergreen.V243.Message
import Evergreen.V243.NonemptyDict
import Evergreen.V243.OneToOne
import Evergreen.V243.SecretId
import Evergreen.V243.Thread
import Evergreen.V243.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V243.Message.MessageState Evergreen.V243.Id.ChannelMessageId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId))
    , visibleMessages : Evergreen.V243.VisibleMessages.VisibleMessages Evergreen.V243.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) (Evergreen.V243.Thread.LastTypedAt Evergreen.V243.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) Evergreen.V243.Thread.FrontendThread
    , goMatches :
        SeqDict.SeqDict
            (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId)
            { setup : Evergreen.V243.Go.ValidatedSetup
            , actions : Array.Array Evergreen.V243.Go.ActionWithTime
            , publicLink : Maybe (Evergreen.V243.SecretId.SecretId Evergreen.V243.Id.GoMatchPublicId)
            }
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V243.Message.MessageState Evergreen.V243.Id.ChannelMessageId (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId))
    , visibleMessages : Evergreen.V243.VisibleMessages.VisibleMessages Evergreen.V243.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Thread.LastTypedAt Evergreen.V243.Id.ChannelMessageId)
    , members :
        Evergreen.V243.NonemptyDict.NonemptyDict
            (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V243.Message.Message Evergreen.V243.Id.ChannelMessageId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) (Evergreen.V243.Thread.LastTypedAt Evergreen.V243.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) Evergreen.V243.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) ( Evergreen.V243.Go.ValidatedSetup, Array.Array Evergreen.V243.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V243.Message.Message Evergreen.V243.Id.ChannelMessageId (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (Evergreen.V243.Thread.LastTypedAt Evergreen.V243.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V243.OneToOne.OneToOne (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId)
    , members :
        Evergreen.V243.NonemptyDict.NonemptyDict
            (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId)
            { messagesSent : Int
            }
    }
