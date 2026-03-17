module Evergreen.V157.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V157.Discord
import Evergreen.V157.Id
import Evergreen.V157.Message
import Evergreen.V157.OneToOne
import Evergreen.V157.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V157.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V157.Message.MessageState Evergreen.V157.Id.ThreadMessageId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId))
    , visibleMessages : Evergreen.V157.VisibleMessages.VisibleMessages Evergreen.V157.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) (LastTypedAt Evergreen.V157.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V157.Message.MessageState Evergreen.V157.Id.ThreadMessageId (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId))
    , visibleMessages : Evergreen.V157.VisibleMessages.VisibleMessages Evergreen.V157.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (LastTypedAt Evergreen.V157.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V157.Message.Message Evergreen.V157.Id.ThreadMessageId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) (LastTypedAt Evergreen.V157.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V157.Message.Message Evergreen.V157.Id.ThreadMessageId (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (LastTypedAt Evergreen.V157.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V157.OneToOne.OneToOne (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ThreadMessageId)
    }
