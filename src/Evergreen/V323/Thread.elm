module Evergreen.V323.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V323.Discord
import Evergreen.V323.Drawing
import Evergreen.V323.Id
import Evergreen.V323.IdArray
import Evergreen.V323.Message
import Evergreen.V323.OneToOne
import Evergreen.V323.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V323.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V323.IdArray.IdArray Evergreen.V323.Id.ThreadMessageId (Evergreen.V323.Message.MessageState Evergreen.V323.Id.ThreadMessageId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))
    , visibleMessages : Evergreen.V323.VisibleMessages.VisibleMessages Evergreen.V323.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) (LastTypedAt Evergreen.V323.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V323.Drawing.Drawing (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V323.IdArray.IdArray Evergreen.V323.Id.ThreadMessageId (Evergreen.V323.Message.MessageState Evergreen.V323.Id.ThreadMessageId (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))
    , visibleMessages : Evergreen.V323.VisibleMessages.VisibleMessages Evergreen.V323.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (LastTypedAt Evergreen.V323.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V323.Drawing.Drawing (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V323.IdArray.IdArray Evergreen.V323.Id.ThreadMessageId (Evergreen.V323.Message.Message Evergreen.V323.Id.ThreadMessageId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) (LastTypedAt Evergreen.V323.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V323.Drawing.Drawing (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V323.IdArray.IdArray Evergreen.V323.Id.ThreadMessageId (Evergreen.V323.Message.Message Evergreen.V323.Id.ThreadMessageId (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (LastTypedAt Evergreen.V323.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V323.OneToOne.OneToOne (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V323.Drawing.Drawing (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))
    }
