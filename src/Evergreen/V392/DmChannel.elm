module Evergreen.V392.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V392.Discord
import Evergreen.V392.Drawing
import Evergreen.V392.Game
import Evergreen.V392.Id
import Evergreen.V392.IdArray
import Evergreen.V392.Message
import Evergreen.V392.MessageArray
import Evergreen.V392.NonemptyDict
import Evergreen.V392.OneToOne
import Evergreen.V392.SessionIdHash
import Evergreen.V392.Thread
import Evergreen.V392.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V392.Id.Id Evergreen.V392.Id.UserId, Evergreen.V392.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V392.Id.Id Evergreen.V392.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V392.Id.Id Evergreen.V392.Id.UserId, Evergreen.V392.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V392.MessageArray.MessageArray Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId)
    , visibleMessages : Evergreen.V392.VisibleMessages.VisibleMessages Evergreen.V392.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Thread.LastTypedAt Evergreen.V392.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V392.Drawing.Drawing (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V392.MessageArray.MessageArray Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId)
    , visibleMessages : Evergreen.V392.VisibleMessages.VisibleMessages Evergreen.V392.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Thread.LastTypedAt Evergreen.V392.Id.ChannelMessageId)
    , members :
        Evergreen.V392.NonemptyDict.NonemptyDict
            (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V392.Drawing.Drawing (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Evergreen.V392.Message.Message Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V392.IdArray.IdArray Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Message.Message Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Thread.LastTypedAt Evergreen.V392.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) Evergreen.V392.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V392.Drawing.Drawing (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V392.IdArray.IdArray Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Message.Message Evergreen.V392.Id.ChannelMessageId (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Thread.LastTypedAt Evergreen.V392.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V392.OneToOne.OneToOne (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId)
    , members :
        Evergreen.V392.NonemptyDict.NonemptyDict
            (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V392.Drawing.Drawing (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId))
    }
