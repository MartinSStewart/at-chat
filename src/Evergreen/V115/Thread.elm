module Evergreen.V115.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V115.Discord.Id
import Evergreen.V115.Id
import Evergreen.V115.Message
import Evergreen.V115.OneToOne
import Evergreen.V115.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V115.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V115.Message.MessageState Evergreen.V115.Id.ThreadMessageId (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId))
    , visibleMessages : Evergreen.V115.VisibleMessages.VisibleMessages Evergreen.V115.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) (LastTypedAt Evergreen.V115.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V115.Message.MessageState Evergreen.V115.Id.ThreadMessageId (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))
    , visibleMessages : Evergreen.V115.VisibleMessages.VisibleMessages Evergreen.V115.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (LastTypedAt Evergreen.V115.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V115.Message.Message Evergreen.V115.Id.ThreadMessageId (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) (LastTypedAt Evergreen.V115.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V115.Message.Message Evergreen.V115.Id.ThreadMessageId (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (LastTypedAt Evergreen.V115.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V115.OneToOne.OneToOne (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ThreadMessageId)
    }
