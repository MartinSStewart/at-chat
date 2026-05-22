module Evergreen.V247.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V247.Discord
import Evergreen.V247.Id
import Evergreen.V247.Message
import Evergreen.V247.OneToOne
import Evergreen.V247.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V247.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V247.Message.MessageState Evergreen.V247.Id.ThreadMessageId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId))
    , visibleMessages : Evergreen.V247.VisibleMessages.VisibleMessages Evergreen.V247.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) (LastTypedAt Evergreen.V247.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V247.Message.MessageState Evergreen.V247.Id.ThreadMessageId (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId))
    , visibleMessages : Evergreen.V247.VisibleMessages.VisibleMessages Evergreen.V247.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (LastTypedAt Evergreen.V247.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V247.Message.Message Evergreen.V247.Id.ThreadMessageId (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) (LastTypedAt Evergreen.V247.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V247.Message.Message Evergreen.V247.Id.ThreadMessageId (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V247.Discord.Id Evergreen.V247.Discord.UserId) (LastTypedAt Evergreen.V247.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V247.OneToOne.OneToOne (Evergreen.V247.Discord.Id Evergreen.V247.Discord.MessageId) (Evergreen.V247.Id.Id Evergreen.V247.Id.ThreadMessageId)
    }
