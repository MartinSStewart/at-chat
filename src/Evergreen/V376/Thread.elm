module Evergreen.V376.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V376.Discord
import Evergreen.V376.Drawing
import Evergreen.V376.Id
import Evergreen.V376.IdArray
import Evergreen.V376.Message
import Evergreen.V376.MessageArray
import Evergreen.V376.OneToOne
import Evergreen.V376.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V376.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V376.MessageArray.MessageArray Evergreen.V376.Id.ThreadMessageId (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    , visibleMessages : Evergreen.V376.VisibleMessages.VisibleMessages Evergreen.V376.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (LastTypedAt Evergreen.V376.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V376.Drawing.Drawing (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V376.MessageArray.MessageArray Evergreen.V376.Id.ThreadMessageId (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
    , visibleMessages : Evergreen.V376.VisibleMessages.VisibleMessages Evergreen.V376.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (LastTypedAt Evergreen.V376.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V376.Drawing.Drawing (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V376.IdArray.IdArray Evergreen.V376.Id.ThreadMessageId (Evergreen.V376.Message.Message Evergreen.V376.Id.ThreadMessageId (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) (LastTypedAt Evergreen.V376.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V376.Drawing.Drawing (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V376.IdArray.IdArray Evergreen.V376.Id.ThreadMessageId (Evergreen.V376.Message.Message Evergreen.V376.Id.ThreadMessageId (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId) (LastTypedAt Evergreen.V376.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V376.OneToOne.OneToOne (Evergreen.V376.Discord.Id Evergreen.V376.Discord.MessageId) (Evergreen.V376.Id.Id Evergreen.V376.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V376.Drawing.Drawing (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId))
    }
