module Evergreen.V382.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V382.Discord
import Evergreen.V382.Drawing
import Evergreen.V382.Id
import Evergreen.V382.IdArray
import Evergreen.V382.Message
import Evergreen.V382.MessageArray
import Evergreen.V382.OneToOne
import Evergreen.V382.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V382.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V382.MessageArray.MessageArray Evergreen.V382.Id.ThreadMessageId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId)
    , visibleMessages : Evergreen.V382.VisibleMessages.VisibleMessages Evergreen.V382.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (LastTypedAt Evergreen.V382.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V382.Drawing.Drawing (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V382.MessageArray.MessageArray Evergreen.V382.Id.ThreadMessageId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId)
    , visibleMessages : Evergreen.V382.VisibleMessages.VisibleMessages Evergreen.V382.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (LastTypedAt Evergreen.V382.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V382.Drawing.Drawing (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V382.IdArray.IdArray Evergreen.V382.Id.ThreadMessageId (Evergreen.V382.Message.Message Evergreen.V382.Id.ThreadMessageId (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) (LastTypedAt Evergreen.V382.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V382.Drawing.Drawing (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V382.IdArray.IdArray Evergreen.V382.Id.ThreadMessageId (Evergreen.V382.Message.Message Evergreen.V382.Id.ThreadMessageId (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId) (LastTypedAt Evergreen.V382.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V382.OneToOne.OneToOne (Evergreen.V382.Discord.Id Evergreen.V382.Discord.MessageId) (Evergreen.V382.Id.Id Evergreen.V382.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V382.Drawing.Drawing (Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId))
    }
