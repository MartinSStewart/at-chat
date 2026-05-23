module Evergreen.V250.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V250.Discord
import Evergreen.V250.Id
import Evergreen.V250.Message
import Evergreen.V250.OneToOne
import Evergreen.V250.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V250.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V250.Message.MessageState Evergreen.V250.Id.ThreadMessageId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId))
    , visibleMessages : Evergreen.V250.VisibleMessages.VisibleMessages Evergreen.V250.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) (LastTypedAt Evergreen.V250.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V250.Message.MessageState Evergreen.V250.Id.ThreadMessageId (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId))
    , visibleMessages : Evergreen.V250.VisibleMessages.VisibleMessages Evergreen.V250.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (LastTypedAt Evergreen.V250.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V250.Message.Message Evergreen.V250.Id.ThreadMessageId (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) (LastTypedAt Evergreen.V250.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V250.Message.Message Evergreen.V250.Id.ThreadMessageId (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V250.Discord.Id Evergreen.V250.Discord.UserId) (LastTypedAt Evergreen.V250.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V250.OneToOne.OneToOne (Evergreen.V250.Discord.Id Evergreen.V250.Discord.MessageId) (Evergreen.V250.Id.Id Evergreen.V250.Id.ThreadMessageId)
    }
