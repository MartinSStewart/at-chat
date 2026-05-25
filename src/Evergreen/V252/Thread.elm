module Evergreen.V252.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V252.Discord
import Evergreen.V252.Id
import Evergreen.V252.Message
import Evergreen.V252.OneToOne
import Evergreen.V252.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V252.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V252.Message.MessageState Evergreen.V252.Id.ThreadMessageId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId))
    , visibleMessages : Evergreen.V252.VisibleMessages.VisibleMessages Evergreen.V252.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) (LastTypedAt Evergreen.V252.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V252.Message.MessageState Evergreen.V252.Id.ThreadMessageId (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId))
    , visibleMessages : Evergreen.V252.VisibleMessages.VisibleMessages Evergreen.V252.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (LastTypedAt Evergreen.V252.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V252.Message.Message Evergreen.V252.Id.ThreadMessageId (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) (LastTypedAt Evergreen.V252.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V252.Message.Message Evergreen.V252.Id.ThreadMessageId (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId) (LastTypedAt Evergreen.V252.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V252.OneToOne.OneToOne (Evergreen.V252.Discord.Id Evergreen.V252.Discord.MessageId) (Evergreen.V252.Id.Id Evergreen.V252.Id.ThreadMessageId)
    }
