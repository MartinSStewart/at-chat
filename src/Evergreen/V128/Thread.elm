module Evergreen.V128.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V128.Discord.Id
import Evergreen.V128.Id
import Evergreen.V128.Message
import Evergreen.V128.OneToOne
import Evergreen.V128.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V128.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V128.Message.MessageState Evergreen.V128.Id.ThreadMessageId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId))
    , visibleMessages : Evergreen.V128.VisibleMessages.VisibleMessages Evergreen.V128.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) (LastTypedAt Evergreen.V128.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V128.Message.MessageState Evergreen.V128.Id.ThreadMessageId (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId))
    , visibleMessages : Evergreen.V128.VisibleMessages.VisibleMessages Evergreen.V128.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (LastTypedAt Evergreen.V128.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V128.Message.Message Evergreen.V128.Id.ThreadMessageId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) (LastTypedAt Evergreen.V128.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V128.Message.Message Evergreen.V128.Id.ThreadMessageId (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (LastTypedAt Evergreen.V128.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V128.OneToOne.OneToOne (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ThreadMessageId)
    }
