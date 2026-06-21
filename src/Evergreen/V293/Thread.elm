module Evergreen.V293.Thread exposing (..)

import Array
import Date
import Effect.Time
import Evergreen.V293.Discord
import Evergreen.V293.Drawing
import Evergreen.V293.Id
import Evergreen.V293.Message
import Evergreen.V293.OneToOne
import Evergreen.V293.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V293.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V293.Message.MessageState Evergreen.V293.Id.ThreadMessageId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))
    , visibleMessages : Evergreen.V293.VisibleMessages.VisibleMessages Evergreen.V293.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) (LastTypedAt Evergreen.V293.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V293.Drawing.Drawing (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V293.Message.MessageState Evergreen.V293.Id.ThreadMessageId (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))
    , visibleMessages : Evergreen.V293.VisibleMessages.VisibleMessages Evergreen.V293.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (LastTypedAt Evergreen.V293.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V293.Drawing.Drawing (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V293.Message.Message Evergreen.V293.Id.ThreadMessageId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) (LastTypedAt Evergreen.V293.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V293.Drawing.Drawing (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V293.Message.Message Evergreen.V293.Id.ThreadMessageId (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (LastTypedAt Evergreen.V293.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V293.OneToOne.OneToOne (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V293.Drawing.Drawing (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))
    }
