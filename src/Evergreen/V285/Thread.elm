module Evergreen.V285.Thread exposing (..)

import Array
import Date
import Effect.Time
import Evergreen.V285.Discord
import Evergreen.V285.Drawing
import Evergreen.V285.Id
import Evergreen.V285.Message
import Evergreen.V285.OneToOne
import Evergreen.V285.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V285.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V285.Message.MessageState Evergreen.V285.Id.ThreadMessageId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))
    , visibleMessages : Evergreen.V285.VisibleMessages.VisibleMessages Evergreen.V285.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) (LastTypedAt Evergreen.V285.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V285.Drawing.Drawing (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V285.Message.MessageState Evergreen.V285.Id.ThreadMessageId (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))
    , visibleMessages : Evergreen.V285.VisibleMessages.VisibleMessages Evergreen.V285.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (LastTypedAt Evergreen.V285.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V285.Drawing.Drawing (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V285.Message.Message Evergreen.V285.Id.ThreadMessageId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) (LastTypedAt Evergreen.V285.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V285.Drawing.Drawing (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V285.Message.Message Evergreen.V285.Id.ThreadMessageId (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (LastTypedAt Evergreen.V285.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V285.OneToOne.OneToOne (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V285.Drawing.Drawing (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))
    }
