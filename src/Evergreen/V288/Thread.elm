module Evergreen.V288.Thread exposing (..)

import Array
import Date
import Effect.Time
import Evergreen.V288.Discord
import Evergreen.V288.Drawing
import Evergreen.V288.Id
import Evergreen.V288.Message
import Evergreen.V288.OneToOne
import Evergreen.V288.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V288.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V288.Message.MessageState Evergreen.V288.Id.ThreadMessageId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))
    , visibleMessages : Evergreen.V288.VisibleMessages.VisibleMessages Evergreen.V288.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) (LastTypedAt Evergreen.V288.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V288.Drawing.Drawing (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V288.Message.MessageState Evergreen.V288.Id.ThreadMessageId (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))
    , visibleMessages : Evergreen.V288.VisibleMessages.VisibleMessages Evergreen.V288.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (LastTypedAt Evergreen.V288.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V288.Drawing.Drawing (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V288.Message.Message Evergreen.V288.Id.ThreadMessageId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) (LastTypedAt Evergreen.V288.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V288.Drawing.Drawing (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V288.Message.Message Evergreen.V288.Id.ThreadMessageId (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (LastTypedAt Evergreen.V288.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V288.OneToOne.OneToOne (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V288.Drawing.Drawing (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))
    }
