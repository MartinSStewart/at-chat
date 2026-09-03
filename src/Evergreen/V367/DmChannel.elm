module Evergreen.V367.DmChannel exposing (..)

import Date
import Evergreen.V367.Discord
import Evergreen.V367.Drawing
import Evergreen.V367.Game
import Evergreen.V367.Id
import Evergreen.V367.IdArray
import Evergreen.V367.Message
import Evergreen.V367.MessageArray
import Evergreen.V367.NonemptyDict
import Evergreen.V367.OneToOne
import Evergreen.V367.Thread
import Evergreen.V367.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V367.MessageArray.MessageArray Evergreen.V367.Id.ChannelMessageId (Evergreen.V367.Message.Message Evergreen.V367.Id.ChannelMessageId (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId))
    , visibleMessages : Evergreen.V367.VisibleMessages.VisibleMessages Evergreen.V367.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (Evergreen.V367.Thread.LastTypedAt Evergreen.V367.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V367.Drawing.Drawing (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V367.MessageArray.MessageArray Evergreen.V367.Id.ChannelMessageId (Evergreen.V367.Message.Message Evergreen.V367.Id.ChannelMessageId (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId))
    , visibleMessages : Evergreen.V367.VisibleMessages.VisibleMessages Evergreen.V367.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Thread.LastTypedAt Evergreen.V367.Id.ChannelMessageId)
    , members :
        Evergreen.V367.NonemptyDict.NonemptyDict
            (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V367.Drawing.Drawing (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V367.IdArray.IdArray Evergreen.V367.Id.ChannelMessageId (Evergreen.V367.Message.Message Evergreen.V367.Id.ChannelMessageId (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (Evergreen.V367.Thread.LastTypedAt Evergreen.V367.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V367.Drawing.Drawing (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V367.IdArray.IdArray Evergreen.V367.Id.ChannelMessageId (Evergreen.V367.Message.Message Evergreen.V367.Id.ChannelMessageId (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (Evergreen.V367.Thread.LastTypedAt Evergreen.V367.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V367.OneToOne.OneToOne (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId)
    , members :
        Evergreen.V367.NonemptyDict.NonemptyDict
            (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V367.Drawing.Drawing (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId))
    }
