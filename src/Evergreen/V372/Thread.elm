module Evergreen.V372.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V372.Discord
import Evergreen.V372.Drawing
import Evergreen.V372.Id
import Evergreen.V372.IdArray
import Evergreen.V372.Message
import Evergreen.V372.MessageArray
import Evergreen.V372.OneToOne
import Evergreen.V372.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V372.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V372.MessageArray.MessageArray Evergreen.V372.Id.ThreadMessageId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    , visibleMessages : Evergreen.V372.VisibleMessages.VisibleMessages Evergreen.V372.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (LastTypedAt Evergreen.V372.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V372.Drawing.Drawing (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V372.MessageArray.MessageArray Evergreen.V372.Id.ThreadMessageId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
    , visibleMessages : Evergreen.V372.VisibleMessages.VisibleMessages Evergreen.V372.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (LastTypedAt Evergreen.V372.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V372.Drawing.Drawing (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V372.IdArray.IdArray Evergreen.V372.Id.ThreadMessageId (Evergreen.V372.Message.Message Evergreen.V372.Id.ThreadMessageId (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) (LastTypedAt Evergreen.V372.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V372.Drawing.Drawing (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V372.IdArray.IdArray Evergreen.V372.Id.ThreadMessageId (Evergreen.V372.Message.Message Evergreen.V372.Id.ThreadMessageId (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId) (LastTypedAt Evergreen.V372.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V372.OneToOne.OneToOne (Evergreen.V372.Discord.Id Evergreen.V372.Discord.MessageId) (Evergreen.V372.Id.Id Evergreen.V372.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V372.Drawing.Drawing (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId))
    }
