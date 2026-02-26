module Evergreen.V121.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V121.Discord.Id
import Evergreen.V121.Id
import Evergreen.V121.Message
import Evergreen.V121.OneToOne
import Evergreen.V121.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V121.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V121.Message.MessageState Evergreen.V121.Id.ThreadMessageId (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId))
    , visibleMessages : Evergreen.V121.VisibleMessages.VisibleMessages Evergreen.V121.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) (LastTypedAt Evergreen.V121.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V121.Message.MessageState Evergreen.V121.Id.ThreadMessageId (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId))
    , visibleMessages : Evergreen.V121.VisibleMessages.VisibleMessages Evergreen.V121.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId) (LastTypedAt Evergreen.V121.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V121.Message.Message Evergreen.V121.Id.ThreadMessageId (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) (LastTypedAt Evergreen.V121.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V121.Message.Message Evergreen.V121.Id.ThreadMessageId (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId) (LastTypedAt Evergreen.V121.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V121.OneToOne.OneToOne (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.MessageId) (Evergreen.V121.Id.Id Evergreen.V121.Id.ThreadMessageId)
    }
