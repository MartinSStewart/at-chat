module Evergreen.V184.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V184.Discord
import Evergreen.V184.Id
import Evergreen.V184.Message
import Evergreen.V184.OneToOne
import Evergreen.V184.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V184.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V184.Message.MessageState Evergreen.V184.Id.ThreadMessageId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId))
    , visibleMessages : Evergreen.V184.VisibleMessages.VisibleMessages Evergreen.V184.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) (LastTypedAt Evergreen.V184.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V184.Message.MessageState Evergreen.V184.Id.ThreadMessageId (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId))
    , visibleMessages : Evergreen.V184.VisibleMessages.VisibleMessages Evergreen.V184.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (LastTypedAt Evergreen.V184.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V184.Message.Message Evergreen.V184.Id.ThreadMessageId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) (LastTypedAt Evergreen.V184.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V184.Message.Message Evergreen.V184.Id.ThreadMessageId (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (LastTypedAt Evergreen.V184.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V184.OneToOne.OneToOne (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ThreadMessageId)
    }
