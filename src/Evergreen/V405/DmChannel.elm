module Evergreen.V405.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V405.Discord
import Evergreen.V405.Drawing
import Evergreen.V405.Game
import Evergreen.V405.Id
import Evergreen.V405.IdArray
import Evergreen.V405.Message
import Evergreen.V405.MessageArray
import Evergreen.V405.NonemptyDict
import Evergreen.V405.OneToOne
import Evergreen.V405.SessionIdHash
import Evergreen.V405.Thread
import Evergreen.V405.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V405.Id.Id Evergreen.V405.Id.UserId, Evergreen.V405.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V405.Id.Id Evergreen.V405.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V405.Id.Id Evergreen.V405.Id.UserId, Evergreen.V405.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V405.MessageArray.MessageArray Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId)
    , visibleMessages : Evergreen.V405.VisibleMessages.VisibleMessages Evergreen.V405.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
            { threadRoute : Evergreen.V405.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V405.Drawing.Drawing (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V405.MessageArray.MessageArray Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId)
    , visibleMessages : Evergreen.V405.VisibleMessages.VisibleMessages Evergreen.V405.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V405.NonemptyDict.NonemptyDict
            (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V405.Drawing.Drawing (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Evergreen.V405.Message.Message Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V405.IdArray.IdArray Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Message.Message Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
            { threadRoute : Evergreen.V405.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) Evergreen.V405.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V405.Drawing.Drawing (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V405.IdArray.IdArray Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Message.Message Evergreen.V405.Id.ChannelMessageId (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V405.OneToOne.OneToOne (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
    , members :
        Evergreen.V405.NonemptyDict.NonemptyDict
            (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V405.Drawing.Drawing (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId))
    }
