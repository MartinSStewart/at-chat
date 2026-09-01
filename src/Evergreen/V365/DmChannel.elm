module Evergreen.V365.DmChannel exposing (..)

import Date
import Evergreen.V365.Discord
import Evergreen.V365.Drawing
import Evergreen.V365.Game
import Evergreen.V365.Id
import Evergreen.V365.IdArray
import Evergreen.V365.Message
import Evergreen.V365.MessageArray
import Evergreen.V365.NonemptyDict
import Evergreen.V365.OneToOne
import Evergreen.V365.Thread
import Evergreen.V365.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V365.MessageArray.MessageArray Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Message.Message Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))
    , visibleMessages : Evergreen.V365.VisibleMessages.VisibleMessages Evergreen.V365.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (Evergreen.V365.Thread.LastTypedAt Evergreen.V365.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V365.Drawing.Drawing (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V365.MessageArray.MessageArray Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Message.Message Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))
    , visibleMessages : Evergreen.V365.VisibleMessages.VisibleMessages Evergreen.V365.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Thread.LastTypedAt Evergreen.V365.Id.ChannelMessageId)
    , members :
        Evergreen.V365.NonemptyDict.NonemptyDict
            (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V365.Drawing.Drawing (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V365.IdArray.IdArray Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Message.Message Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (Evergreen.V365.Thread.LastTypedAt Evergreen.V365.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V365.Drawing.Drawing (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V365.IdArray.IdArray Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Message.Message Evergreen.V365.Id.ChannelMessageId (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (Evergreen.V365.Thread.LastTypedAt Evergreen.V365.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V365.OneToOne.OneToOne (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId)
    , members :
        Evergreen.V365.NonemptyDict.NonemptyDict
            (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V365.Drawing.Drawing (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))
    }
