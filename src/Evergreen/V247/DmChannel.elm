module Evergreen.V247.DmChannel exposing (..)

import Array
import Evergreen.V247.Discord
import Evergreen.V247.Go
import Evergreen.V247.Id
import Evergreen.V247.Message
import Evergreen.V247.NonemptyDict
import Evergreen.V247.OneToOne
import Evergreen.V247.SecretId
import Evergreen.V247.Thread
import Evergreen.V247.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V247.Message.MessageState Evergreen.V247.Id.ChannelMessageId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId))
    , visibleMessages : Evergreen.V247.VisibleMessages.VisibleMessages Evergreen.V247.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) (Evergreen.V247.Thread.LastTypedAt Evergreen.V247.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) Evergreen.V247.Thread.FrontendThread
    , goMatches :
        SeqDict.SeqDict
            (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId)
            { setup : Evergreen.V247.Go.ValidatedSetup
            , actions : Array.Array Evergreen.V247.Go.ActionWithTime
            , publicLink : Maybe (Evergreen.V247.SecretId.SecretId Evergreen.V247.Id.GoMatchPublicId)
            }
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V247.Message.MessageState Evergreen.V247.Id.ChannelMessageId (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId))
    , visibleMessages : Evergreen.V247.VisibleMessages.VisibleMessages Evergreen.V247.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Thread.LastTypedAt Evergreen.V247.Id.ChannelMessageId)
    , members :
        Evergreen.V247.NonemptyDict.NonemptyDict
            (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V247.Message.Message Evergreen.V247.Id.ChannelMessageId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) (Evergreen.V247.Thread.LastTypedAt Evergreen.V247.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) Evergreen.V247.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId) ( Evergreen.V247.Go.ValidatedSetup, Array.Array Evergreen.V247.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V247.Message.Message Evergreen.V247.Id.ChannelMessageId (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (Evergreen.V247.Thread.LastTypedAt Evergreen.V247.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V247.OneToOne.OneToOne (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ChannelMessageId)
    , members :
        Evergreen.V247.NonemptyDict.NonemptyDict
            (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId)
            { messagesSent : Int
            }
    }
