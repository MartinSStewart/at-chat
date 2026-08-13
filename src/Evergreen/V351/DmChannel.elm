module Evergreen.V351.DmChannel exposing (..)

import Date
import Evergreen.V351.Discord
import Evergreen.V351.Drawing
import Evergreen.V351.Game
import Evergreen.V351.Id
import Evergreen.V351.IdArray
import Evergreen.V351.Message
import Evergreen.V351.MessageArray
import Evergreen.V351.NonemptyDict
import Evergreen.V351.OneToOne
import Evergreen.V351.Thread
import Evergreen.V351.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V351.MessageArray.MessageArray Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))
    , visibleMessages : Evergreen.V351.VisibleMessages.VisibleMessages Evergreen.V351.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (Evergreen.V351.Thread.LastTypedAt Evergreen.V351.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V351.Drawing.Drawing (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V351.MessageArray.MessageArray Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))
    , visibleMessages : Evergreen.V351.VisibleMessages.VisibleMessages Evergreen.V351.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Thread.LastTypedAt Evergreen.V351.Id.ChannelMessageId)
    , members :
        Evergreen.V351.NonemptyDict.NonemptyDict
            (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V351.Drawing.Drawing (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V351.IdArray.IdArray Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (Evergreen.V351.Thread.LastTypedAt Evergreen.V351.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V351.Drawing.Drawing (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V351.IdArray.IdArray Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Message.Message Evergreen.V351.Id.ChannelMessageId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (Evergreen.V351.Thread.LastTypedAt Evergreen.V351.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V351.OneToOne.OneToOne (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId)
    , members :
        Evergreen.V351.NonemptyDict.NonemptyDict
            (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V351.Drawing.Drawing (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))
    }
