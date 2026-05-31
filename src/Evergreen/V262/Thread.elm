module Evergreen.V262.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V262.Discord
import Evergreen.V262.Id
import Evergreen.V262.Message
import Evergreen.V262.OneToOne
import Evergreen.V262.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V262.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V262.Message.MessageState Evergreen.V262.Id.ThreadMessageId (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId))
    , visibleMessages : Evergreen.V262.VisibleMessages.VisibleMessages Evergreen.V262.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) (LastTypedAt Evergreen.V262.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V262.Message.MessageState Evergreen.V262.Id.ThreadMessageId (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId))
    , visibleMessages : Evergreen.V262.VisibleMessages.VisibleMessages Evergreen.V262.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (LastTypedAt Evergreen.V262.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V262.Message.Message Evergreen.V262.Id.ThreadMessageId (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) (LastTypedAt Evergreen.V262.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V262.Message.Message Evergreen.V262.Id.ThreadMessageId (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (LastTypedAt Evergreen.V262.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V262.OneToOne.OneToOne (Evergreen.V262.Discord.Id Evergreen.V262.Discord.MessageId) (Evergreen.V262.Id.Id Evergreen.V262.Id.ThreadMessageId)
    }
