module Evergreen.V149.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V149.Discord
import Evergreen.V149.Id
import Evergreen.V149.Message
import Evergreen.V149.OneToOne
import Evergreen.V149.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V149.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V149.Message.MessageState Evergreen.V149.Id.ThreadMessageId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId))
    , visibleMessages : Evergreen.V149.VisibleMessages.VisibleMessages Evergreen.V149.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) (LastTypedAt Evergreen.V149.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V149.Message.MessageState Evergreen.V149.Id.ThreadMessageId (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId))
    , visibleMessages : Evergreen.V149.VisibleMessages.VisibleMessages Evergreen.V149.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (LastTypedAt Evergreen.V149.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V149.Message.Message Evergreen.V149.Id.ThreadMessageId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) (LastTypedAt Evergreen.V149.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V149.Message.Message Evergreen.V149.Id.ThreadMessageId (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (LastTypedAt Evergreen.V149.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V149.OneToOne.OneToOne (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ThreadMessageId)
    }
