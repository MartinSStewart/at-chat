module Evergreen.V385.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V385.Discord
import Evergreen.V385.Drawing
import Evergreen.V385.Id
import Evergreen.V385.IdArray
import Evergreen.V385.Message
import Evergreen.V385.MessageArray
import Evergreen.V385.OneToOne
import Evergreen.V385.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V385.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V385.MessageArray.MessageArray Evergreen.V385.Id.ThreadMessageId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    , visibleMessages : Evergreen.V385.VisibleMessages.VisibleMessages Evergreen.V385.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (LastTypedAt Evergreen.V385.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V385.Drawing.Drawing (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V385.MessageArray.MessageArray Evergreen.V385.Id.ThreadMessageId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
    , visibleMessages : Evergreen.V385.VisibleMessages.VisibleMessages Evergreen.V385.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (LastTypedAt Evergreen.V385.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V385.Drawing.Drawing (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V385.IdArray.IdArray Evergreen.V385.Id.ThreadMessageId (Evergreen.V385.Message.Message Evergreen.V385.Id.ThreadMessageId (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (LastTypedAt Evergreen.V385.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V385.Drawing.Drawing (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V385.IdArray.IdArray Evergreen.V385.Id.ThreadMessageId (Evergreen.V385.Message.Message Evergreen.V385.Id.ThreadMessageId (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId) (LastTypedAt Evergreen.V385.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V385.OneToOne.OneToOne (Evergreen.V385.Discord.Id Evergreen.V385.Discord.MessageId) (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V385.Drawing.Drawing (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId))
    }
