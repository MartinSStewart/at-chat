module Evergreen.V318.DmChannel exposing (..)

import Date
import Evergreen.V318.Discord
import Evergreen.V318.Drawing
import Evergreen.V318.Game
import Evergreen.V318.Id
import Evergreen.V318.IdArray
import Evergreen.V318.Message
import Evergreen.V318.NonemptyDict
import Evergreen.V318.OneToOne
import Evergreen.V318.Thread
import Evergreen.V318.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V318.IdArray.IdArray Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Message.MessageState Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))
    , visibleMessages : Evergreen.V318.VisibleMessages.VisibleMessages Evergreen.V318.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) (Evergreen.V318.Thread.LastTypedAt Evergreen.V318.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) Evergreen.V318.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) Evergreen.V318.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V318.Drawing.Drawing (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V318.IdArray.IdArray Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Message.MessageState Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))
    , visibleMessages : Evergreen.V318.VisibleMessages.VisibleMessages Evergreen.V318.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Thread.LastTypedAt Evergreen.V318.Id.ChannelMessageId)
    , members :
        Evergreen.V318.NonemptyDict.NonemptyDict
            (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V318.Drawing.Drawing (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V318.IdArray.IdArray Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Message.Message Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) (Evergreen.V318.Thread.LastTypedAt Evergreen.V318.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) Evergreen.V318.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) Evergreen.V318.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V318.Drawing.Drawing (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V318.IdArray.IdArray Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Message.Message Evergreen.V318.Id.ChannelMessageId (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (Evergreen.V318.Thread.LastTypedAt Evergreen.V318.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V318.OneToOne.OneToOne (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId)
    , members :
        Evergreen.V318.NonemptyDict.NonemptyDict
            (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V318.Drawing.Drawing (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))
    }
