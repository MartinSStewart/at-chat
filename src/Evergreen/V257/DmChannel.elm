module Evergreen.V257.DmChannel exposing (..)

import Array
import Evergreen.V257.Discord
import Evergreen.V257.Go
import Evergreen.V257.Id
import Evergreen.V257.Message
import Evergreen.V257.NonemptyDict
import Evergreen.V257.OneToOne
import Evergreen.V257.SecretId
import Evergreen.V257.Thread
import Evergreen.V257.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V257.Message.MessageState Evergreen.V257.Id.ChannelMessageId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId))
    , visibleMessages : Evergreen.V257.VisibleMessages.VisibleMessages Evergreen.V257.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) (Evergreen.V257.Thread.LastTypedAt Evergreen.V257.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) Evergreen.V257.Thread.FrontendThread
    , goMatches :
        SeqDict.SeqDict
            (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId)
            { setup : Evergreen.V257.Go.ValidatedSetup
            , actions : Array.Array Evergreen.V257.Go.ActionWithTime
            , publicLink : Maybe (Evergreen.V257.SecretId.SecretId Evergreen.V257.Id.GoMatchPublicId)
            }
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V257.Message.MessageState Evergreen.V257.Id.ChannelMessageId (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId))
    , visibleMessages : Evergreen.V257.VisibleMessages.VisibleMessages Evergreen.V257.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Thread.LastTypedAt Evergreen.V257.Id.ChannelMessageId)
    , members :
        Evergreen.V257.NonemptyDict.NonemptyDict
            (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V257.Message.Message Evergreen.V257.Id.ChannelMessageId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) (Evergreen.V257.Thread.LastTypedAt Evergreen.V257.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) Evergreen.V257.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) ( Evergreen.V257.Go.ValidatedSetup, Array.Array Evergreen.V257.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V257.Message.Message Evergreen.V257.Id.ChannelMessageId (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (Evergreen.V257.Thread.LastTypedAt Evergreen.V257.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V257.OneToOne.OneToOne (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId)
    , members :
        Evergreen.V257.NonemptyDict.NonemptyDict
            (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId)
            { messagesSent : Int
            }
    }
