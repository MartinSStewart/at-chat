module Evergreen.V253.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V253.Discord
import Evergreen.V253.Id
import Evergreen.V253.Message
import Evergreen.V253.OneToOne
import Evergreen.V253.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V253.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V253.Message.MessageState Evergreen.V253.Id.ThreadMessageId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId))
    , visibleMessages : Evergreen.V253.VisibleMessages.VisibleMessages Evergreen.V253.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) (LastTypedAt Evergreen.V253.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V253.Message.MessageState Evergreen.V253.Id.ThreadMessageId (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId))
    , visibleMessages : Evergreen.V253.VisibleMessages.VisibleMessages Evergreen.V253.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (LastTypedAt Evergreen.V253.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V253.Message.Message Evergreen.V253.Id.ThreadMessageId (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) (LastTypedAt Evergreen.V253.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V253.Message.Message Evergreen.V253.Id.ThreadMessageId (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId) (LastTypedAt Evergreen.V253.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V253.OneToOne.OneToOne (Evergreen.V253.Discord.Id Evergreen.V253.Discord.MessageId) (Evergreen.V253.Id.Id Evergreen.V253.Id.ThreadMessageId)
    }
