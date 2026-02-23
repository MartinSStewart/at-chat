module Evergreen.V120.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V120.Discord.Id
import Evergreen.V120.Id
import Evergreen.V120.Message
import Evergreen.V120.OneToOne
import Evergreen.V120.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V120.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V120.Message.MessageState Evergreen.V120.Id.ThreadMessageId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId))
    , visibleMessages : Evergreen.V120.VisibleMessages.VisibleMessages Evergreen.V120.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) (LastTypedAt Evergreen.V120.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V120.Message.MessageState Evergreen.V120.Id.ThreadMessageId (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId))
    , visibleMessages : Evergreen.V120.VisibleMessages.VisibleMessages Evergreen.V120.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (LastTypedAt Evergreen.V120.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V120.Message.Message Evergreen.V120.Id.ThreadMessageId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) (LastTypedAt Evergreen.V120.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V120.Message.Message Evergreen.V120.Id.ThreadMessageId (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (LastTypedAt Evergreen.V120.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V120.OneToOne.OneToOne (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ThreadMessageId)
    }
