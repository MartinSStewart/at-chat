module Evergreen.V384.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V384.Discord
import Evergreen.V384.Drawing
import Evergreen.V384.Game
import Evergreen.V384.Id
import Evergreen.V384.IdArray
import Evergreen.V384.Message
import Evergreen.V384.MessageArray
import Evergreen.V384.NonemptyDict
import Evergreen.V384.OneToOne
import Evergreen.V384.SessionIdHash
import Evergreen.V384.Thread
import Evergreen.V384.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V384.Id.Id Evergreen.V384.Id.UserId, Evergreen.V384.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V384.Id.Id Evergreen.V384.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V384.Id.Id Evergreen.V384.Id.UserId, Evergreen.V384.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V384.MessageArray.MessageArray Evergreen.V384.Id.ChannelMessageId (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    , visibleMessages : Evergreen.V384.VisibleMessages.VisibleMessages Evergreen.V384.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (Evergreen.V384.Thread.LastTypedAt Evergreen.V384.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V384.Drawing.Drawing (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V384.MessageArray.MessageArray Evergreen.V384.Id.ChannelMessageId (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
    , visibleMessages : Evergreen.V384.VisibleMessages.VisibleMessages Evergreen.V384.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Thread.LastTypedAt Evergreen.V384.Id.ChannelMessageId)
    , members :
        Evergreen.V384.NonemptyDict.NonemptyDict
            (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V384.Drawing.Drawing (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId))
    }


type alias BackendDmChannel =
    { messages : Evergreen.V384.IdArray.IdArray Evergreen.V384.Id.ChannelMessageId (Evergreen.V384.Message.Message Evergreen.V384.Id.ChannelMessageId (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (Evergreen.V384.Thread.LastTypedAt Evergreen.V384.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V384.Drawing.Drawing (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V384.IdArray.IdArray Evergreen.V384.Id.ChannelMessageId (Evergreen.V384.Message.Message Evergreen.V384.Id.ChannelMessageId (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (Evergreen.V384.Thread.LastTypedAt Evergreen.V384.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V384.OneToOne.OneToOne (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId)
    , members :
        Evergreen.V384.NonemptyDict.NonemptyDict
            (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V384.Drawing.Drawing (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId))
    }
