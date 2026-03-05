module Evergreen.V135.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V135.Discord.Id
import Evergreen.V135.Id
import Evergreen.V135.Message
import Evergreen.V135.OneToOne
import Evergreen.V135.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V135.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V135.Message.MessageState Evergreen.V135.Id.ThreadMessageId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId))
    , visibleMessages : Evergreen.V135.VisibleMessages.VisibleMessages Evergreen.V135.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) (LastTypedAt Evergreen.V135.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V135.Message.MessageState Evergreen.V135.Id.ThreadMessageId (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId))
    , visibleMessages : Evergreen.V135.VisibleMessages.VisibleMessages Evergreen.V135.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (LastTypedAt Evergreen.V135.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V135.Message.Message Evergreen.V135.Id.ThreadMessageId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) (LastTypedAt Evergreen.V135.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V135.Message.Message Evergreen.V135.Id.ThreadMessageId (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (LastTypedAt Evergreen.V135.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V135.OneToOne.OneToOne (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ThreadMessageId)
    }
