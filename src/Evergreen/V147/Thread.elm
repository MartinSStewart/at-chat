module Evergreen.V147.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V147.Discord
import Evergreen.V147.Id
import Evergreen.V147.Message
import Evergreen.V147.OneToOne
import Evergreen.V147.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V147.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V147.Message.MessageState Evergreen.V147.Id.ThreadMessageId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId))
    , visibleMessages : Evergreen.V147.VisibleMessages.VisibleMessages Evergreen.V147.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) (LastTypedAt Evergreen.V147.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V147.Message.MessageState Evergreen.V147.Id.ThreadMessageId (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId))
    , visibleMessages : Evergreen.V147.VisibleMessages.VisibleMessages Evergreen.V147.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (LastTypedAt Evergreen.V147.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V147.Message.Message Evergreen.V147.Id.ThreadMessageId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) (LastTypedAt Evergreen.V147.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V147.Message.Message Evergreen.V147.Id.ThreadMessageId (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (LastTypedAt Evergreen.V147.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V147.OneToOne.OneToOne (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ThreadMessageId)
    }
