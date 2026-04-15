module Evergreen.V201.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V201.Discord
import Evergreen.V201.Id
import Evergreen.V201.Message
import Evergreen.V201.OneToOne
import Evergreen.V201.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V201.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V201.Message.MessageState Evergreen.V201.Id.ThreadMessageId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))
    , visibleMessages : Evergreen.V201.VisibleMessages.VisibleMessages Evergreen.V201.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) (LastTypedAt Evergreen.V201.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V201.Message.MessageState Evergreen.V201.Id.ThreadMessageId (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId))
    , visibleMessages : Evergreen.V201.VisibleMessages.VisibleMessages Evergreen.V201.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (LastTypedAt Evergreen.V201.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V201.Message.Message Evergreen.V201.Id.ThreadMessageId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) (LastTypedAt Evergreen.V201.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V201.Message.Message Evergreen.V201.Id.ThreadMessageId (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (LastTypedAt Evergreen.V201.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V201.OneToOne.OneToOne (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ThreadMessageId)
    }
