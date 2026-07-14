module Evergreen.V319.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V319.Discord
import Evergreen.V319.Drawing
import Evergreen.V319.Id
import Evergreen.V319.IdArray
import Evergreen.V319.Message
import Evergreen.V319.OneToOne
import Evergreen.V319.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V319.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V319.IdArray.IdArray Evergreen.V319.Id.ThreadMessageId (Evergreen.V319.Message.MessageState Evergreen.V319.Id.ThreadMessageId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))
    , visibleMessages : Evergreen.V319.VisibleMessages.VisibleMessages Evergreen.V319.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) (LastTypedAt Evergreen.V319.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V319.Drawing.Drawing (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V319.IdArray.IdArray Evergreen.V319.Id.ThreadMessageId (Evergreen.V319.Message.MessageState Evergreen.V319.Id.ThreadMessageId (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))
    , visibleMessages : Evergreen.V319.VisibleMessages.VisibleMessages Evergreen.V319.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (LastTypedAt Evergreen.V319.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V319.Drawing.Drawing (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V319.IdArray.IdArray Evergreen.V319.Id.ThreadMessageId (Evergreen.V319.Message.Message Evergreen.V319.Id.ThreadMessageId (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId) (LastTypedAt Evergreen.V319.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V319.Drawing.Drawing (Evergreen.V319.Id.Id Evergreen.V319.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V319.IdArray.IdArray Evergreen.V319.Id.ThreadMessageId (Evergreen.V319.Message.Message Evergreen.V319.Id.ThreadMessageId (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId) (LastTypedAt Evergreen.V319.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V319.OneToOne.OneToOne (Evergreen.V319.Discord.Id Evergreen.V319.Discord.MessageId) (Evergreen.V319.Id.Id Evergreen.V319.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V319.Drawing.Drawing (Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId))
    }
