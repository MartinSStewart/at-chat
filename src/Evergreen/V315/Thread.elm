module Evergreen.V315.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V315.Discord
import Evergreen.V315.Drawing
import Evergreen.V315.Id
import Evergreen.V315.IdArray
import Evergreen.V315.Message
import Evergreen.V315.OneToOne
import Evergreen.V315.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V315.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V315.IdArray.IdArray Evergreen.V315.Id.ThreadMessageId (Evergreen.V315.Message.MessageState Evergreen.V315.Id.ThreadMessageId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))
    , visibleMessages : Evergreen.V315.VisibleMessages.VisibleMessages Evergreen.V315.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) (LastTypedAt Evergreen.V315.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V315.Drawing.Drawing (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V315.IdArray.IdArray Evergreen.V315.Id.ThreadMessageId (Evergreen.V315.Message.MessageState Evergreen.V315.Id.ThreadMessageId (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))
    , visibleMessages : Evergreen.V315.VisibleMessages.VisibleMessages Evergreen.V315.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (LastTypedAt Evergreen.V315.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V315.Drawing.Drawing (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V315.IdArray.IdArray Evergreen.V315.Id.ThreadMessageId (Evergreen.V315.Message.Message Evergreen.V315.Id.ThreadMessageId (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) (LastTypedAt Evergreen.V315.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V315.Drawing.Drawing (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V315.IdArray.IdArray Evergreen.V315.Id.ThreadMessageId (Evergreen.V315.Message.Message Evergreen.V315.Id.ThreadMessageId (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId) (LastTypedAt Evergreen.V315.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V315.OneToOne.OneToOne (Evergreen.V315.Discord.Id Evergreen.V315.Discord.MessageId) (Evergreen.V315.Id.Id Evergreen.V315.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V315.Drawing.Drawing (Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId))
    }
