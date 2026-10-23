module Evergreen.V409.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V409.Discord
import Evergreen.V409.Drawing
import Evergreen.V409.Game
import Evergreen.V409.Id
import Evergreen.V409.IdArray
import Evergreen.V409.Message
import Evergreen.V409.MessageArray
import Evergreen.V409.NonemptyDict
import Evergreen.V409.OneToOne
import Evergreen.V409.SessionIdHash
import Evergreen.V409.Thread
import Evergreen.V409.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V409.Id.Id Evergreen.V409.Id.UserId, Evergreen.V409.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V409.Id.Id Evergreen.V409.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V409.Id.Id Evergreen.V409.Id.UserId, Evergreen.V409.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V409.MessageArray.MessageArray Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId)
    , visibleMessages : Evergreen.V409.VisibleMessages.VisibleMessages Evergreen.V409.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
            { threadRoute : Evergreen.V409.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V409.Drawing.Drawing (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V409.MessageArray.MessageArray Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId)
    , visibleMessages : Evergreen.V409.VisibleMessages.VisibleMessages Evergreen.V409.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V409.NonemptyDict.NonemptyDict
            (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V409.Drawing.Drawing (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V409.IdArray.IdArray Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
            { threadRoute : Evergreen.V409.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) Evergreen.V409.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V409.Drawing.Drawing (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V409.IdArray.IdArray Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Message.Message Evergreen.V409.Id.ChannelMessageId (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V409.OneToOne.OneToOne (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId)
    , members :
        Evergreen.V409.NonemptyDict.NonemptyDict
            (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V409.Drawing.Drawing (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId))
    }
