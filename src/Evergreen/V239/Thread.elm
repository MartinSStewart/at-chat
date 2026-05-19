module Evergreen.V239.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V239.Discord
import Evergreen.V239.Id
import Evergreen.V239.Message
import Evergreen.V239.OneToOne
import Evergreen.V239.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V239.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V239.Message.MessageState Evergreen.V239.Id.ThreadMessageId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId))
    , visibleMessages : Evergreen.V239.VisibleMessages.VisibleMessages Evergreen.V239.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) (LastTypedAt Evergreen.V239.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V239.Message.MessageState Evergreen.V239.Id.ThreadMessageId (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId))
    , visibleMessages : Evergreen.V239.VisibleMessages.VisibleMessages Evergreen.V239.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (LastTypedAt Evergreen.V239.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V239.Message.Message Evergreen.V239.Id.ThreadMessageId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) (LastTypedAt Evergreen.V239.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V239.Message.Message Evergreen.V239.Id.ThreadMessageId (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (LastTypedAt Evergreen.V239.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V239.OneToOne.OneToOne (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ThreadMessageId)
    }
