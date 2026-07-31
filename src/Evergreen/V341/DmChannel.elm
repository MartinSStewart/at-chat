module Evergreen.V341.DmChannel exposing (..)

import Date
import Evergreen.V341.Discord
import Evergreen.V341.Drawing
import Evergreen.V341.Game
import Evergreen.V341.Id
import Evergreen.V341.IdArray
import Evergreen.V341.Message
import Evergreen.V341.MessageArray
import Evergreen.V341.NonemptyDict
import Evergreen.V341.OneToOne
import Evergreen.V341.Thread
import Evergreen.V341.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V341.MessageArray.MessageArray Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))
    , visibleMessages : Evergreen.V341.VisibleMessages.VisibleMessages Evergreen.V341.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (Evergreen.V341.Thread.LastTypedAt Evergreen.V341.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V341.Drawing.Drawing (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V341.MessageArray.MessageArray Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))
    , visibleMessages : Evergreen.V341.VisibleMessages.VisibleMessages Evergreen.V341.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Thread.LastTypedAt Evergreen.V341.Id.ChannelMessageId)
    , members :
        Evergreen.V341.NonemptyDict.NonemptyDict
            (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V341.Drawing.Drawing (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V341.IdArray.IdArray Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (Evergreen.V341.Thread.LastTypedAt Evergreen.V341.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V341.Drawing.Drawing (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V341.IdArray.IdArray Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Message.Message Evergreen.V341.Id.ChannelMessageId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (Evergreen.V341.Thread.LastTypedAt Evergreen.V341.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V341.OneToOne.OneToOne (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId)
    , members :
        Evergreen.V341.NonemptyDict.NonemptyDict
            (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V341.Drawing.Drawing (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))
    }
