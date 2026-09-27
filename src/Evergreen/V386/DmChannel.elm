module Evergreen.V386.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V386.Discord
import Evergreen.V386.Drawing
import Evergreen.V386.Game
import Evergreen.V386.Id
import Evergreen.V386.IdArray
import Evergreen.V386.Message
import Evergreen.V386.MessageArray
import Evergreen.V386.NonemptyDict
import Evergreen.V386.OneToOne
import Evergreen.V386.SessionIdHash
import Evergreen.V386.Thread
import Evergreen.V386.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V386.Id.Id Evergreen.V386.Id.UserId, Evergreen.V386.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V386.Id.Id Evergreen.V386.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V386.Id.Id Evergreen.V386.Id.UserId, Evergreen.V386.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V386.MessageArray.MessageArray Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId)
    , visibleMessages : Evergreen.V386.VisibleMessages.VisibleMessages Evergreen.V386.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Thread.LastTypedAt Evergreen.V386.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V386.Drawing.Drawing (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V386.MessageArray.MessageArray Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId)
    , visibleMessages : Evergreen.V386.VisibleMessages.VisibleMessages Evergreen.V386.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Thread.LastTypedAt Evergreen.V386.Id.ChannelMessageId)
    , members :
        Evergreen.V386.NonemptyDict.NonemptyDict
            (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V386.Drawing.Drawing (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.Message.Message Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V386.IdArray.IdArray Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Message.Message Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Thread.LastTypedAt Evergreen.V386.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V386.Drawing.Drawing (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V386.IdArray.IdArray Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Message.Message Evergreen.V386.Id.ChannelMessageId (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Thread.LastTypedAt Evergreen.V386.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V386.OneToOne.OneToOne (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId)
    , members :
        Evergreen.V386.NonemptyDict.NonemptyDict
            (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V386.Drawing.Drawing (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId))
    }
