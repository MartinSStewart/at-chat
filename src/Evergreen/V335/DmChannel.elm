module Evergreen.V335.DmChannel exposing (..)

import Date
import Evergreen.V335.Discord
import Evergreen.V335.Drawing
import Evergreen.V335.Game
import Evergreen.V335.Id
import Evergreen.V335.IdArray
import Evergreen.V335.Message
import Evergreen.V335.MessageArray
import Evergreen.V335.NonemptyDict
import Evergreen.V335.OneToOne
import Evergreen.V335.Thread
import Evergreen.V335.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V335.MessageArray.MessageArray Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Message.Message Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))
    , visibleMessages : Evergreen.V335.VisibleMessages.VisibleMessages Evergreen.V335.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (Evergreen.V335.Thread.LastTypedAt Evergreen.V335.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) Evergreen.V335.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) Evergreen.V335.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V335.Drawing.Drawing (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V335.MessageArray.MessageArray Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Message.Message Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))
    , visibleMessages : Evergreen.V335.VisibleMessages.VisibleMessages Evergreen.V335.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Thread.LastTypedAt Evergreen.V335.Id.ChannelMessageId)
    , members :
        Evergreen.V335.NonemptyDict.NonemptyDict
            (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V335.Drawing.Drawing (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V335.IdArray.IdArray Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Message.Message Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (Evergreen.V335.Thread.LastTypedAt Evergreen.V335.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) Evergreen.V335.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) Evergreen.V335.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V335.Drawing.Drawing (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V335.IdArray.IdArray Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Message.Message Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Thread.LastTypedAt Evergreen.V335.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V335.OneToOne.OneToOne (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId)
    , members :
        Evergreen.V335.NonemptyDict.NonemptyDict
            (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V335.Drawing.Drawing (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))
    }
