module Evergreen.V248.DmChannel exposing (..)

import Array
import Evergreen.V248.Discord
import Evergreen.V248.Go
import Evergreen.V248.Id
import Evergreen.V248.Message
import Evergreen.V248.NonemptyDict
import Evergreen.V248.OneToOne
import Evergreen.V248.SecretId
import Evergreen.V248.Thread
import Evergreen.V248.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V248.Message.MessageState Evergreen.V248.Id.ChannelMessageId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId))
    , visibleMessages : Evergreen.V248.VisibleMessages.VisibleMessages Evergreen.V248.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) (Evergreen.V248.Thread.LastTypedAt Evergreen.V248.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) Evergreen.V248.Thread.FrontendThread
    , goMatches :
        SeqDict.SeqDict
            (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId)
            { setup : Evergreen.V248.Go.ValidatedSetup
            , actions : Array.Array Evergreen.V248.Go.ActionWithTime
            , publicLink : Maybe (Evergreen.V248.SecretId.SecretId Evergreen.V248.Id.GoMatchPublicId)
            }
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V248.Message.MessageState Evergreen.V248.Id.ChannelMessageId (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId))
    , visibleMessages : Evergreen.V248.VisibleMessages.VisibleMessages Evergreen.V248.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Thread.LastTypedAt Evergreen.V248.Id.ChannelMessageId)
    , members :
        Evergreen.V248.NonemptyDict.NonemptyDict
            (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V248.Message.Message Evergreen.V248.Id.ChannelMessageId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) (Evergreen.V248.Thread.LastTypedAt Evergreen.V248.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) Evergreen.V248.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) ( Evergreen.V248.Go.ValidatedSetup, Array.Array Evergreen.V248.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V248.Message.Message Evergreen.V248.Id.ChannelMessageId (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (Evergreen.V248.Thread.LastTypedAt Evergreen.V248.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V248.OneToOne.OneToOne (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId)
    , members :
        Evergreen.V248.NonemptyDict.NonemptyDict
            (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId)
            { messagesSent : Int
            }
    }
