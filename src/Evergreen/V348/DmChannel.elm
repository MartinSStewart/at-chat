module Evergreen.V348.DmChannel exposing (..)

import Date
import Evergreen.V348.Discord
import Evergreen.V348.Drawing
import Evergreen.V348.Game
import Evergreen.V348.Id
import Evergreen.V348.IdArray
import Evergreen.V348.Message
import Evergreen.V348.MessageArray
import Evergreen.V348.NonemptyDict
import Evergreen.V348.OneToOne
import Evergreen.V348.Thread
import Evergreen.V348.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V348.MessageArray.MessageArray Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))
    , visibleMessages : Evergreen.V348.VisibleMessages.VisibleMessages Evergreen.V348.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (Evergreen.V348.Thread.LastTypedAt Evergreen.V348.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V348.Drawing.Drawing (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V348.MessageArray.MessageArray Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))
    , visibleMessages : Evergreen.V348.VisibleMessages.VisibleMessages Evergreen.V348.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Thread.LastTypedAt Evergreen.V348.Id.ChannelMessageId)
    , members :
        Evergreen.V348.NonemptyDict.NonemptyDict
            (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V348.Drawing.Drawing (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V348.IdArray.IdArray Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (Evergreen.V348.Thread.LastTypedAt Evergreen.V348.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V348.Drawing.Drawing (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V348.IdArray.IdArray Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Message.Message Evergreen.V348.Id.ChannelMessageId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (Evergreen.V348.Thread.LastTypedAt Evergreen.V348.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V348.OneToOne.OneToOne (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId)
    , members :
        Evergreen.V348.NonemptyDict.NonemptyDict
            (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V348.Drawing.Drawing (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))
    }
