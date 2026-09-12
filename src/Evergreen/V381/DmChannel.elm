module Evergreen.V381.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V381.Discord
import Evergreen.V381.Drawing
import Evergreen.V381.Game
import Evergreen.V381.Id
import Evergreen.V381.IdArray
import Evergreen.V381.Message
import Evergreen.V381.MessageArray
import Evergreen.V381.NonemptyDict
import Evergreen.V381.OneToOne
import Evergreen.V381.SessionIdHash
import Evergreen.V381.Thread
import Evergreen.V381.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V381.Id.Id Evergreen.V381.Id.UserId, Evergreen.V381.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V381.Id.Id Evergreen.V381.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V381.Id.Id Evergreen.V381.Id.UserId, Evergreen.V381.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V381.MessageArray.MessageArray Evergreen.V381.Id.ChannelMessageId (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    , visibleMessages : Evergreen.V381.VisibleMessages.VisibleMessages Evergreen.V381.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (Evergreen.V381.Thread.LastTypedAt Evergreen.V381.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V381.Drawing.Drawing (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V381.MessageArray.MessageArray Evergreen.V381.Id.ChannelMessageId (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
    , visibleMessages : Evergreen.V381.VisibleMessages.VisibleMessages Evergreen.V381.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Thread.LastTypedAt Evergreen.V381.Id.ChannelMessageId)
    , members :
        Evergreen.V381.NonemptyDict.NonemptyDict
            (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V381.Drawing.Drawing (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId))
    }


type alias BackendDmChannel =
    { messages : Evergreen.V381.IdArray.IdArray Evergreen.V381.Id.ChannelMessageId (Evergreen.V381.Message.Message Evergreen.V381.Id.ChannelMessageId (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (Evergreen.V381.Thread.LastTypedAt Evergreen.V381.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V381.Drawing.Drawing (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V381.IdArray.IdArray Evergreen.V381.Id.ChannelMessageId (Evergreen.V381.Message.Message Evergreen.V381.Id.ChannelMessageId (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (Evergreen.V381.Thread.LastTypedAt Evergreen.V381.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V381.OneToOne.OneToOne (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId)
    , members :
        Evergreen.V381.NonemptyDict.NonemptyDict
            (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V381.Drawing.Drawing (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId))
    }
