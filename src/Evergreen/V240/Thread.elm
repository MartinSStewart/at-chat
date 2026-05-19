module Evergreen.V240.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V240.Discord
import Evergreen.V240.Id
import Evergreen.V240.Message
import Evergreen.V240.OneToOne
import Evergreen.V240.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V240.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V240.Message.MessageState Evergreen.V240.Id.ThreadMessageId (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId))
    , visibleMessages : Evergreen.V240.VisibleMessages.VisibleMessages Evergreen.V240.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) (LastTypedAt Evergreen.V240.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V240.Message.MessageState Evergreen.V240.Id.ThreadMessageId (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId))
    , visibleMessages : Evergreen.V240.VisibleMessages.VisibleMessages Evergreen.V240.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (LastTypedAt Evergreen.V240.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V240.Message.Message Evergreen.V240.Id.ThreadMessageId (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) (LastTypedAt Evergreen.V240.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V240.Message.Message Evergreen.V240.Id.ThreadMessageId (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (LastTypedAt Evergreen.V240.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V240.OneToOne.OneToOne (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ThreadMessageId)
    }
