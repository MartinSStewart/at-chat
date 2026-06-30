module Evergreen.V297.DmChannel exposing (..)

import Date
import Evergreen.V297.Discord
import Evergreen.V297.Drawing
import Evergreen.V297.Game
import Evergreen.V297.Id
import Evergreen.V297.IdArray
import Evergreen.V297.Message
import Evergreen.V297.NonemptyDict
import Evergreen.V297.OneToOne
import Evergreen.V297.Thread
import Evergreen.V297.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId)


type alias FrontendDmChannel =
    { messages : Evergreen.V297.IdArray.IdArray Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Message.MessageState Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))
    , visibleMessages : Evergreen.V297.VisibleMessages.VisibleMessages Evergreen.V297.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) (Evergreen.V297.Thread.LastTypedAt Evergreen.V297.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) Evergreen.V297.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) Evergreen.V297.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V297.Drawing.Drawing (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V297.IdArray.IdArray Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Message.MessageState Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))
    , visibleMessages : Evergreen.V297.VisibleMessages.VisibleMessages Evergreen.V297.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Thread.LastTypedAt Evergreen.V297.Id.ChannelMessageId)
    , members :
        Evergreen.V297.NonemptyDict.NonemptyDict
            (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V297.Drawing.Drawing (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V297.IdArray.IdArray Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Message.Message Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) (Evergreen.V297.Thread.LastTypedAt Evergreen.V297.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) Evergreen.V297.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) Evergreen.V297.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V297.Drawing.Drawing (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V297.IdArray.IdArray Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Message.Message Evergreen.V297.Id.ChannelMessageId (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (Evergreen.V297.Thread.LastTypedAt Evergreen.V297.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V297.OneToOne.OneToOne (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId)
    , members :
        Evergreen.V297.NonemptyDict.NonemptyDict
            (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V297.Drawing.Drawing (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))
    }
