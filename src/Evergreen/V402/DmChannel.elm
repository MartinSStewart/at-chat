module Evergreen.V402.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V402.Discord
import Evergreen.V402.Drawing
import Evergreen.V402.Game
import Evergreen.V402.Id
import Evergreen.V402.IdArray
import Evergreen.V402.Message
import Evergreen.V402.MessageArray
import Evergreen.V402.NonemptyDict
import Evergreen.V402.OneToOne
import Evergreen.V402.SessionIdHash
import Evergreen.V402.Thread
import Evergreen.V402.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V402.Id.Id Evergreen.V402.Id.UserId, Evergreen.V402.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V402.Id.Id Evergreen.V402.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V402.Id.Id Evergreen.V402.Id.UserId, Evergreen.V402.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V402.MessageArray.MessageArray Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)
    , visibleMessages : Evergreen.V402.VisibleMessages.VisibleMessages Evergreen.V402.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
            { threadRoute : Evergreen.V402.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V402.Drawing.Drawing (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V402.MessageArray.MessageArray Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId)
    , visibleMessages : Evergreen.V402.VisibleMessages.VisibleMessages Evergreen.V402.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V402.NonemptyDict.NonemptyDict
            (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V402.Drawing.Drawing (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Evergreen.V402.Message.Message Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V402.IdArray.IdArray Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Message.Message Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
            { threadRoute : Evergreen.V402.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) Evergreen.V402.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V402.Drawing.Drawing (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V402.IdArray.IdArray Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Message.Message Evergreen.V402.Id.ChannelMessageId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V402.OneToOne.OneToOne (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId)
    , members :
        Evergreen.V402.NonemptyDict.NonemptyDict
            (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V402.Drawing.Drawing (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId))
    }
