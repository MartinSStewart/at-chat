module Evergreen.V392.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V392.Discord
import Evergreen.V392.Drawing
import Evergreen.V392.Id
import Evergreen.V392.IdArray
import Evergreen.V392.Message
import Evergreen.V392.MessageArray
import Evergreen.V392.OneToOne
import Evergreen.V392.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V392.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V392.MessageArray.MessageArray Evergreen.V392.Id.ThreadMessageId (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId)
    , visibleMessages : Evergreen.V392.VisibleMessages.VisibleMessages Evergreen.V392.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (LastTypedAt Evergreen.V392.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V392.Drawing.Drawing (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V392.MessageArray.MessageArray Evergreen.V392.Id.ThreadMessageId (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId)
    , visibleMessages : Evergreen.V392.VisibleMessages.VisibleMessages Evergreen.V392.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (LastTypedAt Evergreen.V392.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V392.Drawing.Drawing (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V392.IdArray.IdArray Evergreen.V392.Id.ThreadMessageId (Evergreen.V392.Message.Message Evergreen.V392.Id.ThreadMessageId (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (LastTypedAt Evergreen.V392.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V392.Drawing.Drawing (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V392.IdArray.IdArray Evergreen.V392.Id.ThreadMessageId (Evergreen.V392.Message.Message Evergreen.V392.Id.ThreadMessageId (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId) (LastTypedAt Evergreen.V392.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V392.OneToOne.OneToOne (Evergreen.V392.Discord.Id Evergreen.V392.Discord.MessageId) (Evergreen.V392.Id.Id Evergreen.V392.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V392.Drawing.Drawing (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId))
    }
