module Evergreen.V183.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V183.Discord
import Evergreen.V183.Id
import Evergreen.V183.Message
import Evergreen.V183.OneToOne
import Evergreen.V183.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V183.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V183.Message.MessageState Evergreen.V183.Id.ThreadMessageId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId))
    , visibleMessages : Evergreen.V183.VisibleMessages.VisibleMessages Evergreen.V183.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) (LastTypedAt Evergreen.V183.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V183.Message.MessageState Evergreen.V183.Id.ThreadMessageId (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId))
    , visibleMessages : Evergreen.V183.VisibleMessages.VisibleMessages Evergreen.V183.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (LastTypedAt Evergreen.V183.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V183.Message.Message Evergreen.V183.Id.ThreadMessageId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) (LastTypedAt Evergreen.V183.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V183.Message.Message Evergreen.V183.Id.ThreadMessageId (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (LastTypedAt Evergreen.V183.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V183.OneToOne.OneToOne (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ThreadMessageId)
    }
