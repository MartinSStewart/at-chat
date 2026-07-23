module Evergreen.V334.DmChannel exposing (..)

import Date
import Evergreen.V334.Discord
import Evergreen.V334.Drawing
import Evergreen.V334.Game
import Evergreen.V334.Id
import Evergreen.V334.IdArray
import Evergreen.V334.Message
import Evergreen.V334.NonemptyDict
import Evergreen.V334.OneToOne
import Evergreen.V334.Thread
import Evergreen.V334.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V334.IdArray.IdArray Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Message.MessageState Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId))
    , visibleMessages : Evergreen.V334.VisibleMessages.VisibleMessages Evergreen.V334.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) (Evergreen.V334.Thread.LastTypedAt Evergreen.V334.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) Evergreen.V334.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) Evergreen.V334.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V334.Drawing.Drawing (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V334.IdArray.IdArray Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Message.MessageState Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId))
    , visibleMessages : Evergreen.V334.VisibleMessages.VisibleMessages Evergreen.V334.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Thread.LastTypedAt Evergreen.V334.Id.ChannelMessageId)
    , members :
        Evergreen.V334.NonemptyDict.NonemptyDict
            (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V334.Drawing.Drawing (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V334.IdArray.IdArray Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Message.Message Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) (Evergreen.V334.Thread.LastTypedAt Evergreen.V334.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) Evergreen.V334.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) Evergreen.V334.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V334.Drawing.Drawing (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V334.IdArray.IdArray Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Message.Message Evergreen.V334.Id.ChannelMessageId (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (Evergreen.V334.Thread.LastTypedAt Evergreen.V334.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V334.OneToOne.OneToOne (Evergreen.V334.Discord.Id Evergreen.V334.Discord.MessageId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId)
    , members :
        Evergreen.V334.NonemptyDict.NonemptyDict
            (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V334.Drawing.Drawing (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId))
    }
