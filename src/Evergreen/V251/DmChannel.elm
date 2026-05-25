module Evergreen.V251.DmChannel exposing (..)

import Array
import Evergreen.V251.Discord
import Evergreen.V251.Go
import Evergreen.V251.Id
import Evergreen.V251.Message
import Evergreen.V251.NonemptyDict
import Evergreen.V251.OneToOne
import Evergreen.V251.SecretId
import Evergreen.V251.Thread
import Evergreen.V251.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V251.Message.MessageState Evergreen.V251.Id.ChannelMessageId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId))
    , visibleMessages : Evergreen.V251.VisibleMessages.VisibleMessages Evergreen.V251.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) (Evergreen.V251.Thread.LastTypedAt Evergreen.V251.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) Evergreen.V251.Thread.FrontendThread
    , goMatches :
        SeqDict.SeqDict
            (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId)
            { setup : Evergreen.V251.Go.ValidatedSetup
            , actions : Array.Array Evergreen.V251.Go.ActionWithTime
            , publicLink : Maybe (Evergreen.V251.SecretId.SecretId Evergreen.V251.Id.GoMatchPublicId)
            }
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V251.Message.MessageState Evergreen.V251.Id.ChannelMessageId (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId))
    , visibleMessages : Evergreen.V251.VisibleMessages.VisibleMessages Evergreen.V251.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Thread.LastTypedAt Evergreen.V251.Id.ChannelMessageId)
    , members :
        Evergreen.V251.NonemptyDict.NonemptyDict
            (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V251.Message.Message Evergreen.V251.Id.ChannelMessageId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) (Evergreen.V251.Thread.LastTypedAt Evergreen.V251.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) Evergreen.V251.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId) ( Evergreen.V251.Go.ValidatedSetup, Array.Array Evergreen.V251.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V251.Message.Message Evergreen.V251.Id.ChannelMessageId (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (Evergreen.V251.Thread.LastTypedAt Evergreen.V251.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V251.OneToOne.OneToOne (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ChannelMessageId)
    , members :
        Evergreen.V251.NonemptyDict.NonemptyDict
            (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId)
            { messagesSent : Int
            }
    }
