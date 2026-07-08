module Evergreen.V307.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V307.Discord
import Evergreen.V307.Drawing
import Evergreen.V307.Id
import Evergreen.V307.IdArray
import Evergreen.V307.Message
import Evergreen.V307.OneToOne
import Evergreen.V307.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V307.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V307.IdArray.IdArray Evergreen.V307.Id.ThreadMessageId (Evergreen.V307.Message.MessageState Evergreen.V307.Id.ThreadMessageId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))
    , visibleMessages : Evergreen.V307.VisibleMessages.VisibleMessages Evergreen.V307.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) (LastTypedAt Evergreen.V307.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V307.Drawing.Drawing (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V307.IdArray.IdArray Evergreen.V307.Id.ThreadMessageId (Evergreen.V307.Message.MessageState Evergreen.V307.Id.ThreadMessageId (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))
    , visibleMessages : Evergreen.V307.VisibleMessages.VisibleMessages Evergreen.V307.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (LastTypedAt Evergreen.V307.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V307.Drawing.Drawing (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V307.IdArray.IdArray Evergreen.V307.Id.ThreadMessageId (Evergreen.V307.Message.Message Evergreen.V307.Id.ThreadMessageId (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId) (LastTypedAt Evergreen.V307.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V307.Drawing.Drawing (Evergreen.V307.Id.Id Evergreen.V307.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V307.IdArray.IdArray Evergreen.V307.Id.ThreadMessageId (Evergreen.V307.Message.Message Evergreen.V307.Id.ThreadMessageId (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId) (LastTypedAt Evergreen.V307.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V307.OneToOne.OneToOne (Evergreen.V307.Discord.Id Evergreen.V307.Discord.MessageId) (Evergreen.V307.Id.Id Evergreen.V307.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V307.Drawing.Drawing (Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId))
    }
