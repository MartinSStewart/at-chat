module Evergreen.V375.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V375.Discord
import Evergreen.V375.Drawing
import Evergreen.V375.Game
import Evergreen.V375.Id
import Evergreen.V375.IdArray
import Evergreen.V375.Message
import Evergreen.V375.MessageArray
import Evergreen.V375.NonemptyDict
import Evergreen.V375.OneToOne
import Evergreen.V375.SessionIdHash
import Evergreen.V375.Thread
import Evergreen.V375.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V375.Id.Id Evergreen.V375.Id.UserId, Evergreen.V375.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V375.Id.Id Evergreen.V375.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V375.Id.Id Evergreen.V375.Id.UserId, Evergreen.V375.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V375.MessageArray.MessageArray Evergreen.V375.Id.ChannelMessageId (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    , visibleMessages : Evergreen.V375.VisibleMessages.VisibleMessages Evergreen.V375.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (Evergreen.V375.Thread.LastTypedAt Evergreen.V375.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V375.Drawing.Drawing (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V375.MessageArray.MessageArray Evergreen.V375.Id.ChannelMessageId (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
    , visibleMessages : Evergreen.V375.VisibleMessages.VisibleMessages Evergreen.V375.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Thread.LastTypedAt Evergreen.V375.Id.ChannelMessageId)
    , members :
        Evergreen.V375.NonemptyDict.NonemptyDict
            (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V375.Drawing.Drawing (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId))
    }


type alias BackendDmChannel =
    { messages : Evergreen.V375.IdArray.IdArray Evergreen.V375.Id.ChannelMessageId (Evergreen.V375.Message.Message Evergreen.V375.Id.ChannelMessageId (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (Evergreen.V375.Thread.LastTypedAt Evergreen.V375.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) Evergreen.V375.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V375.Drawing.Drawing (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V375.IdArray.IdArray Evergreen.V375.Id.ChannelMessageId (Evergreen.V375.Message.Message Evergreen.V375.Id.ChannelMessageId (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (Evergreen.V375.Thread.LastTypedAt Evergreen.V375.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V375.OneToOne.OneToOne (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId)
    , members :
        Evergreen.V375.NonemptyDict.NonemptyDict
            (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V375.Drawing.Drawing (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId))
    }
