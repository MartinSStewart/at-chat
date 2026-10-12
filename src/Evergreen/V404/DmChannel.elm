module Evergreen.V404.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V404.Discord
import Evergreen.V404.Drawing
import Evergreen.V404.Game
import Evergreen.V404.Id
import Evergreen.V404.IdArray
import Evergreen.V404.Message
import Evergreen.V404.MessageArray
import Evergreen.V404.NonemptyDict
import Evergreen.V404.OneToOne
import Evergreen.V404.SessionIdHash
import Evergreen.V404.Thread
import Evergreen.V404.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V404.Id.Id Evergreen.V404.Id.UserId, Evergreen.V404.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V404.Id.Id Evergreen.V404.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V404.Id.Id Evergreen.V404.Id.UserId, Evergreen.V404.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V404.MessageArray.MessageArray Evergreen.V404.Id.ChannelMessageId (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId)
    , visibleMessages : Evergreen.V404.VisibleMessages.VisibleMessages Evergreen.V404.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId)
            { threadRoute : Evergreen.V404.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) Evergreen.V404.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) Evergreen.V404.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V404.Drawing.Drawing (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V404.MessageArray.MessageArray Evergreen.V404.Id.ChannelMessageId (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId)
    , visibleMessages : Evergreen.V404.VisibleMessages.VisibleMessages Evergreen.V404.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V404.NonemptyDict.NonemptyDict
            (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V404.Drawing.Drawing (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) (Evergreen.V404.Message.Message Evergreen.V404.Id.ChannelMessageId (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) Evergreen.V404.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V404.IdArray.IdArray Evergreen.V404.Id.ChannelMessageId (Evergreen.V404.Message.Message Evergreen.V404.Id.ChannelMessageId (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId)
            { threadRoute : Evergreen.V404.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) Evergreen.V404.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) Evergreen.V404.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V404.Drawing.Drawing (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V404.IdArray.IdArray Evergreen.V404.Id.ChannelMessageId (Evergreen.V404.Message.Message Evergreen.V404.Id.ChannelMessageId (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V404.OneToOne.OneToOne (Evergreen.V404.Discord.Id Evergreen.V404.Discord.MessageId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId)
    , members :
        Evergreen.V404.NonemptyDict.NonemptyDict
            (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V404.Drawing.Drawing (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId))
    }
