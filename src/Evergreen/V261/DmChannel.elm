module Evergreen.V261.DmChannel exposing (..)

import Array
import Evergreen.V261.Discord
import Evergreen.V261.Go
import Evergreen.V261.Id
import Evergreen.V261.Message
import Evergreen.V261.NonemptyDict
import Evergreen.V261.OneToOne
import Evergreen.V261.SecretId
import Evergreen.V261.Thread
import Evergreen.V261.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V261.Message.MessageState Evergreen.V261.Id.ChannelMessageId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId))
    , visibleMessages : Evergreen.V261.VisibleMessages.VisibleMessages Evergreen.V261.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) (Evergreen.V261.Thread.LastTypedAt Evergreen.V261.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) Evergreen.V261.Thread.FrontendThread
    , goMatches :
        SeqDict.SeqDict
            (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId)
            { setup : Evergreen.V261.Go.ValidatedSetup
            , actions : Array.Array Evergreen.V261.Go.ActionWithTime
            , publicLink : Maybe (Evergreen.V261.SecretId.SecretId Evergreen.V261.Id.GoMatchPublicId)
            }
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V261.Message.MessageState Evergreen.V261.Id.ChannelMessageId (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId))
    , visibleMessages : Evergreen.V261.VisibleMessages.VisibleMessages Evergreen.V261.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Thread.LastTypedAt Evergreen.V261.Id.ChannelMessageId)
    , members :
        Evergreen.V261.NonemptyDict.NonemptyDict
            (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V261.Message.Message Evergreen.V261.Id.ChannelMessageId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) (Evergreen.V261.Thread.LastTypedAt Evergreen.V261.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) Evergreen.V261.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) ( Evergreen.V261.Go.ValidatedSetup, Array.Array Evergreen.V261.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V261.Message.Message Evergreen.V261.Id.ChannelMessageId (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (Evergreen.V261.Thread.LastTypedAt Evergreen.V261.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V261.OneToOne.OneToOne (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId)
    , members :
        Evergreen.V261.NonemptyDict.NonemptyDict
            (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId)
            { messagesSent : Int
            }
    }
