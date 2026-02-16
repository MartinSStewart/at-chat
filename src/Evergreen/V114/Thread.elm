module Evergreen.V114.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V114.Discord.Id
import Evergreen.V114.Id
import Evergreen.V114.Message
import Evergreen.V114.OneToOne
import Evergreen.V114.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V114.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V114.Message.MessageState Evergreen.V114.Id.ThreadMessageId (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId))
    , visibleMessages : Evergreen.V114.VisibleMessages.VisibleMessages Evergreen.V114.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) (LastTypedAt Evergreen.V114.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V114.Message.MessageState Evergreen.V114.Id.ThreadMessageId (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId))
    , visibleMessages : Evergreen.V114.VisibleMessages.VisibleMessages Evergreen.V114.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (LastTypedAt Evergreen.V114.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V114.Message.Message Evergreen.V114.Id.ThreadMessageId (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) (LastTypedAt Evergreen.V114.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V114.Message.Message Evergreen.V114.Id.ThreadMessageId (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (LastTypedAt Evergreen.V114.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V114.OneToOne.OneToOne (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ThreadMessageId)
    }
