module Evergreen.V384.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V384.Discord
import Evergreen.V384.Drawing
import Evergreen.V384.Id
import Evergreen.V384.IdArray
import Evergreen.V384.Message
import Evergreen.V384.MessageArray
import Evergreen.V384.OneToOne
import Evergreen.V384.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V384.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V384.MessageArray.MessageArray Evergreen.V384.Id.ThreadMessageId (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    , visibleMessages : Evergreen.V384.VisibleMessages.VisibleMessages Evergreen.V384.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (LastTypedAt Evergreen.V384.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V384.Drawing.Drawing (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V384.MessageArray.MessageArray Evergreen.V384.Id.ThreadMessageId (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
    , visibleMessages : Evergreen.V384.VisibleMessages.VisibleMessages Evergreen.V384.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (LastTypedAt Evergreen.V384.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V384.Drawing.Drawing (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V384.IdArray.IdArray Evergreen.V384.Id.ThreadMessageId (Evergreen.V384.Message.Message Evergreen.V384.Id.ThreadMessageId (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) (LastTypedAt Evergreen.V384.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V384.Drawing.Drawing (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V384.IdArray.IdArray Evergreen.V384.Id.ThreadMessageId (Evergreen.V384.Message.Message Evergreen.V384.Id.ThreadMessageId (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId) (LastTypedAt Evergreen.V384.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V384.OneToOne.OneToOne (Evergreen.V384.Discord.Id Evergreen.V384.Discord.MessageId) (Evergreen.V384.Id.Id Evergreen.V384.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V384.Drawing.Drawing (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId))
    }
