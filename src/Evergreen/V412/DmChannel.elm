module Evergreen.V412.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V412.Discord
import Evergreen.V412.Drawing
import Evergreen.V412.Game
import Evergreen.V412.Id
import Evergreen.V412.IdArray
import Evergreen.V412.Message
import Evergreen.V412.MessageArray
import Evergreen.V412.NonemptyDict
import Evergreen.V412.OneToOne
import Evergreen.V412.SessionIdHash
import Evergreen.V412.Thread
import Evergreen.V412.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V412.Id.Id Evergreen.V412.Id.UserId, Evergreen.V412.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V412.Id.Id Evergreen.V412.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V412.Id.Id Evergreen.V412.Id.UserId, Evergreen.V412.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V412.MessageArray.MessageArray Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId)
    , visibleMessages : Evergreen.V412.VisibleMessages.VisibleMessages Evergreen.V412.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
            { threadRoute : Evergreen.V412.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V412.Drawing.Drawing (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V412.MessageArray.MessageArray Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId)
    , visibleMessages : Evergreen.V412.VisibleMessages.VisibleMessages Evergreen.V412.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V412.NonemptyDict.NonemptyDict
            (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V412.Drawing.Drawing (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V412.IdArray.IdArray Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
            { threadRoute : Evergreen.V412.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) Evergreen.V412.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V412.Drawing.Drawing (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V412.IdArray.IdArray Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Message.Message Evergreen.V412.Id.ChannelMessageId (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V412.OneToOne.OneToOne (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId)
    , members :
        Evergreen.V412.NonemptyDict.NonemptyDict
            (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V412.Drawing.Drawing (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId))
    }
