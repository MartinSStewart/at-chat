module Evergreen.V269.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V269.Discord
import Evergreen.V269.Id
import Evergreen.V269.Message
import Evergreen.V269.OneToOne
import Evergreen.V269.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V269.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V269.Message.MessageState Evergreen.V269.Id.ThreadMessageId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId))
    , visibleMessages : Evergreen.V269.VisibleMessages.VisibleMessages Evergreen.V269.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) (LastTypedAt Evergreen.V269.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V269.Message.MessageState Evergreen.V269.Id.ThreadMessageId (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId))
    , visibleMessages : Evergreen.V269.VisibleMessages.VisibleMessages Evergreen.V269.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (LastTypedAt Evergreen.V269.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V269.Message.Message Evergreen.V269.Id.ThreadMessageId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) (LastTypedAt Evergreen.V269.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V269.Message.Message Evergreen.V269.Id.ThreadMessageId (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (LastTypedAt Evergreen.V269.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V269.OneToOne.OneToOne (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ThreadMessageId)
    }
