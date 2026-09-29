module Evergreen.V394.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V394.Discord
import Evergreen.V394.Drawing
import Evergreen.V394.Game
import Evergreen.V394.Id
import Evergreen.V394.IdArray
import Evergreen.V394.Message
import Evergreen.V394.MessageArray
import Evergreen.V394.NonemptyDict
import Evergreen.V394.OneToOne
import Evergreen.V394.SessionIdHash
import Evergreen.V394.Thread
import Evergreen.V394.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V394.Id.Id Evergreen.V394.Id.UserId, Evergreen.V394.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V394.Id.Id Evergreen.V394.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V394.Id.Id Evergreen.V394.Id.UserId, Evergreen.V394.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V394.MessageArray.MessageArray Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId)
    , visibleMessages : Evergreen.V394.VisibleMessages.VisibleMessages Evergreen.V394.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Thread.LastTypedAt Evergreen.V394.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V394.Drawing.Drawing (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V394.MessageArray.MessageArray Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId)
    , visibleMessages : Evergreen.V394.VisibleMessages.VisibleMessages Evergreen.V394.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Thread.LastTypedAt Evergreen.V394.Id.ChannelMessageId)
    , members :
        Evergreen.V394.NonemptyDict.NonemptyDict
            (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V394.Drawing.Drawing (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Evergreen.V394.Message.Message Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V394.IdArray.IdArray Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Message.Message Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Thread.LastTypedAt Evergreen.V394.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) Evergreen.V394.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V394.Drawing.Drawing (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V394.IdArray.IdArray Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Message.Message Evergreen.V394.Id.ChannelMessageId (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Thread.LastTypedAt Evergreen.V394.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V394.OneToOne.OneToOne (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId)
    , members :
        Evergreen.V394.NonemptyDict.NonemptyDict
            (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V394.Drawing.Drawing (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId))
    }
