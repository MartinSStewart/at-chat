module Evergreen.V213.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V213.Discord
import Evergreen.V213.Id
import Evergreen.V213.Message
import Evergreen.V213.OneToOne
import Evergreen.V213.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V213.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V213.Message.MessageState Evergreen.V213.Id.ThreadMessageId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId))
    , visibleMessages : Evergreen.V213.VisibleMessages.VisibleMessages Evergreen.V213.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) (LastTypedAt Evergreen.V213.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V213.Message.MessageState Evergreen.V213.Id.ThreadMessageId (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId))
    , visibleMessages : Evergreen.V213.VisibleMessages.VisibleMessages Evergreen.V213.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (LastTypedAt Evergreen.V213.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V213.Message.Message Evergreen.V213.Id.ThreadMessageId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) (LastTypedAt Evergreen.V213.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V213.Message.Message Evergreen.V213.Id.ThreadMessageId (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (LastTypedAt Evergreen.V213.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V213.OneToOne.OneToOne (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ThreadMessageId)
    }
