module Evergreen.V250.DmChannel exposing (..)

import Array
import Evergreen.V250.Discord
import Evergreen.V250.Go
import Evergreen.V250.Id
import Evergreen.V250.Message
import Evergreen.V250.NonemptyDict
import Evergreen.V250.OneToOne
import Evergreen.V250.SecretId
import Evergreen.V250.Thread
import Evergreen.V250.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V250.Message.MessageState Evergreen.V250.Id.ChannelMessageId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId))
    , visibleMessages : Evergreen.V250.VisibleMessages.VisibleMessages Evergreen.V250.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) (Evergreen.V250.Thread.LastTypedAt Evergreen.V250.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) Evergreen.V250.Thread.FrontendThread
    , goMatches :
        SeqDict.SeqDict
            (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId)
            { setup : Evergreen.V250.Go.ValidatedSetup
            , actions : Array.Array Evergreen.V250.Go.ActionWithTime
            , publicLink : Maybe (Evergreen.V250.SecretId.SecretId Evergreen.V250.Id.GoMatchPublicId)
            }
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V250.Message.MessageState Evergreen.V250.Id.ChannelMessageId (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId))
    , visibleMessages : Evergreen.V250.VisibleMessages.VisibleMessages Evergreen.V250.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Thread.LastTypedAt Evergreen.V250.Id.ChannelMessageId)
    , members :
        Evergreen.V250.NonemptyDict.NonemptyDict
            (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V250.Message.Message Evergreen.V250.Id.ChannelMessageId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) (Evergreen.V250.Thread.LastTypedAt Evergreen.V250.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) Evergreen.V250.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId) ( Evergreen.V250.Go.ValidatedSetup, Array.Array Evergreen.V250.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V250.Message.Message Evergreen.V250.Id.ChannelMessageId (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (Evergreen.V250.Thread.LastTypedAt Evergreen.V250.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V250.OneToOne.OneToOne (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ChannelMessageId)
    , members :
        Evergreen.V250.NonemptyDict.NonemptyDict
            (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId)
            { messagesSent : Int
            }
    }
