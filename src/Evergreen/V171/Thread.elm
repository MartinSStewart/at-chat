module Evergreen.V171.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V171.Discord
import Evergreen.V171.Id
import Evergreen.V171.Message
import Evergreen.V171.OneToOne
import Evergreen.V171.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V171.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V171.Message.MessageState Evergreen.V171.Id.ThreadMessageId (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId))
    , visibleMessages : Evergreen.V171.VisibleMessages.VisibleMessages Evergreen.V171.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) (LastTypedAt Evergreen.V171.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V171.Message.MessageState Evergreen.V171.Id.ThreadMessageId (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId))
    , visibleMessages : Evergreen.V171.VisibleMessages.VisibleMessages Evergreen.V171.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (LastTypedAt Evergreen.V171.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V171.Message.Message Evergreen.V171.Id.ThreadMessageId (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) (LastTypedAt Evergreen.V171.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V171.Message.Message Evergreen.V171.Id.ThreadMessageId (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (LastTypedAt Evergreen.V171.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V171.OneToOne.OneToOne (Evergreen.V171.Discord.Id Evergreen.V171.Discord.MessageId) (Evergreen.V171.Id.Id Evergreen.V171.Id.ThreadMessageId)
    }
