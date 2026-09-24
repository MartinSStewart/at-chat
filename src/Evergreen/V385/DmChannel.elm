module Evergreen.V385.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V385.Discord
import Evergreen.V385.Drawing
import Evergreen.V385.Game
import Evergreen.V385.Id
import Evergreen.V385.IdArray
import Evergreen.V385.Message
import Evergreen.V385.MessageArray
import Evergreen.V385.NonemptyDict
import Evergreen.V385.OneToOne
import Evergreen.V385.SessionIdHash
import Evergreen.V385.Thread
import Evergreen.V385.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V385.Id.Id Evergreen.V385.Id.UserId, Evergreen.V385.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V385.Id.Id Evergreen.V385.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V385.Id.Id Evergreen.V385.Id.UserId, Evergreen.V385.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V385.MessageArray.MessageArray Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    , visibleMessages : Evergreen.V385.VisibleMessages.VisibleMessages Evergreen.V385.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Evergreen.V385.Thread.LastTypedAt Evergreen.V385.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V385.Drawing.Drawing (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V385.MessageArray.MessageArray Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
    , visibleMessages : Evergreen.V385.VisibleMessages.VisibleMessages Evergreen.V385.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Thread.LastTypedAt Evergreen.V385.Id.ChannelMessageId)
    , members :
        Evergreen.V385.NonemptyDict.NonemptyDict
            (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V385.Drawing.Drawing (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.Message.Message Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V385.IdArray.IdArray Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Message.Message Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Evergreen.V385.Thread.LastTypedAt Evergreen.V385.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V385.Drawing.Drawing (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V385.IdArray.IdArray Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Message.Message Evergreen.V385.Id.ChannelMessageId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (Evergreen.V385.Thread.LastTypedAt Evergreen.V385.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V385.OneToOne.OneToOne (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId)
    , members :
        Evergreen.V385.NonemptyDict.NonemptyDict
            (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V385.Drawing.Drawing (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId))
    }
