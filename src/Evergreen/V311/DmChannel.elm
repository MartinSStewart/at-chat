module Evergreen.V311.DmChannel exposing (..)

import Date
import Evergreen.V311.Discord
import Evergreen.V311.Drawing
import Evergreen.V311.Game
import Evergreen.V311.Id
import Evergreen.V311.IdArray
import Evergreen.V311.Message
import Evergreen.V311.NonemptyDict
import Evergreen.V311.OneToOne
import Evergreen.V311.Thread
import Evergreen.V311.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V311.IdArray.IdArray Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Message.MessageState Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))
    , visibleMessages : Evergreen.V311.VisibleMessages.VisibleMessages Evergreen.V311.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) (Evergreen.V311.Thread.LastTypedAt Evergreen.V311.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) Evergreen.V311.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) Evergreen.V311.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V311.Drawing.Drawing (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V311.IdArray.IdArray Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Message.MessageState Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))
    , visibleMessages : Evergreen.V311.VisibleMessages.VisibleMessages Evergreen.V311.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Thread.LastTypedAt Evergreen.V311.Id.ChannelMessageId)
    , members :
        Evergreen.V311.NonemptyDict.NonemptyDict
            (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V311.Drawing.Drawing (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V311.IdArray.IdArray Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Message.Message Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) (Evergreen.V311.Thread.LastTypedAt Evergreen.V311.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) Evergreen.V311.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) Evergreen.V311.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V311.Drawing.Drawing (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V311.IdArray.IdArray Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Message.Message Evergreen.V311.Id.ChannelMessageId (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (Evergreen.V311.Thread.LastTypedAt Evergreen.V311.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V311.OneToOne.OneToOne (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId)
    , members :
        Evergreen.V311.NonemptyDict.NonemptyDict
            (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V311.Drawing.Drawing (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))
    }
