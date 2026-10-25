module Evergreen.V411.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V411.Discord
import Evergreen.V411.Drawing
import Evergreen.V411.Game
import Evergreen.V411.Id
import Evergreen.V411.IdArray
import Evergreen.V411.Message
import Evergreen.V411.MessageArray
import Evergreen.V411.NonemptyDict
import Evergreen.V411.OneToOne
import Evergreen.V411.SessionIdHash
import Evergreen.V411.Thread
import Evergreen.V411.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V411.Id.Id Evergreen.V411.Id.UserId, Evergreen.V411.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V411.Id.Id Evergreen.V411.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V411.Id.Id Evergreen.V411.Id.UserId, Evergreen.V411.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V411.MessageArray.MessageArray Evergreen.V411.Id.ChannelMessageId (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId)
    , visibleMessages : Evergreen.V411.VisibleMessages.VisibleMessages Evergreen.V411.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId)
            { threadRoute : Evergreen.V411.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) Evergreen.V411.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) Evergreen.V411.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V411.Drawing.Drawing (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V411.MessageArray.MessageArray Evergreen.V411.Id.ChannelMessageId (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId)
    , visibleMessages : Evergreen.V411.VisibleMessages.VisibleMessages Evergreen.V411.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V411.NonemptyDict.NonemptyDict
            (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V411.Drawing.Drawing (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Evergreen.V411.Message.Message Evergreen.V411.Id.ChannelMessageId (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) Evergreen.V411.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V411.IdArray.IdArray Evergreen.V411.Id.ChannelMessageId (Evergreen.V411.Message.Message Evergreen.V411.Id.ChannelMessageId (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId)
            { threadRoute : Evergreen.V411.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) Evergreen.V411.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) Evergreen.V411.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V411.Drawing.Drawing (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V411.IdArray.IdArray Evergreen.V411.Id.ChannelMessageId (Evergreen.V411.Message.Message Evergreen.V411.Id.ChannelMessageId (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V411.OneToOne.OneToOne (Evergreen.V411.Discord.Id Evergreen.V411.Discord.MessageId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId)
    , members :
        Evergreen.V411.NonemptyDict.NonemptyDict
            (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V411.Drawing.Drawing (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId))
    }
