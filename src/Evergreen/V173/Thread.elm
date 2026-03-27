module Evergreen.V173.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V173.Discord
import Evergreen.V173.Id
import Evergreen.V173.Message
import Evergreen.V173.OneToOne
import Evergreen.V173.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V173.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V173.Message.MessageState Evergreen.V173.Id.ThreadMessageId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId))
    , visibleMessages : Evergreen.V173.VisibleMessages.VisibleMessages Evergreen.V173.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) (LastTypedAt Evergreen.V173.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V173.Message.MessageState Evergreen.V173.Id.ThreadMessageId (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId))
    , visibleMessages : Evergreen.V173.VisibleMessages.VisibleMessages Evergreen.V173.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (LastTypedAt Evergreen.V173.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V173.Message.Message Evergreen.V173.Id.ThreadMessageId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) (LastTypedAt Evergreen.V173.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V173.Message.Message Evergreen.V173.Id.ThreadMessageId (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (LastTypedAt Evergreen.V173.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V173.OneToOne.OneToOne (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ThreadMessageId)
    }
