module Evergreen.V199.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V199.Discord
import Evergreen.V199.Id
import Evergreen.V199.Message
import Evergreen.V199.OneToOne
import Evergreen.V199.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V199.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V199.Message.MessageState Evergreen.V199.Id.ThreadMessageId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))
    , visibleMessages : Evergreen.V199.VisibleMessages.VisibleMessages Evergreen.V199.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) (LastTypedAt Evergreen.V199.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V199.Message.MessageState Evergreen.V199.Id.ThreadMessageId (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId))
    , visibleMessages : Evergreen.V199.VisibleMessages.VisibleMessages Evergreen.V199.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (LastTypedAt Evergreen.V199.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V199.Message.Message Evergreen.V199.Id.ThreadMessageId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) (LastTypedAt Evergreen.V199.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V199.Message.Message Evergreen.V199.Id.ThreadMessageId (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (LastTypedAt Evergreen.V199.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V199.OneToOne.OneToOne (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ThreadMessageId)
    }
