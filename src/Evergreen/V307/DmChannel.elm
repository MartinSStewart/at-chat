module Evergreen.V307.DmChannel exposing (..)

import Date
import Evergreen.V307.Discord
import Evergreen.V307.Drawing
import Evergreen.V307.Game
import Evergreen.V307.Id
import Evergreen.V307.IdArray
import Evergreen.V307.Message
import Evergreen.V307.NonemptyDict
import Evergreen.V307.OneToOne
import Evergreen.V307.Thread
import Evergreen.V307.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V307.IdArray.IdArray Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Message.MessageState Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))
    , visibleMessages : Evergreen.V307.VisibleMessages.VisibleMessages Evergreen.V307.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) (Evergreen.V307.Thread.LastTypedAt Evergreen.V307.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) Evergreen.V307.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) Evergreen.V307.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V307.Drawing.Drawing (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V307.IdArray.IdArray Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Message.MessageState Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))
    , visibleMessages : Evergreen.V307.VisibleMessages.VisibleMessages Evergreen.V307.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Thread.LastTypedAt Evergreen.V307.Id.ChannelMessageId)
    , members :
        Evergreen.V307.NonemptyDict.NonemptyDict
            (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V307.Drawing.Drawing (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V307.IdArray.IdArray Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Message.Message Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) (Evergreen.V307.Thread.LastTypedAt Evergreen.V307.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) Evergreen.V307.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) Evergreen.V307.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V307.Drawing.Drawing (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V307.IdArray.IdArray Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Message.Message Evergreen.V307.Id.ChannelMessageId (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (Evergreen.V307.Thread.LastTypedAt Evergreen.V307.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V307.OneToOne.OneToOne (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId)
    , members :
        Evergreen.V307.NonemptyDict.NonemptyDict
            (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V307.Drawing.Drawing (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))
    }
