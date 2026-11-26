module Evergreen.V425.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V425.Discord
import Evergreen.V425.Drawing
import Evergreen.V425.Game
import Evergreen.V425.Id
import Evergreen.V425.IdArray
import Evergreen.V425.Message
import Evergreen.V425.MessageArray
import Evergreen.V425.NonemptyDict
import Evergreen.V425.OneToOne
import Evergreen.V425.SessionIdHash
import Evergreen.V425.Thread
import Evergreen.V425.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V425.Id.Id Evergreen.V425.Id.UserId, Evergreen.V425.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V425.Id.Id Evergreen.V425.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V425.Id.Id Evergreen.V425.Id.UserId, Evergreen.V425.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V425.MessageArray.MessageArray Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId)
    , visibleMessages : Evergreen.V425.VisibleMessages.VisibleMessages Evergreen.V425.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
            { threadRoute : Evergreen.V425.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V425.Drawing.Drawing (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V425.MessageArray.MessageArray Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId)
    , visibleMessages : Evergreen.V425.VisibleMessages.VisibleMessages Evergreen.V425.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V425.NonemptyDict.NonemptyDict
            (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V425.Drawing.Drawing (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V425.IdArray.IdArray Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
            { threadRoute : Evergreen.V425.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) Evergreen.V425.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V425.Drawing.Drawing (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V425.IdArray.IdArray Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Message.Message Evergreen.V425.Id.ChannelMessageId (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V425.OneToOne.OneToOne (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId)
    , members :
        Evergreen.V425.NonemptyDict.NonemptyDict
            (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V425.Drawing.Drawing (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId))
    }
