module Evergreen.V223.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V223.Discord
import Evergreen.V223.Id
import Evergreen.V223.Message
import Evergreen.V223.OneToOne
import Evergreen.V223.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V223.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V223.Message.MessageState Evergreen.V223.Id.ThreadMessageId (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId))
    , visibleMessages : Evergreen.V223.VisibleMessages.VisibleMessages Evergreen.V223.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) (LastTypedAt Evergreen.V223.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V223.Message.MessageState Evergreen.V223.Id.ThreadMessageId (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId))
    , visibleMessages : Evergreen.V223.VisibleMessages.VisibleMessages Evergreen.V223.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (LastTypedAt Evergreen.V223.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V223.Message.Message Evergreen.V223.Id.ThreadMessageId (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) (LastTypedAt Evergreen.V223.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V223.Message.Message Evergreen.V223.Id.ThreadMessageId (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (LastTypedAt Evergreen.V223.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V223.OneToOne.OneToOne (Evergreen.V223.Discord.Id Evergreen.V223.Discord.MessageId) (Evergreen.V223.Id.Id Evergreen.V223.Id.ThreadMessageId)
    }
