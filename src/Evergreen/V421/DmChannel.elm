module Evergreen.V421.DmChannel exposing (..)

import Date
import Effect.Time
import Evergreen.V421.Discord
import Evergreen.V421.Drawing
import Evergreen.V421.Game
import Evergreen.V421.Id
import Evergreen.V421.IdArray
import Evergreen.V421.Message
import Evergreen.V421.MessageArray
import Evergreen.V421.NonemptyDict
import Evergreen.V421.OneToOne
import Evergreen.V421.SessionIdHash
import Evergreen.V421.Thread
import Evergreen.V421.VisibleMessages
import SeqDict


type alias E2eeEnabledData =
    { enabledAt : Effect.Time.Posix
    , requestedBy : ( Evergreen.V421.Id.Id Evergreen.V421.Id.UserId, Evergreen.V421.SessionIdHash.SessionIdHash )
    }


type E2eeStatus
    = E2eeDisabled (Maybe ( Evergreen.V421.Id.Id Evergreen.V421.Id.UserId, Effect.Time.Posix ))
    | E2eeRequestedBy ( Evergreen.V421.Id.Id Evergreen.V421.Id.UserId, Evergreen.V421.SessionIdHash.SessionIdHash )
    | E2eeDeclinedBy (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | E2eeEnabled E2eeEnabledData


type alias FrontendDmChannel =
    { messages : Evergreen.V421.MessageArray.MessageArray Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId)
    , visibleMessages : Evergreen.V421.VisibleMessages.VisibleMessages Evergreen.V421.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
            { threadRoute : Evergreen.V421.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V421.Drawing.Drawing (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V421.MessageArray.MessageArray Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId)
    , visibleMessages : Evergreen.V421.VisibleMessages.VisibleMessages Evergreen.V421.Id.ChannelMessageId
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId)
            }
    , members :
        Evergreen.V421.NonemptyDict.NonemptyDict
            (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V421.Drawing.Drawing (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId))
    }


type alias LoadedMessages =
    { messages : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))
    , repliedToMatches : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Game.LoadedMatch
    }


type alias BackendDmChannel =
    { messages : Evergreen.V421.IdArray.IdArray Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
            { threadRoute : Evergreen.V421.Id.ThreadRouteWithMaybeMessage
            , time : Effect.Time.Posix
            }
    , threads : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V421.Drawing.Drawing (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V421.IdArray.IdArray Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Message.Message Evergreen.V421.Id.ChannelMessageId (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId))
    , lastTypedAt :
        SeqDict.SeqDict
            (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
            { time : Effect.Time.Posix
            , messageIndex : Maybe (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId)
            }
    , linkedMessageIds : Evergreen.V421.OneToOne.OneToOne (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId)
    , members :
        Evergreen.V421.NonemptyDict.NonemptyDict
            (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V421.Drawing.Drawing (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId))
    }
