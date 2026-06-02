module Evergreen.V267.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V267.Discord
import Evergreen.V267.Id
import Evergreen.V267.Message
import Evergreen.V267.OneToOne
import Evergreen.V267.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V267.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V267.Message.MessageState Evergreen.V267.Id.ThreadMessageId (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId))
    , visibleMessages : Evergreen.V267.VisibleMessages.VisibleMessages Evergreen.V267.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) (LastTypedAt Evergreen.V267.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V267.Message.MessageState Evergreen.V267.Id.ThreadMessageId (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId))
    , visibleMessages : Evergreen.V267.VisibleMessages.VisibleMessages Evergreen.V267.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (LastTypedAt Evergreen.V267.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V267.Message.Message Evergreen.V267.Id.ThreadMessageId (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) (LastTypedAt Evergreen.V267.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V267.Message.Message Evergreen.V267.Id.ThreadMessageId (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (LastTypedAt Evergreen.V267.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V267.OneToOne.OneToOne (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ThreadMessageId)
    }
