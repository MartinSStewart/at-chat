module Evergreen.V134.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V134.Discord.Id
import Evergreen.V134.Id
import Evergreen.V134.Message
import Evergreen.V134.OneToOne
import Evergreen.V134.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V134.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V134.Message.MessageState Evergreen.V134.Id.ThreadMessageId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId))
    , visibleMessages : Evergreen.V134.VisibleMessages.VisibleMessages Evergreen.V134.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (LastTypedAt Evergreen.V134.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V134.Message.MessageState Evergreen.V134.Id.ThreadMessageId (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId))
    , visibleMessages : Evergreen.V134.VisibleMessages.VisibleMessages Evergreen.V134.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (LastTypedAt Evergreen.V134.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V134.Message.Message Evergreen.V134.Id.ThreadMessageId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (LastTypedAt Evergreen.V134.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V134.Message.Message Evergreen.V134.Id.ThreadMessageId (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (LastTypedAt Evergreen.V134.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V134.OneToOne.OneToOne (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ThreadMessageId)
    }
