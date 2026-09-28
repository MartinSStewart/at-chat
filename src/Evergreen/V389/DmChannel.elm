module Evergreen.V389.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V389.Discord
import Evergreen.V389.Drawing
import Evergreen.V389.Game
import Evergreen.V389.Id
import Evergreen.V389.IdArray
import Evergreen.V389.Message
import Evergreen.V389.MessageArray
import Evergreen.V389.NonemptyDict
import Evergreen.V389.OneToOne
import Evergreen.V389.SessionIdHash
import Evergreen.V389.Thread
import Evergreen.V389.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V389.Id.Id Evergreen.V389.Id.UserId, Evergreen.V389.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V389.Id.Id Evergreen.V389.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V389.Id.Id Evergreen.V389.Id.UserId, Evergreen.V389.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V389.MessageArray.MessageArray Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId)
    , visibleMessages : Evergreen.V389.VisibleMessages.VisibleMessages Evergreen.V389.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Thread.LastTypedAt Evergreen.V389.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V389.Drawing.Drawing (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V389.MessageArray.MessageArray Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId)
    , visibleMessages : Evergreen.V389.VisibleMessages.VisibleMessages Evergreen.V389.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Thread.LastTypedAt Evergreen.V389.Id.ChannelMessageId)
    , members :
        Evergreen.V389.NonemptyDict.NonemptyDict
            (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V389.Drawing.Drawing (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.Message.Message Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V389.IdArray.IdArray Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Message.Message Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Thread.LastTypedAt Evergreen.V389.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V389.Drawing.Drawing (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V389.IdArray.IdArray Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Message.Message Evergreen.V389.Id.ChannelMessageId (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Thread.LastTypedAt Evergreen.V389.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V389.OneToOne.OneToOne (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId)
    , members :
        Evergreen.V389.NonemptyDict.NonemptyDict
            (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V389.Drawing.Drawing (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId))
    }
