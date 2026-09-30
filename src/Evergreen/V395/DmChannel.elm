module Evergreen.V395.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V395.Discord
import Evergreen.V395.Drawing
import Evergreen.V395.Game
import Evergreen.V395.Id
import Evergreen.V395.IdArray
import Evergreen.V395.Message
import Evergreen.V395.MessageArray
import Evergreen.V395.NonemptyDict
import Evergreen.V395.OneToOne
import Evergreen.V395.SessionIdHash
import Evergreen.V395.Thread
import Evergreen.V395.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V395.Id.Id Evergreen.V395.Id.UserId, Evergreen.V395.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V395.Id.Id Evergreen.V395.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V395.Id.Id Evergreen.V395.Id.UserId, Evergreen.V395.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V395.MessageArray.MessageArray Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)
    , visibleMessages : Evergreen.V395.VisibleMessages.VisibleMessages Evergreen.V395.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Thread.LastTypedAt Evergreen.V395.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V395.Drawing.Drawing (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V395.MessageArray.MessageArray Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId)
    , visibleMessages : Evergreen.V395.VisibleMessages.VisibleMessages Evergreen.V395.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Thread.LastTypedAt Evergreen.V395.Id.ChannelMessageId)
    , members :
        Evergreen.V395.NonemptyDict.NonemptyDict
            (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V395.Drawing.Drawing (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.Message.Message Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V395.IdArray.IdArray Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Message.Message Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Thread.LastTypedAt Evergreen.V395.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V395.Drawing.Drawing (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V395.IdArray.IdArray Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Message.Message Evergreen.V395.Id.ChannelMessageId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Thread.LastTypedAt Evergreen.V395.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V395.OneToOne.OneToOne (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId)
    , members :
        Evergreen.V395.NonemptyDict.NonemptyDict
            (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V395.Drawing.Drawing (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId))
    }
