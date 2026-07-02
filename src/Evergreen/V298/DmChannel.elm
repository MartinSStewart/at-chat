module Evergreen.V298.DmChannel exposing (..)

import Date
import Evergreen.V298.Discord
import Evergreen.V298.Drawing
import Evergreen.V298.Game
import Evergreen.V298.Id
import Evergreen.V298.IdArray
import Evergreen.V298.Message
import Evergreen.V298.NonemptyDict
import Evergreen.V298.OneToOne
import Evergreen.V298.Thread
import Evergreen.V298.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId)


type alias FrontendDmChannel =
    { messages : Evergreen.V298.IdArray.IdArray Evergreen.V298.Id.ChannelMessageId (Evergreen.V298.Message.MessageState Evergreen.V298.Id.ChannelMessageId (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))
    , visibleMessages : Evergreen.V298.VisibleMessages.VisibleMessages Evergreen.V298.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) (Evergreen.V298.Thread.LastTypedAt Evergreen.V298.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) Evergreen.V298.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) Evergreen.V298.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V298.Drawing.Drawing (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V298.IdArray.IdArray Evergreen.V298.Id.ChannelMessageId (Evergreen.V298.Message.MessageState Evergreen.V298.Id.ChannelMessageId (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId))
    , visibleMessages : Evergreen.V298.VisibleMessages.VisibleMessages Evergreen.V298.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Thread.LastTypedAt Evergreen.V298.Id.ChannelMessageId)
    , members :
        Evergreen.V298.NonemptyDict.NonemptyDict
            (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V298.Drawing.Drawing (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V298.IdArray.IdArray Evergreen.V298.Id.ChannelMessageId (Evergreen.V298.Message.Message Evergreen.V298.Id.ChannelMessageId (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) (Evergreen.V298.Thread.LastTypedAt Evergreen.V298.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) Evergreen.V298.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) Evergreen.V298.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V298.Drawing.Drawing (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V298.IdArray.IdArray Evergreen.V298.Id.ChannelMessageId (Evergreen.V298.Message.Message Evergreen.V298.Id.ChannelMessageId (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (Evergreen.V298.Thread.LastTypedAt Evergreen.V298.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V298.OneToOne.OneToOne (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId)
    , members :
        Evergreen.V298.NonemptyDict.NonemptyDict
            (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V298.Drawing.Drawing (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId))
    }
