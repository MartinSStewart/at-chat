module Evergreen.V144.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V144.Discord
import Evergreen.V144.Id
import Evergreen.V144.Message
import Evergreen.V144.OneToOne
import Evergreen.V144.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V144.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V144.Message.MessageState Evergreen.V144.Id.ThreadMessageId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId))
    , visibleMessages : Evergreen.V144.VisibleMessages.VisibleMessages Evergreen.V144.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) (LastTypedAt Evergreen.V144.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V144.Message.MessageState Evergreen.V144.Id.ThreadMessageId (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId))
    , visibleMessages : Evergreen.V144.VisibleMessages.VisibleMessages Evergreen.V144.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (LastTypedAt Evergreen.V144.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V144.Message.Message Evergreen.V144.Id.ThreadMessageId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) (LastTypedAt Evergreen.V144.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V144.Message.Message Evergreen.V144.Id.ThreadMessageId (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (LastTypedAt Evergreen.V144.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V144.OneToOne.OneToOne (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ThreadMessageId)
    }
