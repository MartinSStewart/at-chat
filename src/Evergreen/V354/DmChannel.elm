module Evergreen.V354.DmChannel exposing (..)

import Date
import Evergreen.V354.Discord
import Evergreen.V354.Drawing
import Evergreen.V354.Game
import Evergreen.V354.Id
import Evergreen.V354.IdArray
import Evergreen.V354.Message
import Evergreen.V354.MessageArray
import Evergreen.V354.NonemptyDict
import Evergreen.V354.OneToOne
import Evergreen.V354.Thread
import Evergreen.V354.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V354.MessageArray.MessageArray Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))
    , visibleMessages : Evergreen.V354.VisibleMessages.VisibleMessages Evergreen.V354.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) (Evergreen.V354.Thread.LastTypedAt Evergreen.V354.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V354.Drawing.Drawing (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V354.MessageArray.MessageArray Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))
    , visibleMessages : Evergreen.V354.VisibleMessages.VisibleMessages Evergreen.V354.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Thread.LastTypedAt Evergreen.V354.Id.ChannelMessageId)
    , members :
        Evergreen.V354.NonemptyDict.NonemptyDict
            (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V354.Drawing.Drawing (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V354.IdArray.IdArray Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) (Evergreen.V354.Thread.LastTypedAt Evergreen.V354.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) Evergreen.V354.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V354.Drawing.Drawing (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V354.IdArray.IdArray Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Message.Message Evergreen.V354.Id.ChannelMessageId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (Evergreen.V354.Thread.LastTypedAt Evergreen.V354.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V354.OneToOne.OneToOne (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId)
    , members :
        Evergreen.V354.NonemptyDict.NonemptyDict
            (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V354.Drawing.Drawing (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))
    }
