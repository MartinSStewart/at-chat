module Evergreen.V181.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V181.Discord
import Evergreen.V181.Id
import Evergreen.V181.Message
import Evergreen.V181.OneToOne
import Evergreen.V181.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V181.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V181.Message.MessageState Evergreen.V181.Id.ThreadMessageId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId))
    , visibleMessages : Evergreen.V181.VisibleMessages.VisibleMessages Evergreen.V181.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) (LastTypedAt Evergreen.V181.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V181.Message.MessageState Evergreen.V181.Id.ThreadMessageId (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId))
    , visibleMessages : Evergreen.V181.VisibleMessages.VisibleMessages Evergreen.V181.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (LastTypedAt Evergreen.V181.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V181.Message.Message Evergreen.V181.Id.ThreadMessageId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) (LastTypedAt Evergreen.V181.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V181.Message.Message Evergreen.V181.Id.ThreadMessageId (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (LastTypedAt Evergreen.V181.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V181.OneToOne.OneToOne (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ThreadMessageId)
    }
