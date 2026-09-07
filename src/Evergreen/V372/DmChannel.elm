module Evergreen.V372.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V372.Discord
import Evergreen.V372.Drawing
import Evergreen.V372.Game
import Evergreen.V372.Id
import Evergreen.V372.IdArray
import Evergreen.V372.Message
import Evergreen.V372.MessageArray
import Evergreen.V372.NonemptyDict
import Evergreen.V372.OneToOne
import Evergreen.V372.SessionIdHash
import Evergreen.V372.Thread
import Evergreen.V372.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V372.Id.Id Evergreen.V372.Id.UserId, Evergreen.V372.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V372.Id.Id Evergreen.V372.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V372.Id.Id Evergreen.V372.Id.UserId, Evergreen.V372.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V372.MessageArray.MessageArray Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    , visibleMessages : Evergreen.V372.VisibleMessages.VisibleMessages Evergreen.V372.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (Evergreen.V372.Thread.LastTypedAt Evergreen.V372.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V372.Drawing.Drawing (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V372.MessageArray.MessageArray Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
    , visibleMessages : Evergreen.V372.VisibleMessages.VisibleMessages Evergreen.V372.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Thread.LastTypedAt Evergreen.V372.Id.ChannelMessageId)
    , members :
        Evergreen.V372.NonemptyDict.NonemptyDict
            (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V372.Drawing.Drawing (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId))
    }


type alias BackendDmChannel =
    { messages : Evergreen.V372.IdArray.IdArray Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Message.Message Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (Evergreen.V372.Thread.LastTypedAt Evergreen.V372.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) Evergreen.V372.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V372.Drawing.Drawing (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V372.IdArray.IdArray Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Message.Message Evergreen.V372.Id.ChannelMessageId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (Evergreen.V372.Thread.LastTypedAt Evergreen.V372.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V372.OneToOne.OneToOne (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId)
    , members :
        Evergreen.V372.NonemptyDict.NonemptyDict
            (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V372.Drawing.Drawing (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId))
    }
