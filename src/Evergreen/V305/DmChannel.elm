module Evergreen.V305.DmChannel exposing (..)

import Date
import Evergreen.V305.Discord
import Evergreen.V305.Drawing
import Evergreen.V305.Game
import Evergreen.V305.Id
import Evergreen.V305.IdArray
import Evergreen.V305.Message
import Evergreen.V305.NonemptyDict
import Evergreen.V305.OneToOne
import Evergreen.V305.Thread
import Evergreen.V305.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V305.IdArray.IdArray Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Message.MessageState Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId))
    , visibleMessages : Evergreen.V305.VisibleMessages.VisibleMessages Evergreen.V305.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) (Evergreen.V305.Thread.LastTypedAt Evergreen.V305.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) Evergreen.V305.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) Evergreen.V305.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V305.Drawing.Drawing (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V305.IdArray.IdArray Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Message.MessageState Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId))
    , visibleMessages : Evergreen.V305.VisibleMessages.VisibleMessages Evergreen.V305.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (Evergreen.V305.Thread.LastTypedAt Evergreen.V305.Id.ChannelMessageId)
    , members :
        Evergreen.V305.NonemptyDict.NonemptyDict
            (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V305.Drawing.Drawing (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V305.IdArray.IdArray Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Message.Message Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) (Evergreen.V305.Thread.LastTypedAt Evergreen.V305.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) Evergreen.V305.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) Evergreen.V305.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V305.Drawing.Drawing (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V305.IdArray.IdArray Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Message.Message Evergreen.V305.Id.ChannelMessageId (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (Evergreen.V305.Thread.LastTypedAt Evergreen.V305.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V305.OneToOne.OneToOne (Evergreen.V305.Discord.Id Evergreen.V305.Discord.MessageId) (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId)
    , members :
        Evergreen.V305.NonemptyDict.NonemptyDict
            (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V305.Drawing.Drawing (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId))
    }
