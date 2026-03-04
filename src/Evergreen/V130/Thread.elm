module Evergreen.V130.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V130.Discord.Id
import Evergreen.V130.Id
import Evergreen.V130.Message
import Evergreen.V130.OneToOne
import Evergreen.V130.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V130.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V130.Message.MessageState Evergreen.V130.Id.ThreadMessageId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId))
    , visibleMessages : Evergreen.V130.VisibleMessages.VisibleMessages Evergreen.V130.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) (LastTypedAt Evergreen.V130.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V130.Message.MessageState Evergreen.V130.Id.ThreadMessageId (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId))
    , visibleMessages : Evergreen.V130.VisibleMessages.VisibleMessages Evergreen.V130.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (LastTypedAt Evergreen.V130.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V130.Message.Message Evergreen.V130.Id.ThreadMessageId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) (LastTypedAt Evergreen.V130.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V130.Message.Message Evergreen.V130.Id.ThreadMessageId (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (LastTypedAt Evergreen.V130.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V130.OneToOne.OneToOne (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ThreadMessageId)
    }
