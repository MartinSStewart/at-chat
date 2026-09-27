module Evergreen.V388.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V388.Discord
import Evergreen.V388.Drawing
import Evergreen.V388.Game
import Evergreen.V388.Id
import Evergreen.V388.IdArray
import Evergreen.V388.Message
import Evergreen.V388.MessageArray
import Evergreen.V388.NonemptyDict
import Evergreen.V388.OneToOne
import Evergreen.V388.SessionIdHash
import Evergreen.V388.Thread
import Evergreen.V388.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V388.Id.Id Evergreen.V388.Id.UserId, Evergreen.V388.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V388.Id.Id Evergreen.V388.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V388.Id.Id Evergreen.V388.Id.UserId, Evergreen.V388.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V388.MessageArray.MessageArray Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId)
    , visibleMessages : Evergreen.V388.VisibleMessages.VisibleMessages Evergreen.V388.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Thread.LastTypedAt Evergreen.V388.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V388.Drawing.Drawing (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V388.MessageArray.MessageArray Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId)
    , visibleMessages : Evergreen.V388.VisibleMessages.VisibleMessages Evergreen.V388.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Thread.LastTypedAt Evergreen.V388.Id.ChannelMessageId)
    , members :
        Evergreen.V388.NonemptyDict.NonemptyDict
            (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V388.Drawing.Drawing (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.Message.Message Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V388.IdArray.IdArray Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Message.Message Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Thread.LastTypedAt Evergreen.V388.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V388.Drawing.Drawing (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V388.IdArray.IdArray Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Message.Message Evergreen.V388.Id.ChannelMessageId (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Thread.LastTypedAt Evergreen.V388.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V388.OneToOne.OneToOne (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId)
    , members :
        Evergreen.V388.NonemptyDict.NonemptyDict
            (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V388.Drawing.Drawing (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId))
    }
