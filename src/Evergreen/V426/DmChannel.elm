module Evergreen.V426.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V426.Discord
import Evergreen.V426.Drawing
import Evergreen.V426.Game
import Evergreen.V426.Id
import Evergreen.V426.IdArray
import Evergreen.V426.Message
import Evergreen.V426.MessageArray
import Evergreen.V426.NonemptyDict
import Evergreen.V426.OneToOne
import Evergreen.V426.SessionIdHash
import Evergreen.V426.Thread
import Evergreen.V426.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V426.Id.Id Evergreen.V426.Id.UserId, Evergreen.V426.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V426.Id.Id Evergreen.V426.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V426.Id.Id Evergreen.V426.Id.UserId, Evergreen.V426.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V426.MessageArray.MessageArray Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)
    , visibleMessages : Evergreen.V426.VisibleMessages.VisibleMessages Evergreen.V426.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
            { threadRoute : Evergreen.V426.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V426.Drawing.Drawing (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V426.MessageArray.MessageArray Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId)
    , visibleMessages : Evergreen.V426.VisibleMessages.VisibleMessages Evergreen.V426.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V426.NonemptyDict.NonemptyDict
            (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V426.Drawing.Drawing (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V426.IdArray.IdArray Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
            { threadRoute : Evergreen.V426.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) Evergreen.V426.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V426.Drawing.Drawing (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V426.IdArray.IdArray Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Message.Message Evergreen.V426.Id.ChannelMessageId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V426.OneToOne.OneToOne (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId)
    , members :
        Evergreen.V426.NonemptyDict.NonemptyDict
            (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V426.Drawing.Drawing (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId))
    }
