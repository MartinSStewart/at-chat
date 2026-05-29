module Evergreen.V261.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V261.Discord
import Evergreen.V261.Id
import Evergreen.V261.Message
import Evergreen.V261.OneToOne
import Evergreen.V261.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V261.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V261.Message.MessageState Evergreen.V261.Id.ThreadMessageId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId))
    , visibleMessages : Evergreen.V261.VisibleMessages.VisibleMessages Evergreen.V261.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) (LastTypedAt Evergreen.V261.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V261.Message.MessageState Evergreen.V261.Id.ThreadMessageId (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId))
    , visibleMessages : Evergreen.V261.VisibleMessages.VisibleMessages Evergreen.V261.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (LastTypedAt Evergreen.V261.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V261.Message.Message Evergreen.V261.Id.ThreadMessageId (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.Id.UserId) (LastTypedAt Evergreen.V261.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V261.Message.Message Evergreen.V261.Id.ThreadMessageId (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId) (LastTypedAt Evergreen.V261.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V261.OneToOne.OneToOne (Evergreen.V261.Discord.Id Evergreen.V261.Discord.MessageId) (Evergreen.V261.Id.Id Evergreen.V261.Id.ThreadMessageId)
    }
