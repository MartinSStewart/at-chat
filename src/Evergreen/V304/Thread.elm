module Evergreen.V304.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V304.Discord
import Evergreen.V304.Drawing
import Evergreen.V304.Id
import Evergreen.V304.IdArray
import Evergreen.V304.Message
import Evergreen.V304.OneToOne
import Evergreen.V304.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V304.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V304.IdArray.IdArray Evergreen.V304.Id.ThreadMessageId (Evergreen.V304.Message.MessageState Evergreen.V304.Id.ThreadMessageId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))
    , visibleMessages : Evergreen.V304.VisibleMessages.VisibleMessages Evergreen.V304.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) (LastTypedAt Evergreen.V304.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V304.Drawing.Drawing (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V304.IdArray.IdArray Evergreen.V304.Id.ThreadMessageId (Evergreen.V304.Message.MessageState Evergreen.V304.Id.ThreadMessageId (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))
    , visibleMessages : Evergreen.V304.VisibleMessages.VisibleMessages Evergreen.V304.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (LastTypedAt Evergreen.V304.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V304.Drawing.Drawing (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V304.IdArray.IdArray Evergreen.V304.Id.ThreadMessageId (Evergreen.V304.Message.Message Evergreen.V304.Id.ThreadMessageId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) (LastTypedAt Evergreen.V304.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V304.Drawing.Drawing (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V304.IdArray.IdArray Evergreen.V304.Id.ThreadMessageId (Evergreen.V304.Message.Message Evergreen.V304.Id.ThreadMessageId (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (LastTypedAt Evergreen.V304.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V304.OneToOne.OneToOne (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V304.Drawing.Drawing (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))
    }
