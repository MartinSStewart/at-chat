module Evergreen.V336.DmChannel exposing (..)

import Date
import Evergreen.V336.Discord
import Evergreen.V336.Drawing
import Evergreen.V336.Game
import Evergreen.V336.Id
import Evergreen.V336.IdArray
import Evergreen.V336.Message
import Evergreen.V336.MessageArray
import Evergreen.V336.NonemptyDict
import Evergreen.V336.OneToOne
import Evergreen.V336.Thread
import Evergreen.V336.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V336.MessageArray.MessageArray Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Message.Message Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))
    , visibleMessages : Evergreen.V336.VisibleMessages.VisibleMessages Evergreen.V336.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (Evergreen.V336.Thread.LastTypedAt Evergreen.V336.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) Evergreen.V336.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) Evergreen.V336.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V336.Drawing.Drawing (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V336.MessageArray.MessageArray Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Message.Message Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))
    , visibleMessages : Evergreen.V336.VisibleMessages.VisibleMessages Evergreen.V336.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Thread.LastTypedAt Evergreen.V336.Id.ChannelMessageId)
    , members :
        Evergreen.V336.NonemptyDict.NonemptyDict
            (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V336.Drawing.Drawing (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V336.IdArray.IdArray Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Message.Message Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (Evergreen.V336.Thread.LastTypedAt Evergreen.V336.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) Evergreen.V336.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) Evergreen.V336.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V336.Drawing.Drawing (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V336.IdArray.IdArray Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Message.Message Evergreen.V336.Id.ChannelMessageId (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Thread.LastTypedAt Evergreen.V336.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V336.OneToOne.OneToOne (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId)
    , members :
        Evergreen.V336.NonemptyDict.NonemptyDict
            (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V336.Drawing.Drawing (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))
    }
