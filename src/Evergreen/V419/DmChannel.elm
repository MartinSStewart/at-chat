module Evergreen.V419.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V419.Discord
import Evergreen.V419.Drawing
import Evergreen.V419.Game
import Evergreen.V419.Id
import Evergreen.V419.IdArray
import Evergreen.V419.Message
import Evergreen.V419.MessageArray
import Evergreen.V419.NonemptyDict
import Evergreen.V419.OneToOne
import Evergreen.V419.SessionIdHash
import Evergreen.V419.Thread
import Evergreen.V419.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V419.Id.Id Evergreen.V419.Id.UserId, Evergreen.V419.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V419.Id.Id Evergreen.V419.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V419.Id.Id Evergreen.V419.Id.UserId, Evergreen.V419.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V419.MessageArray.MessageArray Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)
    , visibleMessages : Evergreen.V419.VisibleMessages.VisibleMessages Evergreen.V419.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
            { threadRoute : Evergreen.V419.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V419.Drawing.Drawing (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V419.MessageArray.MessageArray Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId)
    , visibleMessages : Evergreen.V419.VisibleMessages.VisibleMessages Evergreen.V419.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V419.NonemptyDict.NonemptyDict
            (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V419.Drawing.Drawing (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V419.IdArray.IdArray Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
            { threadRoute : Evergreen.V419.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) Evergreen.V419.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V419.Drawing.Drawing (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V419.IdArray.IdArray Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Message.Message Evergreen.V419.Id.ChannelMessageId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V419.OneToOne.OneToOne (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId)
    , members :
        Evergreen.V419.NonemptyDict.NonemptyDict
            (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V419.Drawing.Drawing (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId))
    }
