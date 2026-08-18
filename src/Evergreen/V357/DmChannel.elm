module Evergreen.V357.DmChannel exposing (..)

import Date
import Evergreen.V357.Discord
import Evergreen.V357.Drawing
import Evergreen.V357.Game
import Evergreen.V357.Id
import Evergreen.V357.IdArray
import Evergreen.V357.Message
import Evergreen.V357.MessageArray
import Evergreen.V357.NonemptyDict
import Evergreen.V357.OneToOne
import Evergreen.V357.Thread
import Evergreen.V357.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V357.MessageArray.MessageArray Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Message.Message Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))
    , visibleMessages : Evergreen.V357.VisibleMessages.VisibleMessages Evergreen.V357.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (Evergreen.V357.Thread.LastTypedAt Evergreen.V357.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V357.Drawing.Drawing (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V357.MessageArray.MessageArray Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Message.Message Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))
    , visibleMessages : Evergreen.V357.VisibleMessages.VisibleMessages Evergreen.V357.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Thread.LastTypedAt Evergreen.V357.Id.ChannelMessageId)
    , members :
        Evergreen.V357.NonemptyDict.NonemptyDict
            (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V357.Drawing.Drawing (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V357.IdArray.IdArray Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Message.Message Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (Evergreen.V357.Thread.LastTypedAt Evergreen.V357.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V357.Drawing.Drawing (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V357.IdArray.IdArray Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Message.Message Evergreen.V357.Id.ChannelMessageId (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (Evergreen.V357.Thread.LastTypedAt Evergreen.V357.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V357.OneToOne.OneToOne (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId)
    , members :
        Evergreen.V357.NonemptyDict.NonemptyDict
            (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V357.Drawing.Drawing (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))
    }
