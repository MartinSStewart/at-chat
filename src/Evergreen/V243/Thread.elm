module Evergreen.V243.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V243.Discord
import Evergreen.V243.Id
import Evergreen.V243.Message
import Evergreen.V243.OneToOne
import Evergreen.V243.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V243.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V243.Message.MessageState Evergreen.V243.Id.ThreadMessageId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId))
    , visibleMessages : Evergreen.V243.VisibleMessages.VisibleMessages Evergreen.V243.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) (LastTypedAt Evergreen.V243.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V243.Message.MessageState Evergreen.V243.Id.ThreadMessageId (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId))
    , visibleMessages : Evergreen.V243.VisibleMessages.VisibleMessages Evergreen.V243.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (LastTypedAt Evergreen.V243.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V243.Message.Message Evergreen.V243.Id.ThreadMessageId (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.Id.UserId) (LastTypedAt Evergreen.V243.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V243.Message.Message Evergreen.V243.Id.ThreadMessageId (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId) (LastTypedAt Evergreen.V243.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V243.OneToOne.OneToOne (Evergreen.V243.Discord.Id Evergreen.V243.Discord.MessageId) (Evergreen.V243.Id.Id Evergreen.V243.Id.ThreadMessageId)
    }
