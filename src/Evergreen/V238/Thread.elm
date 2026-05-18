module Evergreen.V238.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V238.Discord
import Evergreen.V238.Id
import Evergreen.V238.Message
import Evergreen.V238.OneToOne
import Evergreen.V238.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V238.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V238.Message.MessageState Evergreen.V238.Id.ThreadMessageId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId))
    , visibleMessages : Evergreen.V238.VisibleMessages.VisibleMessages Evergreen.V238.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) (LastTypedAt Evergreen.V238.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V238.Message.MessageState Evergreen.V238.Id.ThreadMessageId (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId))
    , visibleMessages : Evergreen.V238.VisibleMessages.VisibleMessages Evergreen.V238.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (LastTypedAt Evergreen.V238.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V238.Message.Message Evergreen.V238.Id.ThreadMessageId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) (LastTypedAt Evergreen.V238.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V238.Message.Message Evergreen.V238.Id.ThreadMessageId (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (LastTypedAt Evergreen.V238.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V238.OneToOne.OneToOne (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ThreadMessageId)
    }
