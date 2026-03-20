module Evergreen.V161.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V161.Discord
import Evergreen.V161.Id
import Evergreen.V161.Message
import Evergreen.V161.OneToOne
import Evergreen.V161.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V161.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V161.Message.MessageState Evergreen.V161.Id.ThreadMessageId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId))
    , visibleMessages : Evergreen.V161.VisibleMessages.VisibleMessages Evergreen.V161.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) (LastTypedAt Evergreen.V161.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V161.Message.MessageState Evergreen.V161.Id.ThreadMessageId (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId))
    , visibleMessages : Evergreen.V161.VisibleMessages.VisibleMessages Evergreen.V161.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (LastTypedAt Evergreen.V161.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V161.Message.Message Evergreen.V161.Id.ThreadMessageId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) (LastTypedAt Evergreen.V161.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V161.Message.Message Evergreen.V161.Id.ThreadMessageId (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (LastTypedAt Evergreen.V161.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V161.OneToOne.OneToOne (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ThreadMessageId)
    }
