module Evergreen.V394.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V394.Discord
import Evergreen.V394.Drawing
import Evergreen.V394.Id
import Evergreen.V394.IdArray
import Evergreen.V394.Message
import Evergreen.V394.MessageArray
import Evergreen.V394.OneToOne
import Evergreen.V394.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V394.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V394.MessageArray.MessageArray Evergreen.V394.Id.ThreadMessageId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId)
    , visibleMessages : Evergreen.V394.VisibleMessages.VisibleMessages Evergreen.V394.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (LastTypedAt Evergreen.V394.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V394.Drawing.Drawing (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V394.MessageArray.MessageArray Evergreen.V394.Id.ThreadMessageId (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId)
    , visibleMessages : Evergreen.V394.VisibleMessages.VisibleMessages Evergreen.V394.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (LastTypedAt Evergreen.V394.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V394.Drawing.Drawing (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V394.IdArray.IdArray Evergreen.V394.Id.ThreadMessageId (Evergreen.V394.Message.Message Evergreen.V394.Id.ThreadMessageId (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) (LastTypedAt Evergreen.V394.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V394.Drawing.Drawing (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V394.IdArray.IdArray Evergreen.V394.Id.ThreadMessageId (Evergreen.V394.Message.Message Evergreen.V394.Id.ThreadMessageId (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId) (LastTypedAt Evergreen.V394.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V394.OneToOne.OneToOne (Evergreen.V394.Discord.Id Evergreen.V394.Discord.MessageId) (Evergreen.V394.Id.Id Evergreen.V394.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V394.Drawing.Drawing (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId))
    }
