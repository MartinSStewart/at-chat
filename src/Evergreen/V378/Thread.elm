module Evergreen.V378.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V378.Discord
import Evergreen.V378.Drawing
import Evergreen.V378.Id
import Evergreen.V378.IdArray
import Evergreen.V378.Message
import Evergreen.V378.MessageArray
import Evergreen.V378.OneToOne
import Evergreen.V378.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V378.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V378.MessageArray.MessageArray Evergreen.V378.Id.ThreadMessageId (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    , visibleMessages : Evergreen.V378.VisibleMessages.VisibleMessages Evergreen.V378.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (LastTypedAt Evergreen.V378.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V378.Drawing.Drawing (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V378.MessageArray.MessageArray Evergreen.V378.Id.ThreadMessageId (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
    , visibleMessages : Evergreen.V378.VisibleMessages.VisibleMessages Evergreen.V378.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (LastTypedAt Evergreen.V378.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V378.Drawing.Drawing (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V378.IdArray.IdArray Evergreen.V378.Id.ThreadMessageId (Evergreen.V378.Message.Message Evergreen.V378.Id.ThreadMessageId (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) (LastTypedAt Evergreen.V378.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V378.Drawing.Drawing (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V378.IdArray.IdArray Evergreen.V378.Id.ThreadMessageId (Evergreen.V378.Message.Message Evergreen.V378.Id.ThreadMessageId (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId) (LastTypedAt Evergreen.V378.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V378.OneToOne.OneToOne (Evergreen.V378.Discord.Id Evergreen.V378.Discord.MessageId) (Evergreen.V378.Id.Id Evergreen.V378.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V378.Drawing.Drawing (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId))
    }
