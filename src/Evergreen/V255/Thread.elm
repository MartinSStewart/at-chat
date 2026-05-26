module Evergreen.V255.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V255.Discord
import Evergreen.V255.Id
import Evergreen.V255.Message
import Evergreen.V255.OneToOne
import Evergreen.V255.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V255.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V255.Message.MessageState Evergreen.V255.Id.ThreadMessageId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId))
    , visibleMessages : Evergreen.V255.VisibleMessages.VisibleMessages Evergreen.V255.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) (LastTypedAt Evergreen.V255.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V255.Message.MessageState Evergreen.V255.Id.ThreadMessageId (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId))
    , visibleMessages : Evergreen.V255.VisibleMessages.VisibleMessages Evergreen.V255.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (LastTypedAt Evergreen.V255.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V255.Message.Message Evergreen.V255.Id.ThreadMessageId (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) (LastTypedAt Evergreen.V255.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V255.Message.Message Evergreen.V255.Id.ThreadMessageId (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId) (LastTypedAt Evergreen.V255.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V255.OneToOne.OneToOne (Evergreen.V255.Discord.Id Evergreen.V255.Discord.MessageId) (Evergreen.V255.Id.Id Evergreen.V255.Id.ThreadMessageId)
    }
