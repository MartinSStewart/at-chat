module Evergreen.V377.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V377.Discord
import Evergreen.V377.Drawing
import Evergreen.V377.Game
import Evergreen.V377.Id
import Evergreen.V377.IdArray
import Evergreen.V377.Message
import Evergreen.V377.MessageArray
import Evergreen.V377.NonemptyDict
import Evergreen.V377.OneToOne
import Evergreen.V377.SessionIdHash
import Evergreen.V377.Thread
import Evergreen.V377.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V377.Id.Id Evergreen.V377.Id.UserId, Evergreen.V377.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V377.Id.Id Evergreen.V377.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V377.Id.Id Evergreen.V377.Id.UserId, Evergreen.V377.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V377.MessageArray.MessageArray Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    , visibleMessages : Evergreen.V377.VisibleMessages.VisibleMessages Evergreen.V377.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (Evergreen.V377.Thread.LastTypedAt Evergreen.V377.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V377.Drawing.Drawing (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V377.MessageArray.MessageArray Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
    , visibleMessages : Evergreen.V377.VisibleMessages.VisibleMessages Evergreen.V377.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Thread.LastTypedAt Evergreen.V377.Id.ChannelMessageId)
    , members :
        Evergreen.V377.NonemptyDict.NonemptyDict
            (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V377.Drawing.Drawing (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId))
    }


type alias BackendDmChannel =
    { messages : Evergreen.V377.IdArray.IdArray Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Message.Message Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (Evergreen.V377.Thread.LastTypedAt Evergreen.V377.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V377.Drawing.Drawing (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V377.IdArray.IdArray Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Message.Message Evergreen.V377.Id.ChannelMessageId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (Evergreen.V377.Thread.LastTypedAt Evergreen.V377.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V377.OneToOne.OneToOne (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId)
    , members :
        Evergreen.V377.NonemptyDict.NonemptyDict
            (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V377.Drawing.Drawing (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId))
    }
