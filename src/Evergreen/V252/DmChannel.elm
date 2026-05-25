module Evergreen.V252.DmChannel exposing (..)

import Array
import Evergreen.V252.Discord
import Evergreen.V252.Go
import Evergreen.V252.Id
import Evergreen.V252.Message
import Evergreen.V252.NonemptyDict
import Evergreen.V252.OneToOne
import Evergreen.V252.SecretId
import Evergreen.V252.Thread
import Evergreen.V252.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V252.Message.MessageState Evergreen.V252.Id.ChannelMessageId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId))
    , visibleMessages : Evergreen.V252.VisibleMessages.VisibleMessages Evergreen.V252.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) (Evergreen.V252.Thread.LastTypedAt Evergreen.V252.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) Evergreen.V252.Thread.FrontendThread
    , goMatches :
        SeqDict.SeqDict
            (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId)
            { setup : Evergreen.V252.Go.ValidatedSetup
            , actions : Array.Array Evergreen.V252.Go.ActionWithTime
            , publicLink : Maybe (Evergreen.V252.SecretId.SecretId Evergreen.V252.Id.GoMatchPublicId)
            }
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V252.Message.MessageState Evergreen.V252.Id.ChannelMessageId (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId))
    , visibleMessages : Evergreen.V252.VisibleMessages.VisibleMessages Evergreen.V252.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Thread.LastTypedAt Evergreen.V252.Id.ChannelMessageId)
    , members :
        Evergreen.V252.NonemptyDict.NonemptyDict
            (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V252.Message.Message Evergreen.V252.Id.ChannelMessageId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) (Evergreen.V252.Thread.LastTypedAt Evergreen.V252.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) Evergreen.V252.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) ( Evergreen.V252.Go.ValidatedSetup, Array.Array Evergreen.V252.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V252.Message.Message Evergreen.V252.Id.ChannelMessageId (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (Evergreen.V252.Thread.LastTypedAt Evergreen.V252.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V252.OneToOne.OneToOne (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId)
    , members :
        Evergreen.V252.NonemptyDict.NonemptyDict
            (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId)
            { messagesSent : Int
            }
    }
