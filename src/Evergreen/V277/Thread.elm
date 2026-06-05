module Evergreen.V277.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V277.Discord
import Evergreen.V277.Id
import Evergreen.V277.Message
import Evergreen.V277.OneToOne
import Evergreen.V277.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V277.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V277.Message.MessageState Evergreen.V277.Id.ThreadMessageId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId))
    , visibleMessages : Evergreen.V277.VisibleMessages.VisibleMessages Evergreen.V277.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) (LastTypedAt Evergreen.V277.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V277.Message.MessageState Evergreen.V277.Id.ThreadMessageId (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId))
    , visibleMessages : Evergreen.V277.VisibleMessages.VisibleMessages Evergreen.V277.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (LastTypedAt Evergreen.V277.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V277.Message.Message Evergreen.V277.Id.ThreadMessageId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) (LastTypedAt Evergreen.V277.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V277.Message.Message Evergreen.V277.Id.ThreadMessageId (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (LastTypedAt Evergreen.V277.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V277.OneToOne.OneToOne (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ThreadMessageId)
    }
