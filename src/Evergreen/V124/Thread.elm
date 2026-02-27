module Evergreen.V124.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V124.Discord.Id
import Evergreen.V124.Id
import Evergreen.V124.Message
import Evergreen.V124.OneToOne
import Evergreen.V124.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V124.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V124.Message.MessageState Evergreen.V124.Id.ThreadMessageId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId))
    , visibleMessages : Evergreen.V124.VisibleMessages.VisibleMessages Evergreen.V124.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (LastTypedAt Evergreen.V124.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V124.Message.MessageState Evergreen.V124.Id.ThreadMessageId (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId))
    , visibleMessages : Evergreen.V124.VisibleMessages.VisibleMessages Evergreen.V124.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (LastTypedAt Evergreen.V124.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V124.Message.Message Evergreen.V124.Id.ThreadMessageId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (LastTypedAt Evergreen.V124.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V124.Message.Message Evergreen.V124.Id.ThreadMessageId (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (LastTypedAt Evergreen.V124.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V124.OneToOne.OneToOne (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ThreadMessageId)
    }
