module Evergreen.V383.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V383.Discord
import Evergreen.V383.Drawing
import Evergreen.V383.Game
import Evergreen.V383.Id
import Evergreen.V383.IdArray
import Evergreen.V383.Message
import Evergreen.V383.MessageArray
import Evergreen.V383.NonemptyDict
import Evergreen.V383.OneToOne
import Evergreen.V383.SessionIdHash
import Evergreen.V383.Thread
import Evergreen.V383.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V383.Id.Id Evergreen.V383.Id.UserId, Evergreen.V383.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V383.Id.Id Evergreen.V383.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V383.Id.Id Evergreen.V383.Id.UserId, Evergreen.V383.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V383.MessageArray.MessageArray Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    , visibleMessages : Evergreen.V383.VisibleMessages.VisibleMessages Evergreen.V383.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (Evergreen.V383.Thread.LastTypedAt Evergreen.V383.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V383.Drawing.Drawing (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V383.MessageArray.MessageArray Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
    , visibleMessages : Evergreen.V383.VisibleMessages.VisibleMessages Evergreen.V383.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Thread.LastTypedAt Evergreen.V383.Id.ChannelMessageId)
    , members :
        Evergreen.V383.NonemptyDict.NonemptyDict
            (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V383.Drawing.Drawing (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId))
    }


type alias BackendDmChannel =
    { messages : Evergreen.V383.IdArray.IdArray Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Message.Message Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (Evergreen.V383.Thread.LastTypedAt Evergreen.V383.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V383.Drawing.Drawing (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V383.IdArray.IdArray Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Message.Message Evergreen.V383.Id.ChannelMessageId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (Evergreen.V383.Thread.LastTypedAt Evergreen.V383.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V383.OneToOne.OneToOne (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId)
    , members :
        Evergreen.V383.NonemptyDict.NonemptyDict
            (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V383.Drawing.Drawing (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId))
    }
