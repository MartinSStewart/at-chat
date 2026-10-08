module Evergreen.V401.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V401.Discord
import Evergreen.V401.Drawing
import Evergreen.V401.Game
import Evergreen.V401.Id
import Evergreen.V401.IdArray
import Evergreen.V401.Message
import Evergreen.V401.MessageArray
import Evergreen.V401.NonemptyDict
import Evergreen.V401.OneToOne
import Evergreen.V401.SessionIdHash
import Evergreen.V401.Thread
import Evergreen.V401.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V401.Id.Id Evergreen.V401.Id.UserId, Evergreen.V401.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V401.Id.Id Evergreen.V401.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V401.Id.Id Evergreen.V401.Id.UserId, Evergreen.V401.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V401.MessageArray.MessageArray Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)
    , visibleMessages : Evergreen.V401.VisibleMessages.VisibleMessages Evergreen.V401.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
            { threadRoute : Evergreen.V401.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V401.Drawing.Drawing (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V401.MessageArray.MessageArray Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId)
    , visibleMessages : Evergreen.V401.VisibleMessages.VisibleMessages Evergreen.V401.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V401.NonemptyDict.NonemptyDict
            (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V401.Drawing.Drawing (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Evergreen.V401.Message.Message Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V401.IdArray.IdArray Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Message.Message Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
            { threadRoute : Evergreen.V401.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) Evergreen.V401.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V401.Drawing.Drawing (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V401.IdArray.IdArray Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Message.Message Evergreen.V401.Id.ChannelMessageId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V401.OneToOne.OneToOne (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId)
    , members :
        Evergreen.V401.NonemptyDict.NonemptyDict
            (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V401.Drawing.Drawing (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId))
    }
