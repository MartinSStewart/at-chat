module Evergreen.V206.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V206.Discord
import Evergreen.V206.Id
import Evergreen.V206.Message
import Evergreen.V206.OneToOne
import Evergreen.V206.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V206.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V206.Message.MessageState Evergreen.V206.Id.ThreadMessageId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))
    , visibleMessages : Evergreen.V206.VisibleMessages.VisibleMessages Evergreen.V206.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) (LastTypedAt Evergreen.V206.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V206.Message.MessageState Evergreen.V206.Id.ThreadMessageId (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId))
    , visibleMessages : Evergreen.V206.VisibleMessages.VisibleMessages Evergreen.V206.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (LastTypedAt Evergreen.V206.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V206.Message.Message Evergreen.V206.Id.ThreadMessageId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) (LastTypedAt Evergreen.V206.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V206.Message.Message Evergreen.V206.Id.ThreadMessageId (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (LastTypedAt Evergreen.V206.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V206.OneToOne.OneToOne (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ThreadMessageId)
    }
