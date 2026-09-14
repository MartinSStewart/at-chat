module Evergreen.V382.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V382.Discord
import Evergreen.V382.Drawing
import Evergreen.V382.Game
import Evergreen.V382.Id
import Evergreen.V382.IdArray
import Evergreen.V382.Message
import Evergreen.V382.MessageArray
import Evergreen.V382.NonemptyDict
import Evergreen.V382.OneToOne
import Evergreen.V382.SessionIdHash
import Evergreen.V382.Thread
import Evergreen.V382.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V382.Id.Id Evergreen.V382.Id.UserId, Evergreen.V382.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V382.Id.Id Evergreen.V382.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V382.Id.Id Evergreen.V382.Id.UserId, Evergreen.V382.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V382.MessageArray.MessageArray Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    , visibleMessages : Evergreen.V382.VisibleMessages.VisibleMessages Evergreen.V382.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (Evergreen.V382.Thread.LastTypedAt Evergreen.V382.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V382.Drawing.Drawing (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V382.MessageArray.MessageArray Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
    , visibleMessages : Evergreen.V382.VisibleMessages.VisibleMessages Evergreen.V382.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Thread.LastTypedAt Evergreen.V382.Id.ChannelMessageId)
    , members :
        Evergreen.V382.NonemptyDict.NonemptyDict
            (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V382.Drawing.Drawing (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId))
    }


type alias BackendDmChannel =
    { messages : Evergreen.V382.IdArray.IdArray Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Message.Message Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (Evergreen.V382.Thread.LastTypedAt Evergreen.V382.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V382.Drawing.Drawing (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V382.IdArray.IdArray Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Message.Message Evergreen.V382.Id.ChannelMessageId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (Evergreen.V382.Thread.LastTypedAt Evergreen.V382.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V382.OneToOne.OneToOne (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId)
    , members :
        Evergreen.V382.NonemptyDict.NonemptyDict
            (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V382.Drawing.Drawing (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId))
    }
