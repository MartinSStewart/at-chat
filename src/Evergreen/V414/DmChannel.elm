module Evergreen.V414.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V414.Discord
import Evergreen.V414.Drawing
import Evergreen.V414.Game
import Evergreen.V414.Id
import Evergreen.V414.IdArray
import Evergreen.V414.Message
import Evergreen.V414.MessageArray
import Evergreen.V414.NonemptyDict
import Evergreen.V414.OneToOne
import Evergreen.V414.SessionIdHash
import Evergreen.V414.Thread
import Evergreen.V414.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V414.Id.Id Evergreen.V414.Id.UserId, Evergreen.V414.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V414.Id.Id Evergreen.V414.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V414.Id.Id Evergreen.V414.Id.UserId, Evergreen.V414.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V414.MessageArray.MessageArray Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId)
    , visibleMessages : Evergreen.V414.VisibleMessages.VisibleMessages Evergreen.V414.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)
            { threadRoute : Evergreen.V414.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Evergreen.V414.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Evergreen.V414.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V414.Drawing.Drawing (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V414.MessageArray.MessageArray Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId)
    , visibleMessages : Evergreen.V414.VisibleMessages.VisibleMessages Evergreen.V414.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V414.NonemptyDict.NonemptyDict
            (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V414.Drawing.Drawing (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) (Evergreen.V414.Message.Message Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Evergreen.V414.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V414.IdArray.IdArray Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Message.Message Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)
            { threadRoute : Evergreen.V414.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Evergreen.V414.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) Evergreen.V414.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V414.Drawing.Drawing (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V414.IdArray.IdArray Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Message.Message Evergreen.V414.Id.ChannelMessageId (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V414.OneToOne.OneToOne (Evergreen.V414.Discord.Id Evergreen.V414.Discord.MessageId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId)
    , members :
        Evergreen.V414.NonemptyDict.NonemptyDict
            (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V414.Drawing.Drawing (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId))
    }
