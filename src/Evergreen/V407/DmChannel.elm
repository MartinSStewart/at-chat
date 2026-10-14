module Evergreen.V407.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V407.Discord
import Evergreen.V407.Drawing
import Evergreen.V407.Game
import Evergreen.V407.Id
import Evergreen.V407.IdArray
import Evergreen.V407.Message
import Evergreen.V407.MessageArray
import Evergreen.V407.NonemptyDict
import Evergreen.V407.OneToOne
import Evergreen.V407.SessionIdHash
import Evergreen.V407.Thread
import Evergreen.V407.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V407.Id.Id Evergreen.V407.Id.UserId, Evergreen.V407.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V407.Id.Id Evergreen.V407.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V407.Id.Id Evergreen.V407.Id.UserId, Evergreen.V407.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V407.MessageArray.MessageArray Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)
    , visibleMessages : Evergreen.V407.VisibleMessages.VisibleMessages Evergreen.V407.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
            { threadRoute : Evergreen.V407.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V407.Drawing.Drawing (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V407.MessageArray.MessageArray Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId)
    , visibleMessages : Evergreen.V407.VisibleMessages.VisibleMessages Evergreen.V407.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V407.NonemptyDict.NonemptyDict
            (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V407.Drawing.Drawing (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V407.IdArray.IdArray Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
            { threadRoute : Evergreen.V407.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) Evergreen.V407.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V407.Drawing.Drawing (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V407.IdArray.IdArray Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Message.Message Evergreen.V407.Id.ChannelMessageId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V407.OneToOne.OneToOne (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId)
    , members :
        Evergreen.V407.NonemptyDict.NonemptyDict
            (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V407.Drawing.Drawing (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId))
    }
