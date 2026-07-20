module Evergreen.V330.DmChannel exposing (..)

import Date
import Evergreen.V330.Discord
import Evergreen.V330.Drawing
import Evergreen.V330.Game
import Evergreen.V330.Id
import Evergreen.V330.IdArray
import Evergreen.V330.Message
import Evergreen.V330.NonemptyDict
import Evergreen.V330.OneToOne
import Evergreen.V330.Thread
import Evergreen.V330.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V330.IdArray.IdArray Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Message.MessageState Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))
    , visibleMessages : Evergreen.V330.VisibleMessages.VisibleMessages Evergreen.V330.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (Evergreen.V330.Thread.LastTypedAt Evergreen.V330.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) Evergreen.V330.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) Evergreen.V330.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V330.Drawing.Drawing (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V330.IdArray.IdArray Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Message.MessageState Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))
    , visibleMessages : Evergreen.V330.VisibleMessages.VisibleMessages Evergreen.V330.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Thread.LastTypedAt Evergreen.V330.Id.ChannelMessageId)
    , members :
        Evergreen.V330.NonemptyDict.NonemptyDict
            (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V330.Drawing.Drawing (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V330.IdArray.IdArray Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Message.Message Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (Evergreen.V330.Thread.LastTypedAt Evergreen.V330.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) Evergreen.V330.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) Evergreen.V330.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V330.Drawing.Drawing (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V330.IdArray.IdArray Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Message.Message Evergreen.V330.Id.ChannelMessageId (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (Evergreen.V330.Thread.LastTypedAt Evergreen.V330.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V330.OneToOne.OneToOne (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId)
    , members :
        Evergreen.V330.NonemptyDict.NonemptyDict
            (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V330.Drawing.Drawing (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))
    }
