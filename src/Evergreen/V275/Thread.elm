module Evergreen.V275.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V275.Discord
import Evergreen.V275.Id
import Evergreen.V275.Message
import Evergreen.V275.OneToOne
import Evergreen.V275.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V275.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V275.Message.MessageState Evergreen.V275.Id.ThreadMessageId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId))
    , visibleMessages : Evergreen.V275.VisibleMessages.VisibleMessages Evergreen.V275.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) (LastTypedAt Evergreen.V275.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V275.Message.MessageState Evergreen.V275.Id.ThreadMessageId (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId))
    , visibleMessages : Evergreen.V275.VisibleMessages.VisibleMessages Evergreen.V275.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (LastTypedAt Evergreen.V275.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V275.Message.Message Evergreen.V275.Id.ThreadMessageId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) (LastTypedAt Evergreen.V275.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V275.Message.Message Evergreen.V275.Id.ThreadMessageId (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (LastTypedAt Evergreen.V275.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V275.OneToOne.OneToOne (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ThreadMessageId)
    }
