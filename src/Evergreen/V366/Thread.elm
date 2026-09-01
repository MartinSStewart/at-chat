module Evergreen.V366.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V366.Discord
import Evergreen.V366.Drawing
import Evergreen.V366.Id
import Evergreen.V366.IdArray
import Evergreen.V366.Message
import Evergreen.V366.MessageArray
import Evergreen.V366.OneToOne
import Evergreen.V366.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V366.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V366.MessageArray.MessageArray Evergreen.V366.Id.ThreadMessageId (Evergreen.V366.Message.Message Evergreen.V366.Id.ThreadMessageId (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))
    , visibleMessages : Evergreen.V366.VisibleMessages.VisibleMessages Evergreen.V366.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (LastTypedAt Evergreen.V366.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V366.Drawing.Drawing (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V366.MessageArray.MessageArray Evergreen.V366.Id.ThreadMessageId (Evergreen.V366.Message.Message Evergreen.V366.Id.ThreadMessageId (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))
    , visibleMessages : Evergreen.V366.VisibleMessages.VisibleMessages Evergreen.V366.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (LastTypedAt Evergreen.V366.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V366.Drawing.Drawing (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V366.IdArray.IdArray Evergreen.V366.Id.ThreadMessageId (Evergreen.V366.Message.Message Evergreen.V366.Id.ThreadMessageId (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) (LastTypedAt Evergreen.V366.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V366.Drawing.Drawing (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V366.IdArray.IdArray Evergreen.V366.Id.ThreadMessageId (Evergreen.V366.Message.Message Evergreen.V366.Id.ThreadMessageId (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId) (LastTypedAt Evergreen.V366.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V366.OneToOne.OneToOne (Evergreen.V366.Discord.Id Evergreen.V366.Discord.MessageId) (Evergreen.V366.Id.Id Evergreen.V366.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V366.Drawing.Drawing (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId))
    }
