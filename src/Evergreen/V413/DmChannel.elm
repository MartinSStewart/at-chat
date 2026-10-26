module Evergreen.V413.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V413.Discord
import Evergreen.V413.Drawing
import Evergreen.V413.Game
import Evergreen.V413.Id
import Evergreen.V413.IdArray
import Evergreen.V413.Message
import Evergreen.V413.MessageArray
import Evergreen.V413.NonemptyDict
import Evergreen.V413.OneToOne
import Evergreen.V413.SessionIdHash
import Evergreen.V413.Thread
import Evergreen.V413.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V413.Id.Id Evergreen.V413.Id.UserId, Evergreen.V413.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V413.Id.Id Evergreen.V413.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V413.Id.Id Evergreen.V413.Id.UserId, Evergreen.V413.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V413.MessageArray.MessageArray Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId)
    , visibleMessages : Evergreen.V413.VisibleMessages.VisibleMessages Evergreen.V413.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
            { threadRoute : Evergreen.V413.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V413.Drawing.Drawing (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V413.MessageArray.MessageArray Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId)
    , visibleMessages : Evergreen.V413.VisibleMessages.VisibleMessages Evergreen.V413.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V413.NonemptyDict.NonemptyDict
            (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V413.Drawing.Drawing (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V413.IdArray.IdArray Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
            { threadRoute : Evergreen.V413.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V413.Drawing.Drawing (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V413.IdArray.IdArray Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Message.Message Evergreen.V413.Id.ChannelMessageId (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V413.OneToOne.OneToOne (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId)
    , members :
        Evergreen.V413.NonemptyDict.NonemptyDict
            (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V413.Drawing.Drawing (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId))
    }
