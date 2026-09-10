module Evergreen.V376.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V376.Discord
import Evergreen.V376.Drawing
import Evergreen.V376.Game
import Evergreen.V376.Id
import Evergreen.V376.IdArray
import Evergreen.V376.Message
import Evergreen.V376.MessageArray
import Evergreen.V376.NonemptyDict
import Evergreen.V376.OneToOne
import Evergreen.V376.SessionIdHash
import Evergreen.V376.Thread
import Evergreen.V376.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V376.Id.Id Evergreen.V376.Id.UserId, Evergreen.V376.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V376.Id.Id Evergreen.V376.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V376.Id.Id Evergreen.V376.Id.UserId, Evergreen.V376.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V376.MessageArray.MessageArray Evergreen.V376.Id.ChannelMessageId (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    , visibleMessages : Evergreen.V376.VisibleMessages.VisibleMessages Evergreen.V376.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (Evergreen.V376.Thread.LastTypedAt Evergreen.V376.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V376.Drawing.Drawing (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V376.MessageArray.MessageArray Evergreen.V376.Id.ChannelMessageId (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
    , visibleMessages : Evergreen.V376.VisibleMessages.VisibleMessages Evergreen.V376.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Thread.LastTypedAt Evergreen.V376.Id.ChannelMessageId)
    , members :
        Evergreen.V376.NonemptyDict.NonemptyDict
            (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V376.Drawing.Drawing (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId))
    }


type alias BackendDmChannel =
    { messages : Evergreen.V376.IdArray.IdArray Evergreen.V376.Id.ChannelMessageId (Evergreen.V376.Message.Message Evergreen.V376.Id.ChannelMessageId (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (Evergreen.V376.Thread.LastTypedAt Evergreen.V376.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V376.Drawing.Drawing (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V376.IdArray.IdArray Evergreen.V376.Id.ChannelMessageId (Evergreen.V376.Message.Message Evergreen.V376.Id.ChannelMessageId (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (Evergreen.V376.Thread.LastTypedAt Evergreen.V376.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V376.OneToOne.OneToOne (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId)
    , members :
        Evergreen.V376.NonemptyDict.NonemptyDict
            (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V376.Drawing.Drawing (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId))
    }
