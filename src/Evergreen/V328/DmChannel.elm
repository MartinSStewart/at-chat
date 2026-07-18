module Evergreen.V328.DmChannel exposing (..)

import Date
import Evergreen.V328.Discord
import Evergreen.V328.Drawing
import Evergreen.V328.Game
import Evergreen.V328.Id
import Evergreen.V328.IdArray
import Evergreen.V328.Message
import Evergreen.V328.NonemptyDict
import Evergreen.V328.OneToOne
import Evergreen.V328.Thread
import Evergreen.V328.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V328.IdArray.IdArray Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Message.MessageState Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId))
    , visibleMessages : Evergreen.V328.VisibleMessages.VisibleMessages Evergreen.V328.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) (Evergreen.V328.Thread.LastTypedAt Evergreen.V328.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) Evergreen.V328.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) Evergreen.V328.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V328.Drawing.Drawing (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V328.IdArray.IdArray Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Message.MessageState Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId))
    , visibleMessages : Evergreen.V328.VisibleMessages.VisibleMessages Evergreen.V328.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (Evergreen.V328.Thread.LastTypedAt Evergreen.V328.Id.ChannelMessageId)
    , members :
        Evergreen.V328.NonemptyDict.NonemptyDict
            (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V328.Drawing.Drawing (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V328.IdArray.IdArray Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Message.Message Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) (Evergreen.V328.Thread.LastTypedAt Evergreen.V328.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) Evergreen.V328.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) Evergreen.V328.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V328.Drawing.Drawing (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V328.IdArray.IdArray Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Message.Message Evergreen.V328.Id.ChannelMessageId (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (Evergreen.V328.Thread.LastTypedAt Evergreen.V328.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V328.OneToOne.OneToOne (Evergreen.V328.Discord.Id Evergreen.V328.Discord.MessageId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId)
    , members :
        Evergreen.V328.NonemptyDict.NonemptyDict
            (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V328.Drawing.Drawing (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId))
    }
