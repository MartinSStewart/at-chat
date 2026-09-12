module Evergreen.V379.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V379.Discord
import Evergreen.V379.Drawing
import Evergreen.V379.Game
import Evergreen.V379.Id
import Evergreen.V379.IdArray
import Evergreen.V379.Message
import Evergreen.V379.MessageArray
import Evergreen.V379.NonemptyDict
import Evergreen.V379.OneToOne
import Evergreen.V379.SessionIdHash
import Evergreen.V379.Thread
import Evergreen.V379.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V379.Id.Id Evergreen.V379.Id.UserId, Evergreen.V379.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V379.Id.Id Evergreen.V379.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V379.Id.Id Evergreen.V379.Id.UserId, Evergreen.V379.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V379.MessageArray.MessageArray Evergreen.V379.Id.ChannelMessageId (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    , visibleMessages : Evergreen.V379.VisibleMessages.VisibleMessages Evergreen.V379.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (Evergreen.V379.Thread.LastTypedAt Evergreen.V379.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V379.Drawing.Drawing (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V379.MessageArray.MessageArray Evergreen.V379.Id.ChannelMessageId (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
    , visibleMessages : Evergreen.V379.VisibleMessages.VisibleMessages Evergreen.V379.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Thread.LastTypedAt Evergreen.V379.Id.ChannelMessageId)
    , members :
        Evergreen.V379.NonemptyDict.NonemptyDict
            (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V379.Drawing.Drawing (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId))
    }


type alias BackendDmChannel =
    { messages : Evergreen.V379.IdArray.IdArray Evergreen.V379.Id.ChannelMessageId (Evergreen.V379.Message.Message Evergreen.V379.Id.ChannelMessageId (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (Evergreen.V379.Thread.LastTypedAt Evergreen.V379.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V379.Drawing.Drawing (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V379.IdArray.IdArray Evergreen.V379.Id.ChannelMessageId (Evergreen.V379.Message.Message Evergreen.V379.Id.ChannelMessageId (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (Evergreen.V379.Thread.LastTypedAt Evergreen.V379.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V379.OneToOne.OneToOne (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId)
    , members :
        Evergreen.V379.NonemptyDict.NonemptyDict
            (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V379.Drawing.Drawing (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId))
    }
