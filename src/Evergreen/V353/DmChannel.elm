module Evergreen.V353.DmChannel exposing (..)

import Date
import Evergreen.V353.Discord
import Evergreen.V353.Drawing
import Evergreen.V353.Game
import Evergreen.V353.Id
import Evergreen.V353.IdArray
import Evergreen.V353.Message
import Evergreen.V353.MessageArray
import Evergreen.V353.NonemptyDict
import Evergreen.V353.OneToOne
import Evergreen.V353.Thread
import Evergreen.V353.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V353.MessageArray.MessageArray Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))
    , visibleMessages : Evergreen.V353.VisibleMessages.VisibleMessages Evergreen.V353.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) (Evergreen.V353.Thread.LastTypedAt Evergreen.V353.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V353.Drawing.Drawing (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V353.MessageArray.MessageArray Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))
    , visibleMessages : Evergreen.V353.VisibleMessages.VisibleMessages Evergreen.V353.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Thread.LastTypedAt Evergreen.V353.Id.ChannelMessageId)
    , members :
        Evergreen.V353.NonemptyDict.NonemptyDict
            (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V353.Drawing.Drawing (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V353.IdArray.IdArray Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) (Evergreen.V353.Thread.LastTypedAt Evergreen.V353.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) Evergreen.V353.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V353.Drawing.Drawing (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V353.IdArray.IdArray Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Message.Message Evergreen.V353.Id.ChannelMessageId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Thread.LastTypedAt Evergreen.V353.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V353.OneToOne.OneToOne (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId)
    , members :
        Evergreen.V353.NonemptyDict.NonemptyDict
            (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V353.Drawing.Drawing (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))
    }
