module Evergreen.V312.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V312.Discord
import Evergreen.V312.Drawing
import Evergreen.V312.Id
import Evergreen.V312.IdArray
import Evergreen.V312.Message
import Evergreen.V312.OneToOne
import Evergreen.V312.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V312.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V312.IdArray.IdArray Evergreen.V312.Id.ThreadMessageId (Evergreen.V312.Message.MessageState Evergreen.V312.Id.ThreadMessageId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))
    , visibleMessages : Evergreen.V312.VisibleMessages.VisibleMessages Evergreen.V312.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) (LastTypedAt Evergreen.V312.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V312.Drawing.Drawing (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V312.IdArray.IdArray Evergreen.V312.Id.ThreadMessageId (Evergreen.V312.Message.MessageState Evergreen.V312.Id.ThreadMessageId (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))
    , visibleMessages : Evergreen.V312.VisibleMessages.VisibleMessages Evergreen.V312.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (LastTypedAt Evergreen.V312.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V312.Drawing.Drawing (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V312.IdArray.IdArray Evergreen.V312.Id.ThreadMessageId (Evergreen.V312.Message.Message Evergreen.V312.Id.ThreadMessageId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) (LastTypedAt Evergreen.V312.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V312.Drawing.Drawing (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V312.IdArray.IdArray Evergreen.V312.Id.ThreadMessageId (Evergreen.V312.Message.Message Evergreen.V312.Id.ThreadMessageId (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (LastTypedAt Evergreen.V312.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V312.OneToOne.OneToOne (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V312.Drawing.Drawing (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))
    }
