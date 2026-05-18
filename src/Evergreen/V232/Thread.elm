module Evergreen.V232.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V232.Discord
import Evergreen.V232.Id
import Evergreen.V232.Message
import Evergreen.V232.OneToOne
import Evergreen.V232.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V232.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V232.Message.MessageState Evergreen.V232.Id.ThreadMessageId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId))
    , visibleMessages : Evergreen.V232.VisibleMessages.VisibleMessages Evergreen.V232.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) (LastTypedAt Evergreen.V232.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V232.Message.MessageState Evergreen.V232.Id.ThreadMessageId (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId))
    , visibleMessages : Evergreen.V232.VisibleMessages.VisibleMessages Evergreen.V232.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (LastTypedAt Evergreen.V232.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V232.Message.Message Evergreen.V232.Id.ThreadMessageId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) (LastTypedAt Evergreen.V232.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V232.Message.Message Evergreen.V232.Id.ThreadMessageId (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (LastTypedAt Evergreen.V232.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V232.OneToOne.OneToOne (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ThreadMessageId)
    }
