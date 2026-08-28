module Evergreen.V363.DmChannel exposing (..)

import Date
import Evergreen.V363.Discord
import Evergreen.V363.Drawing
import Evergreen.V363.Game
import Evergreen.V363.Id
import Evergreen.V363.IdArray
import Evergreen.V363.Message
import Evergreen.V363.MessageArray
import Evergreen.V363.NonemptyDict
import Evergreen.V363.OneToOne
import Evergreen.V363.Thread
import Evergreen.V363.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V363.MessageArray.MessageArray Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))
    , visibleMessages : Evergreen.V363.VisibleMessages.VisibleMessages Evergreen.V363.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (Evergreen.V363.Thread.LastTypedAt Evergreen.V363.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V363.Drawing.Drawing (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V363.MessageArray.MessageArray Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))
    , visibleMessages : Evergreen.V363.VisibleMessages.VisibleMessages Evergreen.V363.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Thread.LastTypedAt Evergreen.V363.Id.ChannelMessageId)
    , members :
        Evergreen.V363.NonemptyDict.NonemptyDict
            (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V363.Drawing.Drawing (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V363.IdArray.IdArray Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (Evergreen.V363.Thread.LastTypedAt Evergreen.V363.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) Evergreen.V363.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V363.Drawing.Drawing (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V363.IdArray.IdArray Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Message.Message Evergreen.V363.Id.ChannelMessageId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (Evergreen.V363.Thread.LastTypedAt Evergreen.V363.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V363.OneToOne.OneToOne (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId)
    , members :
        Evergreen.V363.NonemptyDict.NonemptyDict
            (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V363.Drawing.Drawing (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))
    }
