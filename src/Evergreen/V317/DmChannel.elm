module Evergreen.V317.DmChannel exposing (..)

import Date
import Evergreen.V317.Discord
import Evergreen.V317.Drawing
import Evergreen.V317.Game
import Evergreen.V317.Id
import Evergreen.V317.IdArray
import Evergreen.V317.Message
import Evergreen.V317.NonemptyDict
import Evergreen.V317.OneToOne
import Evergreen.V317.Thread
import Evergreen.V317.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V317.IdArray.IdArray Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Message.MessageState Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))
    , visibleMessages : Evergreen.V317.VisibleMessages.VisibleMessages Evergreen.V317.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) (Evergreen.V317.Thread.LastTypedAt Evergreen.V317.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) Evergreen.V317.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) Evergreen.V317.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V317.Drawing.Drawing (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V317.IdArray.IdArray Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Message.MessageState Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))
    , visibleMessages : Evergreen.V317.VisibleMessages.VisibleMessages Evergreen.V317.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Thread.LastTypedAt Evergreen.V317.Id.ChannelMessageId)
    , members :
        Evergreen.V317.NonemptyDict.NonemptyDict
            (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V317.Drawing.Drawing (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V317.IdArray.IdArray Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Message.Message Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) (Evergreen.V317.Thread.LastTypedAt Evergreen.V317.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) Evergreen.V317.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) Evergreen.V317.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V317.Drawing.Drawing (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V317.IdArray.IdArray Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Message.Message Evergreen.V317.Id.ChannelMessageId (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (Evergreen.V317.Thread.LastTypedAt Evergreen.V317.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V317.OneToOne.OneToOne (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId)
    , members :
        Evergreen.V317.NonemptyDict.NonemptyDict
            (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V317.Drawing.Drawing (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))
    }
