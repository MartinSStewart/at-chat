module Evergreen.V313.DmChannel exposing (..)

import Date
import Evergreen.V313.Discord
import Evergreen.V313.Drawing
import Evergreen.V313.Game
import Evergreen.V313.Id
import Evergreen.V313.IdArray
import Evergreen.V313.Message
import Evergreen.V313.NonemptyDict
import Evergreen.V313.OneToOne
import Evergreen.V313.Thread
import Evergreen.V313.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V313.IdArray.IdArray Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Message.MessageState Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))
    , visibleMessages : Evergreen.V313.VisibleMessages.VisibleMessages Evergreen.V313.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) (Evergreen.V313.Thread.LastTypedAt Evergreen.V313.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) Evergreen.V313.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) Evergreen.V313.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V313.Drawing.Drawing (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V313.IdArray.IdArray Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Message.MessageState Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))
    , visibleMessages : Evergreen.V313.VisibleMessages.VisibleMessages Evergreen.V313.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Thread.LastTypedAt Evergreen.V313.Id.ChannelMessageId)
    , members :
        Evergreen.V313.NonemptyDict.NonemptyDict
            (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V313.Drawing.Drawing (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V313.IdArray.IdArray Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Message.Message Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) (Evergreen.V313.Thread.LastTypedAt Evergreen.V313.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) Evergreen.V313.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) Evergreen.V313.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V313.Drawing.Drawing (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V313.IdArray.IdArray Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Message.Message Evergreen.V313.Id.ChannelMessageId (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (Evergreen.V313.Thread.LastTypedAt Evergreen.V313.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V313.OneToOne.OneToOne (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId)
    , members :
        Evergreen.V313.NonemptyDict.NonemptyDict
            (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V313.Drawing.Drawing (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))
    }
