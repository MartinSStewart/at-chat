module Evergreen.V366.DmChannel exposing (..)

import Date
import Evergreen.V366.Discord
import Evergreen.V366.Drawing
import Evergreen.V366.Game
import Evergreen.V366.Id
import Evergreen.V366.IdArray
import Evergreen.V366.Message
import Evergreen.V366.MessageArray
import Evergreen.V366.NonemptyDict
import Evergreen.V366.OneToOne
import Evergreen.V366.Thread
import Evergreen.V366.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V366.MessageArray.MessageArray Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Message.Message Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))
    , visibleMessages : Evergreen.V366.VisibleMessages.VisibleMessages Evergreen.V366.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (Evergreen.V366.Thread.LastTypedAt Evergreen.V366.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V366.Drawing.Drawing (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V366.MessageArray.MessageArray Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Message.Message Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))
    , visibleMessages : Evergreen.V366.VisibleMessages.VisibleMessages Evergreen.V366.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Thread.LastTypedAt Evergreen.V366.Id.ChannelMessageId)
    , members :
        Evergreen.V366.NonemptyDict.NonemptyDict
            (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V366.Drawing.Drawing (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V366.IdArray.IdArray Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Message.Message Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (Evergreen.V366.Thread.LastTypedAt Evergreen.V366.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V366.Drawing.Drawing (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V366.IdArray.IdArray Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Message.Message Evergreen.V366.Id.ChannelMessageId (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (Evergreen.V366.Thread.LastTypedAt Evergreen.V366.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V366.OneToOne.OneToOne (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId)
    , members :
        Evergreen.V366.NonemptyDict.NonemptyDict
            (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V366.Drawing.Drawing (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))
    }
