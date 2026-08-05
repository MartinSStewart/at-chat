module Evergreen.V345.DmChannel exposing (..)

import Date
import Evergreen.V345.Discord
import Evergreen.V345.Drawing
import Evergreen.V345.Game
import Evergreen.V345.Id
import Evergreen.V345.IdArray
import Evergreen.V345.Message
import Evergreen.V345.MessageArray
import Evergreen.V345.NonemptyDict
import Evergreen.V345.OneToOne
import Evergreen.V345.Thread
import Evergreen.V345.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V345.MessageArray.MessageArray Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))
    , visibleMessages : Evergreen.V345.VisibleMessages.VisibleMessages Evergreen.V345.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (Evergreen.V345.Thread.LastTypedAt Evergreen.V345.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V345.Drawing.Drawing (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V345.MessageArray.MessageArray Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))
    , visibleMessages : Evergreen.V345.VisibleMessages.VisibleMessages Evergreen.V345.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Thread.LastTypedAt Evergreen.V345.Id.ChannelMessageId)
    , members :
        Evergreen.V345.NonemptyDict.NonemptyDict
            (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V345.Drawing.Drawing (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V345.IdArray.IdArray Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (Evergreen.V345.Thread.LastTypedAt Evergreen.V345.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V345.Drawing.Drawing (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V345.IdArray.IdArray Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Message.Message Evergreen.V345.Id.ChannelMessageId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Thread.LastTypedAt Evergreen.V345.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V345.OneToOne.OneToOne (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId)
    , members :
        Evergreen.V345.NonemptyDict.NonemptyDict
            (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V345.Drawing.Drawing (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))
    }
