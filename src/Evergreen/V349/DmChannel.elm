module Evergreen.V349.DmChannel exposing (..)

import Date
import Evergreen.V349.Discord
import Evergreen.V349.Drawing
import Evergreen.V349.Game
import Evergreen.V349.Id
import Evergreen.V349.IdArray
import Evergreen.V349.Message
import Evergreen.V349.MessageArray
import Evergreen.V349.NonemptyDict
import Evergreen.V349.OneToOne
import Evergreen.V349.Thread
import Evergreen.V349.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V349.MessageArray.MessageArray Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))
    , visibleMessages : Evergreen.V349.VisibleMessages.VisibleMessages Evergreen.V349.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (Evergreen.V349.Thread.LastTypedAt Evergreen.V349.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V349.Drawing.Drawing (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V349.MessageArray.MessageArray Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))
    , visibleMessages : Evergreen.V349.VisibleMessages.VisibleMessages Evergreen.V349.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Thread.LastTypedAt Evergreen.V349.Id.ChannelMessageId)
    , members :
        Evergreen.V349.NonemptyDict.NonemptyDict
            (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V349.Drawing.Drawing (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V349.IdArray.IdArray Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (Evergreen.V349.Thread.LastTypedAt Evergreen.V349.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) Evergreen.V349.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V349.Drawing.Drawing (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V349.IdArray.IdArray Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Message.Message Evergreen.V349.Id.ChannelMessageId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (Evergreen.V349.Thread.LastTypedAt Evergreen.V349.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V349.OneToOne.OneToOne (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId)
    , members :
        Evergreen.V349.NonemptyDict.NonemptyDict
            (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V349.Drawing.Drawing (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))
    }
