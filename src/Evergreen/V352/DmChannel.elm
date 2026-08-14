module Evergreen.V352.DmChannel exposing (..)

import Date
import Evergreen.V352.Discord
import Evergreen.V352.Drawing
import Evergreen.V352.Game
import Evergreen.V352.Id
import Evergreen.V352.IdArray
import Evergreen.V352.Message
import Evergreen.V352.MessageArray
import Evergreen.V352.NonemptyDict
import Evergreen.V352.OneToOne
import Evergreen.V352.Thread
import Evergreen.V352.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V352.MessageArray.MessageArray Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))
    , visibleMessages : Evergreen.V352.VisibleMessages.VisibleMessages Evergreen.V352.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) (Evergreen.V352.Thread.LastTypedAt Evergreen.V352.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V352.Drawing.Drawing (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V352.MessageArray.MessageArray Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))
    , visibleMessages : Evergreen.V352.VisibleMessages.VisibleMessages Evergreen.V352.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Thread.LastTypedAt Evergreen.V352.Id.ChannelMessageId)
    , members :
        Evergreen.V352.NonemptyDict.NonemptyDict
            (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V352.Drawing.Drawing (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V352.IdArray.IdArray Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) (Evergreen.V352.Thread.LastTypedAt Evergreen.V352.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) Evergreen.V352.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V352.Drawing.Drawing (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V352.IdArray.IdArray Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Message.Message Evergreen.V352.Id.ChannelMessageId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (Evergreen.V352.Thread.LastTypedAt Evergreen.V352.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V352.OneToOne.OneToOne (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId)
    , members :
        Evergreen.V352.NonemptyDict.NonemptyDict
            (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V352.Drawing.Drawing (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))
    }
