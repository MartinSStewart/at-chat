module Evergreen.V253.DmChannel exposing (..)

import Array
import Evergreen.V253.Discord
import Evergreen.V253.Go
import Evergreen.V253.Id
import Evergreen.V253.Message
import Evergreen.V253.NonemptyDict
import Evergreen.V253.OneToOne
import Evergreen.V253.SecretId
import Evergreen.V253.Thread
import Evergreen.V253.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V253.Message.MessageState Evergreen.V253.Id.ChannelMessageId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId))
    , visibleMessages : Evergreen.V253.VisibleMessages.VisibleMessages Evergreen.V253.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) (Evergreen.V253.Thread.LastTypedAt Evergreen.V253.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) Evergreen.V253.Thread.FrontendThread
    , goMatches :
        SeqDict.SeqDict
            (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId)
            { setup : Evergreen.V253.Go.ValidatedSetup
            , actions : Array.Array Evergreen.V253.Go.ActionWithTime
            , publicLink : Maybe (Evergreen.V253.SecretId.SecretId Evergreen.V253.Id.GoMatchPublicId)
            }
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V253.Message.MessageState Evergreen.V253.Id.ChannelMessageId (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId))
    , visibleMessages : Evergreen.V253.VisibleMessages.VisibleMessages Evergreen.V253.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Thread.LastTypedAt Evergreen.V253.Id.ChannelMessageId)
    , members :
        Evergreen.V253.NonemptyDict.NonemptyDict
            (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V253.Message.Message Evergreen.V253.Id.ChannelMessageId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) (Evergreen.V253.Thread.LastTypedAt Evergreen.V253.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) Evergreen.V253.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) ( Evergreen.V253.Go.ValidatedSetup, Array.Array Evergreen.V253.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V253.Message.Message Evergreen.V253.Id.ChannelMessageId (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (Evergreen.V253.Thread.LastTypedAt Evergreen.V253.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V253.OneToOne.OneToOne (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId)
    , members :
        Evergreen.V253.NonemptyDict.NonemptyDict
            (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId)
            { messagesSent : Int
            }
    }
