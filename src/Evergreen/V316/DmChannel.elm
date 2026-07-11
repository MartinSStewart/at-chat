module Evergreen.V316.DmChannel exposing (..)

import Date
import Evergreen.V316.Discord
import Evergreen.V316.Drawing
import Evergreen.V316.Game
import Evergreen.V316.Id
import Evergreen.V316.IdArray
import Evergreen.V316.Message
import Evergreen.V316.NonemptyDict
import Evergreen.V316.OneToOne
import Evergreen.V316.Thread
import Evergreen.V316.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V316.IdArray.IdArray Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Message.MessageState Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))
    , visibleMessages : Evergreen.V316.VisibleMessages.VisibleMessages Evergreen.V316.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) (Evergreen.V316.Thread.LastTypedAt Evergreen.V316.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) Evergreen.V316.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) Evergreen.V316.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V316.Drawing.Drawing (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V316.IdArray.IdArray Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Message.MessageState Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))
    , visibleMessages : Evergreen.V316.VisibleMessages.VisibleMessages Evergreen.V316.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Thread.LastTypedAt Evergreen.V316.Id.ChannelMessageId)
    , members :
        Evergreen.V316.NonemptyDict.NonemptyDict
            (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V316.Drawing.Drawing (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V316.IdArray.IdArray Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Message.Message Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) (Evergreen.V316.Thread.LastTypedAt Evergreen.V316.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) Evergreen.V316.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) Evergreen.V316.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V316.Drawing.Drawing (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V316.IdArray.IdArray Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Message.Message Evergreen.V316.Id.ChannelMessageId (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (Evergreen.V316.Thread.LastTypedAt Evergreen.V316.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V316.OneToOne.OneToOne (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId)
    , members :
        Evergreen.V316.NonemptyDict.NonemptyDict
            (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V316.Drawing.Drawing (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))
    }
