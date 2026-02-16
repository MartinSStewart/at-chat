module Evergreen.V112.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V112.Discord.Id
import Evergreen.V112.Id
import Evergreen.V112.Message
import Evergreen.V112.OneToOne
import Evergreen.V112.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V112.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V112.Message.MessageState Evergreen.V112.Id.ThreadMessageId (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId))
    , visibleMessages : Evergreen.V112.VisibleMessages.VisibleMessages Evergreen.V112.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) (LastTypedAt Evergreen.V112.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V112.Message.MessageState Evergreen.V112.Id.ThreadMessageId (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId))
    , visibleMessages : Evergreen.V112.VisibleMessages.VisibleMessages Evergreen.V112.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (LastTypedAt Evergreen.V112.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V112.Message.Message Evergreen.V112.Id.ThreadMessageId (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) (LastTypedAt Evergreen.V112.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V112.Message.Message Evergreen.V112.Id.ThreadMessageId (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (LastTypedAt Evergreen.V112.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V112.OneToOne.OneToOne (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ThreadMessageId)
    }
