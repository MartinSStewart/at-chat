module Evergreen.V192.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V192.Discord
import Evergreen.V192.Id
import Evergreen.V192.Message
import Evergreen.V192.OneToOne
import Evergreen.V192.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V192.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V192.Message.MessageState Evergreen.V192.Id.ThreadMessageId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))
    , visibleMessages : Evergreen.V192.VisibleMessages.VisibleMessages Evergreen.V192.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) (LastTypedAt Evergreen.V192.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V192.Message.MessageState Evergreen.V192.Id.ThreadMessageId (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId))
    , visibleMessages : Evergreen.V192.VisibleMessages.VisibleMessages Evergreen.V192.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (LastTypedAt Evergreen.V192.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V192.Message.Message Evergreen.V192.Id.ThreadMessageId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) (LastTypedAt Evergreen.V192.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V192.Message.Message Evergreen.V192.Id.ThreadMessageId (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (LastTypedAt Evergreen.V192.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V192.OneToOne.OneToOne (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ThreadMessageId)
    }
