module Evergreen.V341.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V341.Discord
import Evergreen.V341.Drawing
import Evergreen.V341.Id
import Evergreen.V341.IdArray
import Evergreen.V341.Message
import Evergreen.V341.MessageArray
import Evergreen.V341.OneToOne
import Evergreen.V341.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V341.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V341.MessageArray.MessageArray Evergreen.V341.Id.ThreadMessageId (Evergreen.V341.Message.Message Evergreen.V341.Id.ThreadMessageId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))
    , visibleMessages : Evergreen.V341.VisibleMessages.VisibleMessages Evergreen.V341.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (LastTypedAt Evergreen.V341.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V341.Drawing.Drawing (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V341.MessageArray.MessageArray Evergreen.V341.Id.ThreadMessageId (Evergreen.V341.Message.Message Evergreen.V341.Id.ThreadMessageId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))
    , visibleMessages : Evergreen.V341.VisibleMessages.VisibleMessages Evergreen.V341.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (LastTypedAt Evergreen.V341.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V341.Drawing.Drawing (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V341.IdArray.IdArray Evergreen.V341.Id.ThreadMessageId (Evergreen.V341.Message.Message Evergreen.V341.Id.ThreadMessageId (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) (LastTypedAt Evergreen.V341.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V341.Drawing.Drawing (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V341.IdArray.IdArray Evergreen.V341.Id.ThreadMessageId (Evergreen.V341.Message.Message Evergreen.V341.Id.ThreadMessageId (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId) (LastTypedAt Evergreen.V341.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V341.OneToOne.OneToOne (Evergreen.V341.Discord.Id Evergreen.V341.Discord.MessageId) (Evergreen.V341.Id.Id Evergreen.V341.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V341.Drawing.Drawing (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId))
    }
