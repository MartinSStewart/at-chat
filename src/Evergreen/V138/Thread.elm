module Evergreen.V138.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V138.Discord.Id
import Evergreen.V138.Id
import Evergreen.V138.Message
import Evergreen.V138.OneToOne
import Evergreen.V138.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V138.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V138.Message.MessageState Evergreen.V138.Id.ThreadMessageId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId))
    , visibleMessages : Evergreen.V138.VisibleMessages.VisibleMessages Evergreen.V138.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) (LastTypedAt Evergreen.V138.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V138.Message.MessageState Evergreen.V138.Id.ThreadMessageId (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId))
    , visibleMessages : Evergreen.V138.VisibleMessages.VisibleMessages Evergreen.V138.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (LastTypedAt Evergreen.V138.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V138.Message.Message Evergreen.V138.Id.ThreadMessageId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) (LastTypedAt Evergreen.V138.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V138.Message.Message Evergreen.V138.Id.ThreadMessageId (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (LastTypedAt Evergreen.V138.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V138.OneToOne.OneToOne (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ThreadMessageId)
    }
