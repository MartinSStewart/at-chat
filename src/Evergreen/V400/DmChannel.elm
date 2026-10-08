module Evergreen.V400.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V400.Discord
import Evergreen.V400.Drawing
import Evergreen.V400.Game
import Evergreen.V400.Id
import Evergreen.V400.IdArray
import Evergreen.V400.Message
import Evergreen.V400.MessageArray
import Evergreen.V400.NonemptyDict
import Evergreen.V400.OneToOne
import Evergreen.V400.SessionIdHash
import Evergreen.V400.Thread
import Evergreen.V400.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V400.Id.Id Evergreen.V400.Id.UserId, Evergreen.V400.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V400.Id.Id Evergreen.V400.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V400.Id.Id Evergreen.V400.Id.UserId, Evergreen.V400.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V400.MessageArray.MessageArray Evergreen.V400.Id.ChannelMessageId (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId)
    , visibleMessages : Evergreen.V400.VisibleMessages.VisibleMessages Evergreen.V400.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId)
            { threadRoute : Evergreen.V400.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) Evergreen.V400.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) Evergreen.V400.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V400.Drawing.Drawing (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V400.MessageArray.MessageArray Evergreen.V400.Id.ChannelMessageId (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId)
    , visibleMessages : Evergreen.V400.VisibleMessages.VisibleMessages Evergreen.V400.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V400.NonemptyDict.NonemptyDict
            (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V400.Drawing.Drawing (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) (Evergreen.V400.Message.Message Evergreen.V400.Id.ChannelMessageId (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) Evergreen.V400.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V400.IdArray.IdArray Evergreen.V400.Id.ChannelMessageId (Evergreen.V400.Message.Message Evergreen.V400.Id.ChannelMessageId (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId)
            { threadRoute : Evergreen.V400.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) Evergreen.V400.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) Evergreen.V400.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V400.Drawing.Drawing (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V400.IdArray.IdArray Evergreen.V400.Id.ChannelMessageId (Evergreen.V400.Message.Message Evergreen.V400.Id.ChannelMessageId (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V400.OneToOne.OneToOne (Evergreen.V400.Discord.Id Evergreen.V400.Discord.MessageId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId)
    , members :
        Evergreen.V400.NonemptyDict.NonemptyDict
            (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V400.Drawing.Drawing (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId))
    }
