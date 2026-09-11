module Evergreen.V378.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V378.Discord
import Evergreen.V378.Drawing
import Evergreen.V378.Game
import Evergreen.V378.Id
import Evergreen.V378.IdArray
import Evergreen.V378.Message
import Evergreen.V378.MessageArray
import Evergreen.V378.NonemptyDict
import Evergreen.V378.OneToOne
import Evergreen.V378.SessionIdHash
import Evergreen.V378.Thread
import Evergreen.V378.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V378.Id.Id Evergreen.V378.Id.UserId, Evergreen.V378.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V378.Id.Id Evergreen.V378.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V378.Id.Id Evergreen.V378.Id.UserId, Evergreen.V378.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V378.MessageArray.MessageArray Evergreen.V378.Id.ChannelMessageId (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    , visibleMessages : Evergreen.V378.VisibleMessages.VisibleMessages Evergreen.V378.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (Evergreen.V378.Thread.LastTypedAt Evergreen.V378.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V378.Drawing.Drawing (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V378.MessageArray.MessageArray Evergreen.V378.Id.ChannelMessageId (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
    , visibleMessages : Evergreen.V378.VisibleMessages.VisibleMessages Evergreen.V378.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Thread.LastTypedAt Evergreen.V378.Id.ChannelMessageId)
    , members :
        Evergreen.V378.NonemptyDict.NonemptyDict
            (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V378.Drawing.Drawing (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId))
    }


type alias BackendDmChannel =
    { messages : Evergreen.V378.IdArray.IdArray Evergreen.V378.Id.ChannelMessageId (Evergreen.V378.Message.Message Evergreen.V378.Id.ChannelMessageId (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (Evergreen.V378.Thread.LastTypedAt Evergreen.V378.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V378.Drawing.Drawing (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V378.IdArray.IdArray Evergreen.V378.Id.ChannelMessageId (Evergreen.V378.Message.Message Evergreen.V378.Id.ChannelMessageId (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (Evergreen.V378.Thread.LastTypedAt Evergreen.V378.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V378.OneToOne.OneToOne (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId)
    , members :
        Evergreen.V378.NonemptyDict.NonemptyDict
            (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V378.Drawing.Drawing (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId))
    }
