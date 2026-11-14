module Evergreen.V422.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V422.Discord
import Evergreen.V422.Drawing
import Evergreen.V422.Game
import Evergreen.V422.Id
import Evergreen.V422.IdArray
import Evergreen.V422.Message
import Evergreen.V422.MessageArray
import Evergreen.V422.NonemptyDict
import Evergreen.V422.OneToOne
import Evergreen.V422.SessionIdHash
import Evergreen.V422.Thread
import Evergreen.V422.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V422.Id.Id Evergreen.V422.Id.UserId, Evergreen.V422.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V422.Id.Id Evergreen.V422.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V422.Id.Id Evergreen.V422.Id.UserId, Evergreen.V422.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V422.MessageArray.MessageArray Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId)
    , visibleMessages : Evergreen.V422.VisibleMessages.VisibleMessages Evergreen.V422.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
            { threadRoute : Evergreen.V422.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V422.Drawing.Drawing (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V422.MessageArray.MessageArray Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId)
    , visibleMessages : Evergreen.V422.VisibleMessages.VisibleMessages Evergreen.V422.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V422.NonemptyDict.NonemptyDict
            (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V422.Drawing.Drawing (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V422.IdArray.IdArray Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
            { threadRoute : Evergreen.V422.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) Evergreen.V422.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V422.Drawing.Drawing (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V422.IdArray.IdArray Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Message.Message Evergreen.V422.Id.ChannelMessageId (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V422.OneToOne.OneToOne (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId)
    , members :
        Evergreen.V422.NonemptyDict.NonemptyDict
            (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V422.Drawing.Drawing (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId))
    }
