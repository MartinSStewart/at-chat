module Evergreen.V319.DmChannel exposing (..)

import Date
import Evergreen.V319.Discord
import Evergreen.V319.Drawing
import Evergreen.V319.Game
import Evergreen.V319.Id
import Evergreen.V319.IdArray
import Evergreen.V319.Message
import Evergreen.V319.NonemptyDict
import Evergreen.V319.OneToOne
import Evergreen.V319.Thread
import Evergreen.V319.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V319.IdArray.IdArray Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Message.MessageState Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))
    , visibleMessages : Evergreen.V319.VisibleMessages.VisibleMessages Evergreen.V319.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) (Evergreen.V319.Thread.LastTypedAt Evergreen.V319.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) Evergreen.V319.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) Evergreen.V319.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V319.Drawing.Drawing (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V319.IdArray.IdArray Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Message.MessageState Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))
    , visibleMessages : Evergreen.V319.VisibleMessages.VisibleMessages Evergreen.V319.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Thread.LastTypedAt Evergreen.V319.Id.ChannelMessageId)
    , members :
        Evergreen.V319.NonemptyDict.NonemptyDict
            (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V319.Drawing.Drawing (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V319.IdArray.IdArray Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Message.Message Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) (Evergreen.V319.Thread.LastTypedAt Evergreen.V319.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) Evergreen.V319.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) Evergreen.V319.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V319.Drawing.Drawing (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V319.IdArray.IdArray Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Message.Message Evergreen.V319.Id.ChannelMessageId (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (Evergreen.V319.Thread.LastTypedAt Evergreen.V319.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V319.OneToOne.OneToOne (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId)
    , members :
        Evergreen.V319.NonemptyDict.NonemptyDict
            (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V319.Drawing.Drawing (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))
    }
