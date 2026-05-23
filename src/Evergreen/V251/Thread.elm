module Evergreen.V251.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V251.Discord
import Evergreen.V251.Id
import Evergreen.V251.Message
import Evergreen.V251.OneToOne
import Evergreen.V251.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V251.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V251.Message.MessageState Evergreen.V251.Id.ThreadMessageId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId))
    , visibleMessages : Evergreen.V251.VisibleMessages.VisibleMessages Evergreen.V251.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) (LastTypedAt Evergreen.V251.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V251.Message.MessageState Evergreen.V251.Id.ThreadMessageId (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId))
    , visibleMessages : Evergreen.V251.VisibleMessages.VisibleMessages Evergreen.V251.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (LastTypedAt Evergreen.V251.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V251.Message.Message Evergreen.V251.Id.ThreadMessageId (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) (LastTypedAt Evergreen.V251.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V251.Message.Message Evergreen.V251.Id.ThreadMessageId (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V251.Discord.Id Evergreen.V251.Discord.UserId) (LastTypedAt Evergreen.V251.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V251.OneToOne.OneToOne (Evergreen.V251.Discord.Id Evergreen.V251.Discord.MessageId) (Evergreen.V251.Id.Id Evergreen.V251.Id.ThreadMessageId)
    }
