module Evergreen.V309.DmChannel exposing (..)

import Date
import Evergreen.V309.Discord
import Evergreen.V309.Drawing
import Evergreen.V309.Game
import Evergreen.V309.Id
import Evergreen.V309.IdArray
import Evergreen.V309.Message
import Evergreen.V309.NonemptyDict
import Evergreen.V309.OneToOne
import Evergreen.V309.Thread
import Evergreen.V309.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V309.IdArray.IdArray Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Message.MessageState Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))
    , visibleMessages : Evergreen.V309.VisibleMessages.VisibleMessages Evergreen.V309.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) (Evergreen.V309.Thread.LastTypedAt Evergreen.V309.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) Evergreen.V309.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) Evergreen.V309.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V309.Drawing.Drawing (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V309.IdArray.IdArray Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Message.MessageState Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))
    , visibleMessages : Evergreen.V309.VisibleMessages.VisibleMessages Evergreen.V309.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Thread.LastTypedAt Evergreen.V309.Id.ChannelMessageId)
    , members :
        Evergreen.V309.NonemptyDict.NonemptyDict
            (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V309.Drawing.Drawing (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V309.IdArray.IdArray Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Message.Message Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) (Evergreen.V309.Thread.LastTypedAt Evergreen.V309.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) Evergreen.V309.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) Evergreen.V309.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V309.Drawing.Drawing (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V309.IdArray.IdArray Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Message.Message Evergreen.V309.Id.ChannelMessageId (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (Evergreen.V309.Thread.LastTypedAt Evergreen.V309.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V309.OneToOne.OneToOne (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId)
    , members :
        Evergreen.V309.NonemptyDict.NonemptyDict
            (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V309.Drawing.Drawing (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))
    }
