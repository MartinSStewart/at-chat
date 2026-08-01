module Evergreen.V342.DmChannel exposing (..)

import Date
import Evergreen.V342.Discord
import Evergreen.V342.Drawing
import Evergreen.V342.Game
import Evergreen.V342.Id
import Evergreen.V342.IdArray
import Evergreen.V342.Message
import Evergreen.V342.MessageArray
import Evergreen.V342.NonemptyDict
import Evergreen.V342.OneToOne
import Evergreen.V342.Thread
import Evergreen.V342.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V342.MessageArray.MessageArray Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))
    , visibleMessages : Evergreen.V342.VisibleMessages.VisibleMessages Evergreen.V342.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (Evergreen.V342.Thread.LastTypedAt Evergreen.V342.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V342.Drawing.Drawing (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V342.MessageArray.MessageArray Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))
    , visibleMessages : Evergreen.V342.VisibleMessages.VisibleMessages Evergreen.V342.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Thread.LastTypedAt Evergreen.V342.Id.ChannelMessageId)
    , members :
        Evergreen.V342.NonemptyDict.NonemptyDict
            (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V342.Drawing.Drawing (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V342.IdArray.IdArray Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (Evergreen.V342.Thread.LastTypedAt Evergreen.V342.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) Evergreen.V342.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V342.Drawing.Drawing (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V342.IdArray.IdArray Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Message.Message Evergreen.V342.Id.ChannelMessageId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (Evergreen.V342.Thread.LastTypedAt Evergreen.V342.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V342.OneToOne.OneToOne (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId)
    , members :
        Evergreen.V342.NonemptyDict.NonemptyDict
            (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V342.Drawing.Drawing (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))
    }
