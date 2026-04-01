module Evergreen.V185.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V185.Discord
import Evergreen.V185.Id
import Evergreen.V185.Message
import Evergreen.V185.OneToOne
import Evergreen.V185.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V185.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V185.Message.MessageState Evergreen.V185.Id.ThreadMessageId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId))
    , visibleMessages : Evergreen.V185.VisibleMessages.VisibleMessages Evergreen.V185.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) (LastTypedAt Evergreen.V185.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V185.Message.MessageState Evergreen.V185.Id.ThreadMessageId (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId))
    , visibleMessages : Evergreen.V185.VisibleMessages.VisibleMessages Evergreen.V185.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (LastTypedAt Evergreen.V185.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V185.Message.Message Evergreen.V185.Id.ThreadMessageId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) (LastTypedAt Evergreen.V185.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V185.Message.Message Evergreen.V185.Id.ThreadMessageId (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (LastTypedAt Evergreen.V185.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V185.OneToOne.OneToOne (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ThreadMessageId)
    }
