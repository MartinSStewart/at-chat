module Evergreen.V217.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V217.Discord
import Evergreen.V217.Id
import Evergreen.V217.Message
import Evergreen.V217.OneToOne
import Evergreen.V217.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V217.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V217.Message.MessageState Evergreen.V217.Id.ThreadMessageId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId))
    , visibleMessages : Evergreen.V217.VisibleMessages.VisibleMessages Evergreen.V217.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) (LastTypedAt Evergreen.V217.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V217.Message.MessageState Evergreen.V217.Id.ThreadMessageId (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId))
    , visibleMessages : Evergreen.V217.VisibleMessages.VisibleMessages Evergreen.V217.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (LastTypedAt Evergreen.V217.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V217.Message.Message Evergreen.V217.Id.ThreadMessageId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) (LastTypedAt Evergreen.V217.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V217.Message.Message Evergreen.V217.Id.ThreadMessageId (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (LastTypedAt Evergreen.V217.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V217.OneToOne.OneToOne (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ThreadMessageId)
    }
