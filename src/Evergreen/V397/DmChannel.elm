module Evergreen.V397.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V397.Discord
import Evergreen.V397.Drawing
import Evergreen.V397.Game
import Evergreen.V397.Id
import Evergreen.V397.IdArray
import Evergreen.V397.Message
import Evergreen.V397.MessageArray
import Evergreen.V397.NonemptyDict
import Evergreen.V397.OneToOne
import Evergreen.V397.SessionIdHash
import Evergreen.V397.Thread
import Evergreen.V397.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V397.Id.Id Evergreen.V397.Id.UserId, Evergreen.V397.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V397.Id.Id Evergreen.V397.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V397.Id.Id Evergreen.V397.Id.UserId, Evergreen.V397.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V397.MessageArray.MessageArray Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)
    , visibleMessages : Evergreen.V397.VisibleMessages.VisibleMessages Evergreen.V397.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
            { threadRoute : Evergreen.V397.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V397.Drawing.Drawing (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V397.MessageArray.MessageArray Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId)
    , visibleMessages : Evergreen.V397.VisibleMessages.VisibleMessages Evergreen.V397.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V397.NonemptyDict.NonemptyDict
            (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V397.Drawing.Drawing (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.Message.Message Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V397.IdArray.IdArray Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Message.Message Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
            { threadRoute : Evergreen.V397.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V397.Drawing.Drawing (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V397.IdArray.IdArray Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Message.Message Evergreen.V397.Id.ChannelMessageId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V397.OneToOne.OneToOne (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId)
    , members :
        Evergreen.V397.NonemptyDict.NonemptyDict
            (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V397.Drawing.Drawing (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId))
    }
