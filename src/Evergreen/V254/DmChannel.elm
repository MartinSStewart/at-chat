module Evergreen.V254.DmChannel exposing (..)

import Array
import Evergreen.V254.Discord
import Evergreen.V254.Go
import Evergreen.V254.Id
import Evergreen.V254.Message
import Evergreen.V254.NonemptyDict
import Evergreen.V254.OneToOne
import Evergreen.V254.SecretId
import Evergreen.V254.Thread
import Evergreen.V254.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V254.Message.MessageState Evergreen.V254.Id.ChannelMessageId (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId))
    , visibleMessages : Evergreen.V254.VisibleMessages.VisibleMessages Evergreen.V254.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) (Evergreen.V254.Thread.LastTypedAt Evergreen.V254.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) Evergreen.V254.Thread.FrontendThread
    , goMatches :
        SeqDict.SeqDict
            (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId)
            { setup : Evergreen.V254.Go.ValidatedSetup
            , actions : Array.Array Evergreen.V254.Go.ActionWithTime
            , publicLink : Maybe (Evergreen.V254.SecretId.SecretId Evergreen.V254.Id.GoMatchPublicId)
            }
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V254.Message.MessageState Evergreen.V254.Id.ChannelMessageId (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId))
    , visibleMessages : Evergreen.V254.VisibleMessages.VisibleMessages Evergreen.V254.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (Evergreen.V254.Thread.LastTypedAt Evergreen.V254.Id.ChannelMessageId)
    , members :
        Evergreen.V254.NonemptyDict.NonemptyDict
            (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V254.Message.Message Evergreen.V254.Id.ChannelMessageId (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) (Evergreen.V254.Thread.LastTypedAt Evergreen.V254.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) Evergreen.V254.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) ( Evergreen.V254.Go.ValidatedSetup, Array.Array Evergreen.V254.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V254.Message.Message Evergreen.V254.Id.ChannelMessageId (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (Evergreen.V254.Thread.LastTypedAt Evergreen.V254.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V254.OneToOne.OneToOne (Evergreen.V254.Discord.Id Evergreen.V254.Discord.MessageId) (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId)
    , members :
        Evergreen.V254.NonemptyDict.NonemptyDict
            (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId)
            { messagesSent : Int
            }
    }
