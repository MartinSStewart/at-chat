module Evergreen.V406.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V406.Discord
import Evergreen.V406.Drawing
import Evergreen.V406.Game
import Evergreen.V406.Id
import Evergreen.V406.IdArray
import Evergreen.V406.Message
import Evergreen.V406.MessageArray
import Evergreen.V406.NonemptyDict
import Evergreen.V406.OneToOne
import Evergreen.V406.SessionIdHash
import Evergreen.V406.Thread
import Evergreen.V406.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V406.Id.Id Evergreen.V406.Id.UserId, Evergreen.V406.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V406.Id.Id Evergreen.V406.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V406.Id.Id Evergreen.V406.Id.UserId, Evergreen.V406.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V406.MessageArray.MessageArray Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)
    , visibleMessages : Evergreen.V406.VisibleMessages.VisibleMessages Evergreen.V406.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
            { threadRoute : Evergreen.V406.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V406.Drawing.Drawing (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V406.MessageArray.MessageArray Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId)
    , visibleMessages : Evergreen.V406.VisibleMessages.VisibleMessages Evergreen.V406.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V406.NonemptyDict.NonemptyDict
            (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V406.Drawing.Drawing (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V406.IdArray.IdArray Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
            { threadRoute : Evergreen.V406.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V406.Drawing.Drawing (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V406.IdArray.IdArray Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Message.Message Evergreen.V406.Id.ChannelMessageId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V406.OneToOne.OneToOne (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
    , members :
        Evergreen.V406.NonemptyDict.NonemptyDict
            (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V406.Drawing.Drawing (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId))
    }
