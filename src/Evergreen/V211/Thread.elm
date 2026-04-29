module Evergreen.V211.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V211.Discord
import Evergreen.V211.Id
import Evergreen.V211.Message
import Evergreen.V211.OneToOne
import Evergreen.V211.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V211.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V211.Message.MessageState Evergreen.V211.Id.ThreadMessageId (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId))
    , visibleMessages : Evergreen.V211.VisibleMessages.VisibleMessages Evergreen.V211.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) (LastTypedAt Evergreen.V211.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V211.Message.MessageState Evergreen.V211.Id.ThreadMessageId (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId))
    , visibleMessages : Evergreen.V211.VisibleMessages.VisibleMessages Evergreen.V211.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (LastTypedAt Evergreen.V211.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V211.Message.Message Evergreen.V211.Id.ThreadMessageId (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) (LastTypedAt Evergreen.V211.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V211.Message.Message Evergreen.V211.Id.ThreadMessageId (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (LastTypedAt Evergreen.V211.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V211.OneToOne.OneToOne (Evergreen.V211.Discord.Id Evergreen.V211.Discord.MessageId) (Evergreen.V211.Id.Id Evergreen.V211.Id.ThreadMessageId)
    }
