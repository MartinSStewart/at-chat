module Evergreen.V257.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V257.Discord
import Evergreen.V257.Id
import Evergreen.V257.Message
import Evergreen.V257.OneToOne
import Evergreen.V257.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V257.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V257.Message.MessageState Evergreen.V257.Id.ThreadMessageId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId))
    , visibleMessages : Evergreen.V257.VisibleMessages.VisibleMessages Evergreen.V257.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) (LastTypedAt Evergreen.V257.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V257.Message.MessageState Evergreen.V257.Id.ThreadMessageId (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId))
    , visibleMessages : Evergreen.V257.VisibleMessages.VisibleMessages Evergreen.V257.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (LastTypedAt Evergreen.V257.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V257.Message.Message Evergreen.V257.Id.ThreadMessageId (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.Id.UserId) (LastTypedAt Evergreen.V257.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V257.Message.Message Evergreen.V257.Id.ThreadMessageId (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId) (LastTypedAt Evergreen.V257.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V257.OneToOne.OneToOne (Evergreen.V257.Discord.Id Evergreen.V257.Discord.MessageId) (Evergreen.V257.Id.Id Evergreen.V257.Id.ThreadMessageId)
    }
