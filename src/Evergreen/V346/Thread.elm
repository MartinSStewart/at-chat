module Evergreen.V346.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V346.Discord
import Evergreen.V346.Drawing
import Evergreen.V346.Id
import Evergreen.V346.IdArray
import Evergreen.V346.Message
import Evergreen.V346.MessageArray
import Evergreen.V346.OneToOne
import Evergreen.V346.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V346.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V346.MessageArray.MessageArray Evergreen.V346.Id.ThreadMessageId (Evergreen.V346.Message.Message Evergreen.V346.Id.ThreadMessageId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))
    , visibleMessages : Evergreen.V346.VisibleMessages.VisibleMessages Evergreen.V346.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (LastTypedAt Evergreen.V346.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V346.Drawing.Drawing (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V346.MessageArray.MessageArray Evergreen.V346.Id.ThreadMessageId (Evergreen.V346.Message.Message Evergreen.V346.Id.ThreadMessageId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))
    , visibleMessages : Evergreen.V346.VisibleMessages.VisibleMessages Evergreen.V346.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (LastTypedAt Evergreen.V346.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V346.Drawing.Drawing (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V346.IdArray.IdArray Evergreen.V346.Id.ThreadMessageId (Evergreen.V346.Message.Message Evergreen.V346.Id.ThreadMessageId (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) (LastTypedAt Evergreen.V346.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V346.Drawing.Drawing (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V346.IdArray.IdArray Evergreen.V346.Id.ThreadMessageId (Evergreen.V346.Message.Message Evergreen.V346.Id.ThreadMessageId (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId) (LastTypedAt Evergreen.V346.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V346.OneToOne.OneToOne (Evergreen.V346.Discord.Id Evergreen.V346.Discord.MessageId) (Evergreen.V346.Id.Id Evergreen.V346.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V346.Drawing.Drawing (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId))
    }
