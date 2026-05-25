module Evergreen.V254.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V254.Discord
import Evergreen.V254.Id
import Evergreen.V254.Message
import Evergreen.V254.OneToOne
import Evergreen.V254.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V254.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V254.Message.MessageState Evergreen.V254.Id.ThreadMessageId (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId))
    , visibleMessages : Evergreen.V254.VisibleMessages.VisibleMessages Evergreen.V254.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) (LastTypedAt Evergreen.V254.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V254.Message.MessageState Evergreen.V254.Id.ThreadMessageId (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId))
    , visibleMessages : Evergreen.V254.VisibleMessages.VisibleMessages Evergreen.V254.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (LastTypedAt Evergreen.V254.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V254.Message.Message Evergreen.V254.Id.ThreadMessageId (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) (LastTypedAt Evergreen.V254.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V254.Message.Message Evergreen.V254.Id.ThreadMessageId (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId) (LastTypedAt Evergreen.V254.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V254.OneToOne.OneToOne (Evergreen.V254.Discord.Id Evergreen.V254.Discord.MessageId) (Evergreen.V254.Id.Id Evergreen.V254.Id.ThreadMessageId)
    }
