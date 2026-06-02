module Evergreen.V264.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V264.Discord
import Evergreen.V264.Id
import Evergreen.V264.Message
import Evergreen.V264.OneToOne
import Evergreen.V264.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V264.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V264.Message.MessageState Evergreen.V264.Id.ThreadMessageId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId))
    , visibleMessages : Evergreen.V264.VisibleMessages.VisibleMessages Evergreen.V264.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) (LastTypedAt Evergreen.V264.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V264.Message.MessageState Evergreen.V264.Id.ThreadMessageId (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId))
    , visibleMessages : Evergreen.V264.VisibleMessages.VisibleMessages Evergreen.V264.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (LastTypedAt Evergreen.V264.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V264.Message.Message Evergreen.V264.Id.ThreadMessageId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) (LastTypedAt Evergreen.V264.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V264.Message.Message Evergreen.V264.Id.ThreadMessageId (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (LastTypedAt Evergreen.V264.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V264.OneToOne.OneToOne (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ThreadMessageId)
    }
