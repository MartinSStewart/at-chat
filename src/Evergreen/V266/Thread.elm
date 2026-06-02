module Evergreen.V266.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V266.Discord
import Evergreen.V266.Id
import Evergreen.V266.Message
import Evergreen.V266.OneToOne
import Evergreen.V266.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V266.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V266.Message.MessageState Evergreen.V266.Id.ThreadMessageId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId))
    , visibleMessages : Evergreen.V266.VisibleMessages.VisibleMessages Evergreen.V266.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) (LastTypedAt Evergreen.V266.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V266.Message.MessageState Evergreen.V266.Id.ThreadMessageId (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId))
    , visibleMessages : Evergreen.V266.VisibleMessages.VisibleMessages Evergreen.V266.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (LastTypedAt Evergreen.V266.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V266.Message.Message Evergreen.V266.Id.ThreadMessageId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) (LastTypedAt Evergreen.V266.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V266.Message.Message Evergreen.V266.Id.ThreadMessageId (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (LastTypedAt Evergreen.V266.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V266.OneToOne.OneToOne (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ThreadMessageId)
    }
