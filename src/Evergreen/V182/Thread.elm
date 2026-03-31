module Evergreen.V182.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V182.Discord
import Evergreen.V182.Id
import Evergreen.V182.Message
import Evergreen.V182.OneToOne
import Evergreen.V182.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V182.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V182.Message.MessageState Evergreen.V182.Id.ThreadMessageId (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId))
    , visibleMessages : Evergreen.V182.VisibleMessages.VisibleMessages Evergreen.V182.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) (LastTypedAt Evergreen.V182.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V182.Message.MessageState Evergreen.V182.Id.ThreadMessageId (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId))
    , visibleMessages : Evergreen.V182.VisibleMessages.VisibleMessages Evergreen.V182.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (LastTypedAt Evergreen.V182.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V182.Message.Message Evergreen.V182.Id.ThreadMessageId (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) (LastTypedAt Evergreen.V182.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V182.Message.Message Evergreen.V182.Id.ThreadMessageId (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (LastTypedAt Evergreen.V182.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V182.OneToOne.OneToOne (Evergreen.V182.Discord.Id Evergreen.V182.Discord.MessageId) (Evergreen.V182.Id.Id Evergreen.V182.Id.ThreadMessageId)
    }
