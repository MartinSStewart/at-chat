module Evergreen.V119.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V119.Discord.Id
import Evergreen.V119.Id
import Evergreen.V119.Message
import Evergreen.V119.OneToOne
import Evergreen.V119.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V119.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V119.Message.MessageState Evergreen.V119.Id.ThreadMessageId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId))
    , visibleMessages : Evergreen.V119.VisibleMessages.VisibleMessages Evergreen.V119.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) (LastTypedAt Evergreen.V119.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V119.Message.MessageState Evergreen.V119.Id.ThreadMessageId (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId))
    , visibleMessages : Evergreen.V119.VisibleMessages.VisibleMessages Evergreen.V119.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (LastTypedAt Evergreen.V119.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V119.Message.Message Evergreen.V119.Id.ThreadMessageId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) (LastTypedAt Evergreen.V119.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V119.Message.Message Evergreen.V119.Id.ThreadMessageId (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (LastTypedAt Evergreen.V119.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V119.OneToOne.OneToOne (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ThreadMessageId)
    }
