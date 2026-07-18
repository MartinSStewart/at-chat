module Evergreen.V327.DmChannel exposing (..)

import Date
import Evergreen.V327.Discord
import Evergreen.V327.Drawing
import Evergreen.V327.Game
import Evergreen.V327.Id
import Evergreen.V327.IdArray
import Evergreen.V327.Message
import Evergreen.V327.NonemptyDict
import Evergreen.V327.OneToOne
import Evergreen.V327.Thread
import Evergreen.V327.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V327.IdArray.IdArray Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Message.MessageState Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))
    , visibleMessages : Evergreen.V327.VisibleMessages.VisibleMessages Evergreen.V327.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) (Evergreen.V327.Thread.LastTypedAt Evergreen.V327.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) Evergreen.V327.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) Evergreen.V327.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V327.Drawing.Drawing (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V327.IdArray.IdArray Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Message.MessageState Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))
    , visibleMessages : Evergreen.V327.VisibleMessages.VisibleMessages Evergreen.V327.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Thread.LastTypedAt Evergreen.V327.Id.ChannelMessageId)
    , members :
        Evergreen.V327.NonemptyDict.NonemptyDict
            (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V327.Drawing.Drawing (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V327.IdArray.IdArray Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Message.Message Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) (Evergreen.V327.Thread.LastTypedAt Evergreen.V327.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) Evergreen.V327.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) Evergreen.V327.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V327.Drawing.Drawing (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V327.IdArray.IdArray Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Message.Message Evergreen.V327.Id.ChannelMessageId (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (Evergreen.V327.Thread.LastTypedAt Evergreen.V327.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V327.OneToOne.OneToOne (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId)
    , members :
        Evergreen.V327.NonemptyDict.NonemptyDict
            (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V327.Drawing.Drawing (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))
    }
