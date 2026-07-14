module Evergreen.V323.DmChannel exposing (..)

import Date
import Evergreen.V323.Discord
import Evergreen.V323.Drawing
import Evergreen.V323.Game
import Evergreen.V323.Id
import Evergreen.V323.IdArray
import Evergreen.V323.Message
import Evergreen.V323.NonemptyDict
import Evergreen.V323.OneToOne
import Evergreen.V323.Thread
import Evergreen.V323.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V323.IdArray.IdArray Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Message.MessageState Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))
    , visibleMessages : Evergreen.V323.VisibleMessages.VisibleMessages Evergreen.V323.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) (Evergreen.V323.Thread.LastTypedAt Evergreen.V323.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) Evergreen.V323.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) Evergreen.V323.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V323.Drawing.Drawing (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V323.IdArray.IdArray Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Message.MessageState Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))
    , visibleMessages : Evergreen.V323.VisibleMessages.VisibleMessages Evergreen.V323.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Thread.LastTypedAt Evergreen.V323.Id.ChannelMessageId)
    , members :
        Evergreen.V323.NonemptyDict.NonemptyDict
            (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V323.Drawing.Drawing (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V323.IdArray.IdArray Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Message.Message Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) (Evergreen.V323.Thread.LastTypedAt Evergreen.V323.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) Evergreen.V323.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) Evergreen.V323.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V323.Drawing.Drawing (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V323.IdArray.IdArray Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Message.Message Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Thread.LastTypedAt Evergreen.V323.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V323.OneToOne.OneToOne (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId)
    , members :
        Evergreen.V323.NonemptyDict.NonemptyDict
            (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V323.Drawing.Drawing (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))
    }
