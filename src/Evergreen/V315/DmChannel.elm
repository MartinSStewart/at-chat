module Evergreen.V315.DmChannel exposing (..)

import Date
import Evergreen.V315.Discord
import Evergreen.V315.Drawing
import Evergreen.V315.Game
import Evergreen.V315.Id
import Evergreen.V315.IdArray
import Evergreen.V315.Message
import Evergreen.V315.NonemptyDict
import Evergreen.V315.OneToOne
import Evergreen.V315.Thread
import Evergreen.V315.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V315.IdArray.IdArray Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Message.MessageState Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))
    , visibleMessages : Evergreen.V315.VisibleMessages.VisibleMessages Evergreen.V315.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) (Evergreen.V315.Thread.LastTypedAt Evergreen.V315.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) Evergreen.V315.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) Evergreen.V315.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V315.Drawing.Drawing (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V315.IdArray.IdArray Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Message.MessageState Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))
    , visibleMessages : Evergreen.V315.VisibleMessages.VisibleMessages Evergreen.V315.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Thread.LastTypedAt Evergreen.V315.Id.ChannelMessageId)
    , members :
        Evergreen.V315.NonemptyDict.NonemptyDict
            (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V315.Drawing.Drawing (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V315.IdArray.IdArray Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Message.Message Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) (Evergreen.V315.Thread.LastTypedAt Evergreen.V315.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) Evergreen.V315.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) Evergreen.V315.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V315.Drawing.Drawing (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V315.IdArray.IdArray Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Message.Message Evergreen.V315.Id.ChannelMessageId (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (Evergreen.V315.Thread.LastTypedAt Evergreen.V315.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V315.OneToOne.OneToOne (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId)
    , members :
        Evergreen.V315.NonemptyDict.NonemptyDict
            (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V315.Drawing.Drawing (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))
    }
