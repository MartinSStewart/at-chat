module Evergreen.V263.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V263.Discord
import Evergreen.V263.Id
import Evergreen.V263.Message
import Evergreen.V263.OneToOne
import Evergreen.V263.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V263.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V263.Message.MessageState Evergreen.V263.Id.ThreadMessageId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId))
    , visibleMessages : Evergreen.V263.VisibleMessages.VisibleMessages Evergreen.V263.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) (LastTypedAt Evergreen.V263.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V263.Message.MessageState Evergreen.V263.Id.ThreadMessageId (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId))
    , visibleMessages : Evergreen.V263.VisibleMessages.VisibleMessages Evergreen.V263.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (LastTypedAt Evergreen.V263.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V263.Message.Message Evergreen.V263.Id.ThreadMessageId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) (LastTypedAt Evergreen.V263.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V263.Message.Message Evergreen.V263.Id.ThreadMessageId (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (LastTypedAt Evergreen.V263.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V263.OneToOne.OneToOne (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ThreadMessageId)
    }
