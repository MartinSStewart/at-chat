module Evergreen.V179.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V179.Discord
import Evergreen.V179.Id
import Evergreen.V179.Message
import Evergreen.V179.OneToOne
import Evergreen.V179.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V179.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V179.Message.MessageState Evergreen.V179.Id.ThreadMessageId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId))
    , visibleMessages : Evergreen.V179.VisibleMessages.VisibleMessages Evergreen.V179.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) (LastTypedAt Evergreen.V179.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V179.Message.MessageState Evergreen.V179.Id.ThreadMessageId (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId))
    , visibleMessages : Evergreen.V179.VisibleMessages.VisibleMessages Evergreen.V179.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (LastTypedAt Evergreen.V179.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V179.Message.Message Evergreen.V179.Id.ThreadMessageId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) (LastTypedAt Evergreen.V179.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V179.Message.Message Evergreen.V179.Id.ThreadMessageId (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (LastTypedAt Evergreen.V179.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V179.OneToOne.OneToOne (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ThreadMessageId)
    }
