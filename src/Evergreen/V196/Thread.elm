module Evergreen.V196.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V196.Discord
import Evergreen.V196.Id
import Evergreen.V196.Message
import Evergreen.V196.OneToOne
import Evergreen.V196.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V196.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V196.Message.MessageState Evergreen.V196.Id.ThreadMessageId (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId))
    , visibleMessages : Evergreen.V196.VisibleMessages.VisibleMessages Evergreen.V196.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) (LastTypedAt Evergreen.V196.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V196.Message.MessageState Evergreen.V196.Id.ThreadMessageId (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId))
    , visibleMessages : Evergreen.V196.VisibleMessages.VisibleMessages Evergreen.V196.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (LastTypedAt Evergreen.V196.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V196.Message.Message Evergreen.V196.Id.ThreadMessageId (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) (LastTypedAt Evergreen.V196.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V196.Message.Message Evergreen.V196.Id.ThreadMessageId (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (LastTypedAt Evergreen.V196.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V196.OneToOne.OneToOne (Evergreen.V196.Discord.Id Evergreen.V196.Discord.MessageId) (Evergreen.V196.Id.Id Evergreen.V196.Id.ThreadMessageId)
    }
