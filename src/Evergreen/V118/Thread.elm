module Evergreen.V118.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V118.Discord.Id
import Evergreen.V118.Id
import Evergreen.V118.Message
import Evergreen.V118.OneToOne
import Evergreen.V118.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V118.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V118.Message.MessageState Evergreen.V118.Id.ThreadMessageId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId))
    , visibleMessages : Evergreen.V118.VisibleMessages.VisibleMessages Evergreen.V118.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) (LastTypedAt Evergreen.V118.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V118.Message.MessageState Evergreen.V118.Id.ThreadMessageId (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId))
    , visibleMessages : Evergreen.V118.VisibleMessages.VisibleMessages Evergreen.V118.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (LastTypedAt Evergreen.V118.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V118.Message.Message Evergreen.V118.Id.ThreadMessageId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) (LastTypedAt Evergreen.V118.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V118.Message.Message Evergreen.V118.Id.ThreadMessageId (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (LastTypedAt Evergreen.V118.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V118.OneToOne.OneToOne (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ThreadMessageId)
    }
