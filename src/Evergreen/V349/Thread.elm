module Evergreen.V349.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V349.Discord
import Evergreen.V349.Drawing
import Evergreen.V349.Id
import Evergreen.V349.IdArray
import Evergreen.V349.Message
import Evergreen.V349.MessageArray
import Evergreen.V349.OneToOne
import Evergreen.V349.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V349.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V349.MessageArray.MessageArray Evergreen.V349.Id.ThreadMessageId (Evergreen.V349.Message.Message Evergreen.V349.Id.ThreadMessageId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))
    , visibleMessages : Evergreen.V349.VisibleMessages.VisibleMessages Evergreen.V349.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (LastTypedAt Evergreen.V349.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V349.Drawing.Drawing (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V349.MessageArray.MessageArray Evergreen.V349.Id.ThreadMessageId (Evergreen.V349.Message.Message Evergreen.V349.Id.ThreadMessageId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))
    , visibleMessages : Evergreen.V349.VisibleMessages.VisibleMessages Evergreen.V349.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (LastTypedAt Evergreen.V349.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V349.Drawing.Drawing (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V349.IdArray.IdArray Evergreen.V349.Id.ThreadMessageId (Evergreen.V349.Message.Message Evergreen.V349.Id.ThreadMessageId (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) (LastTypedAt Evergreen.V349.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V349.Drawing.Drawing (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V349.IdArray.IdArray Evergreen.V349.Id.ThreadMessageId (Evergreen.V349.Message.Message Evergreen.V349.Id.ThreadMessageId (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId) (LastTypedAt Evergreen.V349.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V349.OneToOne.OneToOne (Evergreen.V349.Discord.Id Evergreen.V349.Discord.MessageId) (Evergreen.V349.Id.Id Evergreen.V349.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V349.Drawing.Drawing (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId))
    }
