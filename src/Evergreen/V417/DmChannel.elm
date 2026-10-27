module Evergreen.V417.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V417.Discord
import Evergreen.V417.Drawing
import Evergreen.V417.Game
import Evergreen.V417.Id
import Evergreen.V417.IdArray
import Evergreen.V417.Message
import Evergreen.V417.MessageArray
import Evergreen.V417.NonemptyDict
import Evergreen.V417.OneToOne
import Evergreen.V417.SessionIdHash
import Evergreen.V417.Thread
import Evergreen.V417.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V417.Id.Id Evergreen.V417.Id.UserId, Evergreen.V417.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V417.Id.Id Evergreen.V417.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V417.Id.Id Evergreen.V417.Id.UserId, Evergreen.V417.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V417.MessageArray.MessageArray Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)
    , visibleMessages : Evergreen.V417.VisibleMessages.VisibleMessages Evergreen.V417.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
            { threadRoute : Evergreen.V417.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V417.Drawing.Drawing (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V417.MessageArray.MessageArray Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId)
    , visibleMessages : Evergreen.V417.VisibleMessages.VisibleMessages Evergreen.V417.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V417.NonemptyDict.NonemptyDict
            (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V417.Drawing.Drawing (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V417.IdArray.IdArray Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
            { threadRoute : Evergreen.V417.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) Evergreen.V417.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V417.Drawing.Drawing (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V417.IdArray.IdArray Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Message.Message Evergreen.V417.Id.ChannelMessageId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V417.OneToOne.OneToOne (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId)
    , members :
        Evergreen.V417.NonemptyDict.NonemptyDict
            (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V417.Drawing.Drawing (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId))
    }
