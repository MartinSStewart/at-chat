module Evergreen.V346.DmChannel exposing (..)

import Date
import Evergreen.V346.Discord
import Evergreen.V346.Drawing
import Evergreen.V346.Game
import Evergreen.V346.Id
import Evergreen.V346.IdArray
import Evergreen.V346.Message
import Evergreen.V346.MessageArray
import Evergreen.V346.NonemptyDict
import Evergreen.V346.OneToOne
import Evergreen.V346.Thread
import Evergreen.V346.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V346.MessageArray.MessageArray Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))
    , visibleMessages : Evergreen.V346.VisibleMessages.VisibleMessages Evergreen.V346.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (Evergreen.V346.Thread.LastTypedAt Evergreen.V346.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V346.Drawing.Drawing (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V346.MessageArray.MessageArray Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))
    , visibleMessages : Evergreen.V346.VisibleMessages.VisibleMessages Evergreen.V346.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Thread.LastTypedAt Evergreen.V346.Id.ChannelMessageId)
    , members :
        Evergreen.V346.NonemptyDict.NonemptyDict
            (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V346.Drawing.Drawing (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V346.IdArray.IdArray Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (Evergreen.V346.Thread.LastTypedAt Evergreen.V346.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V346.Drawing.Drawing (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V346.IdArray.IdArray Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Message.Message Evergreen.V346.Id.ChannelMessageId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (Evergreen.V346.Thread.LastTypedAt Evergreen.V346.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V346.OneToOne.OneToOne (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId)
    , members :
        Evergreen.V346.NonemptyDict.NonemptyDict
            (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V346.Drawing.Drawing (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))
    }
