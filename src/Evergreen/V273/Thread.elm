module Evergreen.V273.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V273.Discord
import Evergreen.V273.Id
import Evergreen.V273.Message
import Evergreen.V273.OneToOne
import Evergreen.V273.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V273.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V273.Message.MessageState Evergreen.V273.Id.ThreadMessageId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId))
    , visibleMessages : Evergreen.V273.VisibleMessages.VisibleMessages Evergreen.V273.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) (LastTypedAt Evergreen.V273.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V273.Message.MessageState Evergreen.V273.Id.ThreadMessageId (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId))
    , visibleMessages : Evergreen.V273.VisibleMessages.VisibleMessages Evergreen.V273.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (LastTypedAt Evergreen.V273.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V273.Message.Message Evergreen.V273.Id.ThreadMessageId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) (LastTypedAt Evergreen.V273.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V273.Message.Message Evergreen.V273.Id.ThreadMessageId (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (LastTypedAt Evergreen.V273.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V273.OneToOne.OneToOne (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ThreadMessageId)
    }
