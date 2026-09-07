module Evergreen.V370.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V370.Discord
import Evergreen.V370.Drawing
import Evergreen.V370.Id
import Evergreen.V370.IdArray
import Evergreen.V370.Message
import Evergreen.V370.MessageArray
import Evergreen.V370.OneToOne
import Evergreen.V370.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V370.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V370.MessageArray.MessageArray Evergreen.V370.Id.ThreadMessageId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    , visibleMessages : Evergreen.V370.VisibleMessages.VisibleMessages Evergreen.V370.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (LastTypedAt Evergreen.V370.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V370.Drawing.Drawing (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V370.MessageArray.MessageArray Evergreen.V370.Id.ThreadMessageId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
    , visibleMessages : Evergreen.V370.VisibleMessages.VisibleMessages Evergreen.V370.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (LastTypedAt Evergreen.V370.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V370.Drawing.Drawing (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V370.IdArray.IdArray Evergreen.V370.Id.ThreadMessageId (Evergreen.V370.Message.Message Evergreen.V370.Id.ThreadMessageId (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) (LastTypedAt Evergreen.V370.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V370.Drawing.Drawing (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V370.IdArray.IdArray Evergreen.V370.Id.ThreadMessageId (Evergreen.V370.Message.Message Evergreen.V370.Id.ThreadMessageId (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId) (LastTypedAt Evergreen.V370.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V370.OneToOne.OneToOne (Evergreen.V370.Discord.Id Evergreen.V370.Discord.MessageId) (Evergreen.V370.Id.Id Evergreen.V370.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V370.Drawing.Drawing (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId))
    }
