module Evergreen.V167.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V167.Discord
import Evergreen.V167.Id
import Evergreen.V167.Message
import Evergreen.V167.OneToOne
import Evergreen.V167.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V167.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V167.Message.MessageState Evergreen.V167.Id.ThreadMessageId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId))
    , visibleMessages : Evergreen.V167.VisibleMessages.VisibleMessages Evergreen.V167.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) (LastTypedAt Evergreen.V167.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V167.Message.MessageState Evergreen.V167.Id.ThreadMessageId (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId))
    , visibleMessages : Evergreen.V167.VisibleMessages.VisibleMessages Evergreen.V167.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (LastTypedAt Evergreen.V167.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V167.Message.Message Evergreen.V167.Id.ThreadMessageId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) (LastTypedAt Evergreen.V167.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V167.Message.Message Evergreen.V167.Id.ThreadMessageId (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (LastTypedAt Evergreen.V167.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V167.OneToOne.OneToOne (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ThreadMessageId)
    }
