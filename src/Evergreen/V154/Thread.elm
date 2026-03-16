module Evergreen.V154.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V154.Discord
import Evergreen.V154.Id
import Evergreen.V154.Message
import Evergreen.V154.OneToOne
import Evergreen.V154.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V154.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V154.Message.MessageState Evergreen.V154.Id.ThreadMessageId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId))
    , visibleMessages : Evergreen.V154.VisibleMessages.VisibleMessages Evergreen.V154.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) (LastTypedAt Evergreen.V154.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V154.Message.MessageState Evergreen.V154.Id.ThreadMessageId (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId))
    , visibleMessages : Evergreen.V154.VisibleMessages.VisibleMessages Evergreen.V154.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (LastTypedAt Evergreen.V154.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V154.Message.Message Evergreen.V154.Id.ThreadMessageId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) (LastTypedAt Evergreen.V154.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V154.Message.Message Evergreen.V154.Id.ThreadMessageId (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (LastTypedAt Evergreen.V154.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V154.OneToOne.OneToOne (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ThreadMessageId)
    }
