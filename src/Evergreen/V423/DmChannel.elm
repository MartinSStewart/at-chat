module Evergreen.V423.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V423.Discord
import Evergreen.V423.Drawing
import Evergreen.V423.Game
import Evergreen.V423.Id
import Evergreen.V423.IdArray
import Evergreen.V423.Message
import Evergreen.V423.MessageArray
import Evergreen.V423.NonemptyDict
import Evergreen.V423.OneToOne
import Evergreen.V423.SessionIdHash
import Evergreen.V423.Thread
import Evergreen.V423.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V423.Id.Id Evergreen.V423.Id.UserId, Evergreen.V423.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V423.Id.Id Evergreen.V423.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V423.Id.Id Evergreen.V423.Id.UserId, Evergreen.V423.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V423.MessageArray.MessageArray Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId)
    , visibleMessages : Evergreen.V423.VisibleMessages.VisibleMessages Evergreen.V423.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
            { threadRoute : Evergreen.V423.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V423.Drawing.Drawing (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V423.MessageArray.MessageArray Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId)
    , visibleMessages : Evergreen.V423.VisibleMessages.VisibleMessages Evergreen.V423.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V423.NonemptyDict.NonemptyDict
            (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V423.Drawing.Drawing (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Evergreen.V423.Message.Message Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V423.IdArray.IdArray Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Message.Message Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
            { threadRoute : Evergreen.V423.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) Evergreen.V423.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V423.Drawing.Drawing (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V423.IdArray.IdArray Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Message.Message Evergreen.V423.Id.ChannelMessageId (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V423.OneToOne.OneToOne (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId)
    , members :
        Evergreen.V423.NonemptyDict.NonemptyDict
            (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V423.Drawing.Drawing (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId))
    }
