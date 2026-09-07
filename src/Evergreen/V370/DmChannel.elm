module Evergreen.V370.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V370.Discord
import Evergreen.V370.Drawing
import Evergreen.V370.Game
import Evergreen.V370.Id
import Evergreen.V370.IdArray
import Evergreen.V370.Message
import Evergreen.V370.MessageArray
import Evergreen.V370.NonemptyDict
import Evergreen.V370.OneToOne
import Evergreen.V370.SessionIdHash
import Evergreen.V370.Thread
import Evergreen.V370.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V370.Id.Id Evergreen.V370.Id.UserId, Evergreen.V370.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V370.Id.Id Evergreen.V370.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V370.Id.Id Evergreen.V370.Id.UserId, Evergreen.V370.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V370.MessageArray.MessageArray Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    , visibleMessages : Evergreen.V370.VisibleMessages.VisibleMessages Evergreen.V370.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (Evergreen.V370.Thread.LastTypedAt Evergreen.V370.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V370.Drawing.Drawing (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V370.MessageArray.MessageArray Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
    , visibleMessages : Evergreen.V370.VisibleMessages.VisibleMessages Evergreen.V370.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Thread.LastTypedAt Evergreen.V370.Id.ChannelMessageId)
    , members :
        Evergreen.V370.NonemptyDict.NonemptyDict
            (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V370.Drawing.Drawing (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId))
    }


type alias BackendDmChannel =
    { messages : Evergreen.V370.IdArray.IdArray Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Message.Message Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (Evergreen.V370.Thread.LastTypedAt Evergreen.V370.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId) Evergreen.V370.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V370.Drawing.Drawing (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V370.IdArray.IdArray Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Message.Message Evergreen.V370.Id.ChannelMessageId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (Evergreen.V370.Thread.LastTypedAt Evergreen.V370.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V370.OneToOne.OneToOne (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId)
    , members :
        Evergreen.V370.NonemptyDict.NonemptyDict
            (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V370.Drawing.Drawing (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId))
    }
