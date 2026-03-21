module Evergreen.V163.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V163.Discord
import Evergreen.V163.Id
import Evergreen.V163.Message
import Evergreen.V163.OneToOne
import Evergreen.V163.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V163.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V163.Message.MessageState Evergreen.V163.Id.ThreadMessageId (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId))
    , visibleMessages : Evergreen.V163.VisibleMessages.VisibleMessages Evergreen.V163.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) (LastTypedAt Evergreen.V163.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V163.Message.MessageState Evergreen.V163.Id.ThreadMessageId (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId))
    , visibleMessages : Evergreen.V163.VisibleMessages.VisibleMessages Evergreen.V163.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (LastTypedAt Evergreen.V163.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V163.Message.Message Evergreen.V163.Id.ThreadMessageId (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) (LastTypedAt Evergreen.V163.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V163.Message.Message Evergreen.V163.Id.ThreadMessageId (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (LastTypedAt Evergreen.V163.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V163.OneToOne.OneToOne (Evergreen.V163.Discord.Id Evergreen.V163.Discord.MessageId) (Evergreen.V163.Id.Id Evergreen.V163.Id.ThreadMessageId)
    }
