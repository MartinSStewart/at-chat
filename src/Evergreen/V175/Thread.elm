module Evergreen.V175.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V175.Discord
import Evergreen.V175.Id
import Evergreen.V175.Message
import Evergreen.V175.OneToOne
import Evergreen.V175.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V175.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V175.Message.MessageState Evergreen.V175.Id.ThreadMessageId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId))
    , visibleMessages : Evergreen.V175.VisibleMessages.VisibleMessages Evergreen.V175.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) (LastTypedAt Evergreen.V175.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V175.Message.MessageState Evergreen.V175.Id.ThreadMessageId (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId))
    , visibleMessages : Evergreen.V175.VisibleMessages.VisibleMessages Evergreen.V175.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (LastTypedAt Evergreen.V175.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V175.Message.Message Evergreen.V175.Id.ThreadMessageId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) (LastTypedAt Evergreen.V175.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V175.Message.Message Evergreen.V175.Id.ThreadMessageId (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (LastTypedAt Evergreen.V175.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V175.OneToOne.OneToOne (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ThreadMessageId)
    }
