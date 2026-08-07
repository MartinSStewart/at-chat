module Evergreen.V347.DmChannel exposing (..)

import Date
import Evergreen.V347.Discord
import Evergreen.V347.Drawing
import Evergreen.V347.Game
import Evergreen.V347.Id
import Evergreen.V347.IdArray
import Evergreen.V347.Message
import Evergreen.V347.MessageArray
import Evergreen.V347.NonemptyDict
import Evergreen.V347.OneToOne
import Evergreen.V347.Thread
import Evergreen.V347.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V347.MessageArray.MessageArray Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId))
    , visibleMessages : Evergreen.V347.VisibleMessages.VisibleMessages Evergreen.V347.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) (Evergreen.V347.Thread.LastTypedAt Evergreen.V347.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) Evergreen.V347.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) Evergreen.V347.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V347.Drawing.Drawing (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V347.MessageArray.MessageArray Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId))
    , visibleMessages : Evergreen.V347.VisibleMessages.VisibleMessages Evergreen.V347.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Thread.LastTypedAt Evergreen.V347.Id.ChannelMessageId)
    , members :
        Evergreen.V347.NonemptyDict.NonemptyDict
            (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V347.Drawing.Drawing (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V347.IdArray.IdArray Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) (Evergreen.V347.Thread.LastTypedAt Evergreen.V347.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) Evergreen.V347.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) Evergreen.V347.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V347.Drawing.Drawing (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V347.IdArray.IdArray Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Message.Message Evergreen.V347.Id.ChannelMessageId (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (Evergreen.V347.Thread.LastTypedAt Evergreen.V347.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V347.OneToOne.OneToOne (Evergreen.V347.Discord.Id Evergreen.V347.Discord.MessageId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId)
    , members :
        Evergreen.V347.NonemptyDict.NonemptyDict
            (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V347.Drawing.Drawing (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId))
    }
