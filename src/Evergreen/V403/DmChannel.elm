module Evergreen.V403.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V403.Discord
import Evergreen.V403.Drawing
import Evergreen.V403.Game
import Evergreen.V403.Id
import Evergreen.V403.IdArray
import Evergreen.V403.Message
import Evergreen.V403.MessageArray
import Evergreen.V403.NonemptyDict
import Evergreen.V403.OneToOne
import Evergreen.V403.SessionIdHash
import Evergreen.V403.Thread
import Evergreen.V403.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V403.Id.Id Evergreen.V403.Id.UserId, Evergreen.V403.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V403.Id.Id Evergreen.V403.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V403.Id.Id Evergreen.V403.Id.UserId, Evergreen.V403.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V403.MessageArray.MessageArray Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)
    , visibleMessages : Evergreen.V403.VisibleMessages.VisibleMessages Evergreen.V403.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
            { threadRoute : Evergreen.V403.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V403.Drawing.Drawing (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V403.MessageArray.MessageArray Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId)
    , visibleMessages : Evergreen.V403.VisibleMessages.VisibleMessages Evergreen.V403.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V403.NonemptyDict.NonemptyDict
            (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V403.Drawing.Drawing (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Evergreen.V403.Message.Message Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V403.IdArray.IdArray Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Message.Message Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
            { threadRoute : Evergreen.V403.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) Evergreen.V403.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V403.Drawing.Drawing (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V403.IdArray.IdArray Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Message.Message Evergreen.V403.Id.ChannelMessageId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V403.OneToOne.OneToOne (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId)
    , members :
        Evergreen.V403.NonemptyDict.NonemptyDict
            (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V403.Drawing.Drawing (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId))
    }
