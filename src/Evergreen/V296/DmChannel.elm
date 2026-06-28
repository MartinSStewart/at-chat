module Evergreen.V296.DmChannel exposing (..)

import Date
import Evergreen.V296.Discord
import Evergreen.V296.Drawing
import Evergreen.V296.Game
import Evergreen.V296.Id
import Evergreen.V296.IdArray
import Evergreen.V296.Message
import Evergreen.V296.NonemptyDict
import Evergreen.V296.OneToOne
import Evergreen.V296.Thread
import Evergreen.V296.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId)


type alias FrontendDmChannel =
    { messages : Evergreen.V296.IdArray.IdArray Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Message.MessageState Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))
    , visibleMessages : Evergreen.V296.VisibleMessages.VisibleMessages Evergreen.V296.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) (Evergreen.V296.Thread.LastTypedAt Evergreen.V296.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) Evergreen.V296.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) Evergreen.V296.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V296.Drawing.Drawing (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V296.IdArray.IdArray Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Message.MessageState Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))
    , visibleMessages : Evergreen.V296.VisibleMessages.VisibleMessages Evergreen.V296.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Thread.LastTypedAt Evergreen.V296.Id.ChannelMessageId)
    , members :
        Evergreen.V296.NonemptyDict.NonemptyDict
            (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V296.Drawing.Drawing (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V296.IdArray.IdArray Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Message.Message Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) (Evergreen.V296.Thread.LastTypedAt Evergreen.V296.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) Evergreen.V296.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) Evergreen.V296.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V296.Drawing.Drawing (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V296.IdArray.IdArray Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Message.Message Evergreen.V296.Id.ChannelMessageId (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (Evergreen.V296.Thread.LastTypedAt Evergreen.V296.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V296.OneToOne.OneToOne (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId)
    , members :
        Evergreen.V296.NonemptyDict.NonemptyDict
            (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V296.Drawing.Drawing (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))
    }
