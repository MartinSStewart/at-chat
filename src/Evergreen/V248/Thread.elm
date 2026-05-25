module Evergreen.V248.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V248.Discord
import Evergreen.V248.Id
import Evergreen.V248.Message
import Evergreen.V248.OneToOne
import Evergreen.V248.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V248.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V248.Message.MessageState Evergreen.V248.Id.ThreadMessageId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId))
    , visibleMessages : Evergreen.V248.VisibleMessages.VisibleMessages Evergreen.V248.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) (LastTypedAt Evergreen.V248.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V248.Message.MessageState Evergreen.V248.Id.ThreadMessageId (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId))
    , visibleMessages : Evergreen.V248.VisibleMessages.VisibleMessages Evergreen.V248.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (LastTypedAt Evergreen.V248.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V248.Message.Message Evergreen.V248.Id.ThreadMessageId (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.Id.UserId) (LastTypedAt Evergreen.V248.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V248.Message.Message Evergreen.V248.Id.ThreadMessageId (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId) (LastTypedAt Evergreen.V248.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V248.OneToOne.OneToOne (Evergreen.V248.Discord.Id Evergreen.V248.Discord.MessageId) (Evergreen.V248.Id.Id Evergreen.V248.Id.ThreadMessageId)
    }
