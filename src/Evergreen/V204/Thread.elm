module Evergreen.V204.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V204.Discord
import Evergreen.V204.Id
import Evergreen.V204.Message
import Evergreen.V204.OneToOne
import Evergreen.V204.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V204.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V204.Message.MessageState Evergreen.V204.Id.ThreadMessageId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))
    , visibleMessages : Evergreen.V204.VisibleMessages.VisibleMessages Evergreen.V204.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) (LastTypedAt Evergreen.V204.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V204.Message.MessageState Evergreen.V204.Id.ThreadMessageId (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId))
    , visibleMessages : Evergreen.V204.VisibleMessages.VisibleMessages Evergreen.V204.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (LastTypedAt Evergreen.V204.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V204.Message.Message Evergreen.V204.Id.ThreadMessageId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) (LastTypedAt Evergreen.V204.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V204.Message.Message Evergreen.V204.Id.ThreadMessageId (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (LastTypedAt Evergreen.V204.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V204.OneToOne.OneToOne (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ThreadMessageId)
    }
