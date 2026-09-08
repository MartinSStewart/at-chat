module Evergreen.V373.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V373.Discord
import Evergreen.V373.Drawing
import Evergreen.V373.Game
import Evergreen.V373.Id
import Evergreen.V373.IdArray
import Evergreen.V373.Message
import Evergreen.V373.MessageArray
import Evergreen.V373.NonemptyDict
import Evergreen.V373.OneToOne
import Evergreen.V373.SessionIdHash
import Evergreen.V373.Thread
import Evergreen.V373.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V373.Id.Id Evergreen.V373.Id.UserId, Evergreen.V373.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V373.Id.Id Evergreen.V373.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V373.Id.Id Evergreen.V373.Id.UserId, Evergreen.V373.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V373.MessageArray.MessageArray Evergreen.V373.Id.ChannelMessageId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    , visibleMessages : Evergreen.V373.VisibleMessages.VisibleMessages Evergreen.V373.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (Evergreen.V373.Thread.LastTypedAt Evergreen.V373.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V373.Drawing.Drawing (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V373.MessageArray.MessageArray Evergreen.V373.Id.ChannelMessageId (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
    , visibleMessages : Evergreen.V373.VisibleMessages.VisibleMessages Evergreen.V373.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Thread.LastTypedAt Evergreen.V373.Id.ChannelMessageId)
    , members :
        Evergreen.V373.NonemptyDict.NonemptyDict
            (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V373.Drawing.Drawing (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId))
    }


type alias BackendDmChannel =
    { messages : Evergreen.V373.IdArray.IdArray Evergreen.V373.Id.ChannelMessageId (Evergreen.V373.Message.Message Evergreen.V373.Id.ChannelMessageId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (Evergreen.V373.Thread.LastTypedAt Evergreen.V373.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) Evergreen.V373.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V373.Drawing.Drawing (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V373.IdArray.IdArray Evergreen.V373.Id.ChannelMessageId (Evergreen.V373.Message.Message Evergreen.V373.Id.ChannelMessageId (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (Evergreen.V373.Thread.LastTypedAt Evergreen.V373.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V373.OneToOne.OneToOne (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId)
    , members :
        Evergreen.V373.NonemptyDict.NonemptyDict
            (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V373.Drawing.Drawing (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId))
    }
