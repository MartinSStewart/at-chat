module Evergreen.V137.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V137.Discord.Id
import Evergreen.V137.Id
import Evergreen.V137.Message
import Evergreen.V137.OneToOne
import Evergreen.V137.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V137.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V137.Message.MessageState Evergreen.V137.Id.ThreadMessageId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId))
    , visibleMessages : Evergreen.V137.VisibleMessages.VisibleMessages Evergreen.V137.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) (LastTypedAt Evergreen.V137.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V137.Message.MessageState Evergreen.V137.Id.ThreadMessageId (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId))
    , visibleMessages : Evergreen.V137.VisibleMessages.VisibleMessages Evergreen.V137.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (LastTypedAt Evergreen.V137.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V137.Message.Message Evergreen.V137.Id.ThreadMessageId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) (LastTypedAt Evergreen.V137.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V137.Message.Message Evergreen.V137.Id.ThreadMessageId (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (LastTypedAt Evergreen.V137.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V137.OneToOne.OneToOne (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ThreadMessageId)
    }
