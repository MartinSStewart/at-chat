module Evergreen.V396.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V396.Discord
import Evergreen.V396.Drawing
import Evergreen.V396.Game
import Evergreen.V396.Id
import Evergreen.V396.IdArray
import Evergreen.V396.Message
import Evergreen.V396.MessageArray
import Evergreen.V396.NonemptyDict
import Evergreen.V396.OneToOne
import Evergreen.V396.SessionIdHash
import Evergreen.V396.Thread
import Evergreen.V396.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V396.Id.Id Evergreen.V396.Id.UserId, Evergreen.V396.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V396.Id.Id Evergreen.V396.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V396.Id.Id Evergreen.V396.Id.UserId, Evergreen.V396.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V396.MessageArray.MessageArray Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId)
    , visibleMessages : Evergreen.V396.VisibleMessages.VisibleMessages Evergreen.V396.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Thread.LastTypedAt Evergreen.V396.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V396.Drawing.Drawing (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V396.MessageArray.MessageArray Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId)
    , visibleMessages : Evergreen.V396.VisibleMessages.VisibleMessages Evergreen.V396.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Thread.LastTypedAt Evergreen.V396.Id.ChannelMessageId)
    , members :
        Evergreen.V396.NonemptyDict.NonemptyDict
            (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V396.Drawing.Drawing (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.Message.Message Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V396.IdArray.IdArray Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Message.Message Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Thread.LastTypedAt Evergreen.V396.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V396.Drawing.Drawing (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V396.IdArray.IdArray Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Message.Message Evergreen.V396.Id.ChannelMessageId (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Thread.LastTypedAt Evergreen.V396.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V396.OneToOne.OneToOne (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId)
    , members :
        Evergreen.V396.NonemptyDict.NonemptyDict
            (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V396.Drawing.Drawing (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId))
    }
