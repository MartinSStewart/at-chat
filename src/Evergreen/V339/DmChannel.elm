module Evergreen.V339.DmChannel exposing (..)

import Date
import Evergreen.V339.Discord
import Evergreen.V339.Drawing
import Evergreen.V339.Game
import Evergreen.V339.Id
import Evergreen.V339.IdArray
import Evergreen.V339.Message
import Evergreen.V339.MessageArray
import Evergreen.V339.NonemptyDict
import Evergreen.V339.OneToOne
import Evergreen.V339.Thread
import Evergreen.V339.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V339.MessageArray.MessageArray Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Message.Message Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))
    , visibleMessages : Evergreen.V339.VisibleMessages.VisibleMessages Evergreen.V339.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (Evergreen.V339.Thread.LastTypedAt Evergreen.V339.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) Evergreen.V339.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) Evergreen.V339.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V339.Drawing.Drawing (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V339.MessageArray.MessageArray Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Message.Message Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))
    , visibleMessages : Evergreen.V339.VisibleMessages.VisibleMessages Evergreen.V339.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Thread.LastTypedAt Evergreen.V339.Id.ChannelMessageId)
    , members :
        Evergreen.V339.NonemptyDict.NonemptyDict
            (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V339.Drawing.Drawing (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V339.IdArray.IdArray Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Message.Message Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (Evergreen.V339.Thread.LastTypedAt Evergreen.V339.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) Evergreen.V339.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) Evergreen.V339.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V339.Drawing.Drawing (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V339.IdArray.IdArray Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Message.Message Evergreen.V339.Id.ChannelMessageId (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (Evergreen.V339.Thread.LastTypedAt Evergreen.V339.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V339.OneToOne.OneToOne (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId)
    , members :
        Evergreen.V339.NonemptyDict.NonemptyDict
            (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V339.Drawing.Drawing (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))
    }
