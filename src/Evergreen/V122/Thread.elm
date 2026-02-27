module Evergreen.V122.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V122.Discord.Id
import Evergreen.V122.Id
import Evergreen.V122.Message
import Evergreen.V122.OneToOne
import Evergreen.V122.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V122.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V122.Message.MessageState Evergreen.V122.Id.ThreadMessageId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId))
    , visibleMessages : Evergreen.V122.VisibleMessages.VisibleMessages Evergreen.V122.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) (LastTypedAt Evergreen.V122.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V122.Message.MessageState Evergreen.V122.Id.ThreadMessageId (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId))
    , visibleMessages : Evergreen.V122.VisibleMessages.VisibleMessages Evergreen.V122.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (LastTypedAt Evergreen.V122.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V122.Message.Message Evergreen.V122.Id.ThreadMessageId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) (LastTypedAt Evergreen.V122.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V122.Message.Message Evergreen.V122.Id.ThreadMessageId (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (LastTypedAt Evergreen.V122.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V122.OneToOne.OneToOne (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ThreadMessageId)
    }
