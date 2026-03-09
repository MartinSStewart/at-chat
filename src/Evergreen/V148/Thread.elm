module Evergreen.V148.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V148.Discord
import Evergreen.V148.Id
import Evergreen.V148.Message
import Evergreen.V148.OneToOne
import Evergreen.V148.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V148.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V148.Message.MessageState Evergreen.V148.Id.ThreadMessageId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId))
    , visibleMessages : Evergreen.V148.VisibleMessages.VisibleMessages Evergreen.V148.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) (LastTypedAt Evergreen.V148.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V148.Message.MessageState Evergreen.V148.Id.ThreadMessageId (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId))
    , visibleMessages : Evergreen.V148.VisibleMessages.VisibleMessages Evergreen.V148.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (LastTypedAt Evergreen.V148.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V148.Message.Message Evergreen.V148.Id.ThreadMessageId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) (LastTypedAt Evergreen.V148.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V148.Message.Message Evergreen.V148.Id.ThreadMessageId (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (LastTypedAt Evergreen.V148.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V148.OneToOne.OneToOne (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ThreadMessageId)
    }
