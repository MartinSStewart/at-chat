module Evergreen.V387.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V387.Discord
import Evergreen.V387.Drawing
import Evergreen.V387.Game
import Evergreen.V387.Id
import Evergreen.V387.IdArray
import Evergreen.V387.Message
import Evergreen.V387.MessageArray
import Evergreen.V387.NonemptyDict
import Evergreen.V387.OneToOne
import Evergreen.V387.SessionIdHash
import Evergreen.V387.Thread
import Evergreen.V387.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V387.Id.Id Evergreen.V387.Id.UserId, Evergreen.V387.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V387.Id.Id Evergreen.V387.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V387.Id.Id Evergreen.V387.Id.UserId, Evergreen.V387.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V387.MessageArray.MessageArray Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId)
    , visibleMessages : Evergreen.V387.VisibleMessages.VisibleMessages Evergreen.V387.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Thread.LastTypedAt Evergreen.V387.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V387.Drawing.Drawing (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V387.MessageArray.MessageArray Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId)
    , visibleMessages : Evergreen.V387.VisibleMessages.VisibleMessages Evergreen.V387.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Thread.LastTypedAt Evergreen.V387.Id.ChannelMessageId)
    , members :
        Evergreen.V387.NonemptyDict.NonemptyDict
            (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V387.Drawing.Drawing (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.Message.Message Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V387.IdArray.IdArray Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Message.Message Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Thread.LastTypedAt Evergreen.V387.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V387.Drawing.Drawing (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V387.IdArray.IdArray Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Message.Message Evergreen.V387.Id.ChannelMessageId (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Thread.LastTypedAt Evergreen.V387.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V387.OneToOne.OneToOne (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId)
    , members :
        Evergreen.V387.NonemptyDict.NonemptyDict
            (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V387.Drawing.Drawing (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId))
    }
