module Evergreen.V344.DmChannel exposing (..)

import Date
import Evergreen.V344.Discord
import Evergreen.V344.Drawing
import Evergreen.V344.Game
import Evergreen.V344.Id
import Evergreen.V344.IdArray
import Evergreen.V344.Message
import Evergreen.V344.MessageArray
import Evergreen.V344.NonemptyDict
import Evergreen.V344.OneToOne
import Evergreen.V344.Thread
import Evergreen.V344.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V344.MessageArray.MessageArray Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Message.Message Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))
    , visibleMessages : Evergreen.V344.VisibleMessages.VisibleMessages Evergreen.V344.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (Evergreen.V344.Thread.LastTypedAt Evergreen.V344.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) Evergreen.V344.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) Evergreen.V344.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V344.Drawing.Drawing (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V344.MessageArray.MessageArray Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Message.Message Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId))
    , visibleMessages : Evergreen.V344.VisibleMessages.VisibleMessages Evergreen.V344.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Thread.LastTypedAt Evergreen.V344.Id.ChannelMessageId)
    , members :
        Evergreen.V344.NonemptyDict.NonemptyDict
            (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V344.Drawing.Drawing (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V344.IdArray.IdArray Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Message.Message Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (Evergreen.V344.Thread.LastTypedAt Evergreen.V344.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) Evergreen.V344.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) Evergreen.V344.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V344.Drawing.Drawing (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V344.IdArray.IdArray Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Message.Message Evergreen.V344.Id.ChannelMessageId (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (Evergreen.V344.Thread.LastTypedAt Evergreen.V344.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V344.OneToOne.OneToOne (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId)
    , members :
        Evergreen.V344.NonemptyDict.NonemptyDict
            (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V344.Drawing.Drawing (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId))
    }
