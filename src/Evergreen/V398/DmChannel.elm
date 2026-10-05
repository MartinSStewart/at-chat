module Evergreen.V398.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V398.Discord
import Evergreen.V398.Drawing
import Evergreen.V398.Game
import Evergreen.V398.Id
import Evergreen.V398.IdArray
import Evergreen.V398.Message
import Evergreen.V398.MessageArray
import Evergreen.V398.NonemptyDict
import Evergreen.V398.OneToOne
import Evergreen.V398.SessionIdHash
import Evergreen.V398.Thread
import Evergreen.V398.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V398.Id.Id Evergreen.V398.Id.UserId, Evergreen.V398.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V398.Id.Id Evergreen.V398.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V398.Id.Id Evergreen.V398.Id.UserId, Evergreen.V398.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V398.MessageArray.MessageArray Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId)
    , visibleMessages : Evergreen.V398.VisibleMessages.VisibleMessages Evergreen.V398.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
            { threadRoute : Evergreen.V398.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V398.Drawing.Drawing (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V398.MessageArray.MessageArray Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId)
    , visibleMessages : Evergreen.V398.VisibleMessages.VisibleMessages Evergreen.V398.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V398.NonemptyDict.NonemptyDict
            (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V398.Drawing.Drawing (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Evergreen.V398.Message.Message Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V398.IdArray.IdArray Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Message.Message Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
            { threadRoute : Evergreen.V398.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) Evergreen.V398.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V398.Drawing.Drawing (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V398.IdArray.IdArray Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Message.Message Evergreen.V398.Id.ChannelMessageId (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V398.OneToOne.OneToOne (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId)
    , members :
        Evergreen.V398.NonemptyDict.NonemptyDict
            (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V398.Drawing.Drawing (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId))
    }
