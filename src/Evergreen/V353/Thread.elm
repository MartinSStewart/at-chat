module Evergreen.V353.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V353.Discord
import Evergreen.V353.Drawing
import Evergreen.V353.Id
import Evergreen.V353.IdArray
import Evergreen.V353.Message
import Evergreen.V353.MessageArray
import Evergreen.V353.OneToOne
import Evergreen.V353.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V353.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V353.MessageArray.MessageArray Evergreen.V353.Id.ThreadMessageId (Evergreen.V353.Message.Message Evergreen.V353.Id.ThreadMessageId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))
    , visibleMessages : Evergreen.V353.VisibleMessages.VisibleMessages Evergreen.V353.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) (LastTypedAt Evergreen.V353.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V353.Drawing.Drawing (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V353.MessageArray.MessageArray Evergreen.V353.Id.ThreadMessageId (Evergreen.V353.Message.Message Evergreen.V353.Id.ThreadMessageId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))
    , visibleMessages : Evergreen.V353.VisibleMessages.VisibleMessages Evergreen.V353.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (LastTypedAt Evergreen.V353.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V353.Drawing.Drawing (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V353.IdArray.IdArray Evergreen.V353.Id.ThreadMessageId (Evergreen.V353.Message.Message Evergreen.V353.Id.ThreadMessageId (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId) (LastTypedAt Evergreen.V353.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V353.Drawing.Drawing (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V353.IdArray.IdArray Evergreen.V353.Id.ThreadMessageId (Evergreen.V353.Message.Message Evergreen.V353.Id.ThreadMessageId (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (LastTypedAt Evergreen.V353.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V353.OneToOne.OneToOne (Evergreen.V353.Discord.Id Evergreen.V353.Discord.MessageId) (Evergreen.V353.Id.Id Evergreen.V353.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V353.Drawing.Drawing (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId))
    }
