module Evergreen.V342.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V342.Discord
import Evergreen.V342.Drawing
import Evergreen.V342.Id
import Evergreen.V342.IdArray
import Evergreen.V342.Message
import Evergreen.V342.MessageArray
import Evergreen.V342.OneToOne
import Evergreen.V342.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V342.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V342.MessageArray.MessageArray Evergreen.V342.Id.ThreadMessageId (Evergreen.V342.Message.Message Evergreen.V342.Id.ThreadMessageId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))
    , visibleMessages : Evergreen.V342.VisibleMessages.VisibleMessages Evergreen.V342.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (LastTypedAt Evergreen.V342.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V342.Drawing.Drawing (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V342.MessageArray.MessageArray Evergreen.V342.Id.ThreadMessageId (Evergreen.V342.Message.Message Evergreen.V342.Id.ThreadMessageId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))
    , visibleMessages : Evergreen.V342.VisibleMessages.VisibleMessages Evergreen.V342.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (LastTypedAt Evergreen.V342.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V342.Drawing.Drawing (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V342.IdArray.IdArray Evergreen.V342.Id.ThreadMessageId (Evergreen.V342.Message.Message Evergreen.V342.Id.ThreadMessageId (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) (LastTypedAt Evergreen.V342.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V342.Drawing.Drawing (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V342.IdArray.IdArray Evergreen.V342.Id.ThreadMessageId (Evergreen.V342.Message.Message Evergreen.V342.Id.ThreadMessageId (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId) (LastTypedAt Evergreen.V342.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V342.OneToOne.OneToOne (Evergreen.V342.Discord.Id Evergreen.V342.Discord.MessageId) (Evergreen.V342.Id.Id Evergreen.V342.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V342.Drawing.Drawing (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId))
    }
