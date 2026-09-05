module Evergreen.V368.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V368.Discord
import Evergreen.V368.Drawing
import Evergreen.V368.Game
import Evergreen.V368.Id
import Evergreen.V368.IdArray
import Evergreen.V368.Message
import Evergreen.V368.MessageArray
import Evergreen.V368.NonemptyDict
import Evergreen.V368.OneToOne
import Evergreen.V368.SessionIdHash
import Evergreen.V368.Thread
import Evergreen.V368.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V368.Id.Id Evergreen.V368.Id.UserId, Evergreen.V368.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V368.Id.Id Evergreen.V368.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V368.Id.Id Evergreen.V368.Id.UserId, Evergreen.V368.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V368.MessageArray.MessageArray Evergreen.V368.Id.ChannelMessageId (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    , visibleMessages : Evergreen.V368.VisibleMessages.VisibleMessages Evergreen.V368.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (Evergreen.V368.Thread.LastTypedAt Evergreen.V368.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V368.Drawing.Drawing (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V368.MessageArray.MessageArray Evergreen.V368.Id.ChannelMessageId (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
    , visibleMessages : Evergreen.V368.VisibleMessages.VisibleMessages Evergreen.V368.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Thread.LastTypedAt Evergreen.V368.Id.ChannelMessageId)
    , members :
        Evergreen.V368.NonemptyDict.NonemptyDict
            (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V368.Drawing.Drawing (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId))
    }


type alias BackendDmChannel =
    { messages : Evergreen.V368.IdArray.IdArray Evergreen.V368.Id.ChannelMessageId (Evergreen.V368.Message.Message Evergreen.V368.Id.ChannelMessageId (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (Evergreen.V368.Thread.LastTypedAt Evergreen.V368.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V368.Drawing.Drawing (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V368.IdArray.IdArray Evergreen.V368.Id.ChannelMessageId (Evergreen.V368.Message.Message Evergreen.V368.Id.ChannelMessageId (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (Evergreen.V368.Thread.LastTypedAt Evergreen.V368.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V368.OneToOne.OneToOne (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId)
    , members :
        Evergreen.V368.NonemptyDict.NonemptyDict
            (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V368.Drawing.Drawing (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId))
    }
