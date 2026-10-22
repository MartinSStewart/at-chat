module Evergreen.V408.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V408.Discord
import Evergreen.V408.Drawing
import Evergreen.V408.Game
import Evergreen.V408.Id
import Evergreen.V408.IdArray
import Evergreen.V408.Message
import Evergreen.V408.MessageArray
import Evergreen.V408.NonemptyDict
import Evergreen.V408.OneToOne
import Evergreen.V408.SessionIdHash
import Evergreen.V408.Thread
import Evergreen.V408.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V408.Id.Id Evergreen.V408.Id.UserId, Evergreen.V408.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V408.Id.Id Evergreen.V408.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V408.Id.Id Evergreen.V408.Id.UserId, Evergreen.V408.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V408.MessageArray.MessageArray Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId)
    , visibleMessages : Evergreen.V408.VisibleMessages.VisibleMessages Evergreen.V408.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
            { threadRoute : Evergreen.V408.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V408.Drawing.Drawing (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V408.MessageArray.MessageArray Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId)
    , visibleMessages : Evergreen.V408.VisibleMessages.VisibleMessages Evergreen.V408.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V408.NonemptyDict.NonemptyDict
            (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V408.Drawing.Drawing (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Evergreen.V408.Message.Message Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V408.IdArray.IdArray Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Message.Message Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
            { threadRoute : Evergreen.V408.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) Evergreen.V408.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V408.Drawing.Drawing (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V408.IdArray.IdArray Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Message.Message Evergreen.V408.Id.ChannelMessageId (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V408.OneToOne.OneToOne (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId)
    , members :
        Evergreen.V408.NonemptyDict.NonemptyDict
            (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V408.Drawing.Drawing (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId))
    }
