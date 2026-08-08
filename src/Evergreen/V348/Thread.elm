module Evergreen.V348.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V348.Discord
import Evergreen.V348.Drawing
import Evergreen.V348.Id
import Evergreen.V348.IdArray
import Evergreen.V348.Message
import Evergreen.V348.MessageArray
import Evergreen.V348.OneToOne
import Evergreen.V348.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V348.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V348.MessageArray.MessageArray Evergreen.V348.Id.ThreadMessageId (Evergreen.V348.Message.Message Evergreen.V348.Id.ThreadMessageId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))
    , visibleMessages : Evergreen.V348.VisibleMessages.VisibleMessages Evergreen.V348.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (LastTypedAt Evergreen.V348.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V348.Drawing.Drawing (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V348.MessageArray.MessageArray Evergreen.V348.Id.ThreadMessageId (Evergreen.V348.Message.Message Evergreen.V348.Id.ThreadMessageId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))
    , visibleMessages : Evergreen.V348.VisibleMessages.VisibleMessages Evergreen.V348.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (LastTypedAt Evergreen.V348.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V348.Drawing.Drawing (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V348.IdArray.IdArray Evergreen.V348.Id.ThreadMessageId (Evergreen.V348.Message.Message Evergreen.V348.Id.ThreadMessageId (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) (LastTypedAt Evergreen.V348.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V348.Drawing.Drawing (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V348.IdArray.IdArray Evergreen.V348.Id.ThreadMessageId (Evergreen.V348.Message.Message Evergreen.V348.Id.ThreadMessageId (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId) (LastTypedAt Evergreen.V348.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V348.OneToOne.OneToOne (Evergreen.V348.Discord.Id Evergreen.V348.Discord.MessageId) (Evergreen.V348.Id.Id Evergreen.V348.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V348.Drawing.Drawing (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId))
    }
