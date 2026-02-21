module Evergreen.V117.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V117.Discord.Id
import Evergreen.V117.Id
import Evergreen.V117.Message
import Evergreen.V117.OneToOne
import Evergreen.V117.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V117.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V117.Message.MessageState Evergreen.V117.Id.ThreadMessageId (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId))
    , visibleMessages : Evergreen.V117.VisibleMessages.VisibleMessages Evergreen.V117.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) (LastTypedAt Evergreen.V117.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V117.Message.MessageState Evergreen.V117.Id.ThreadMessageId (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))
    , visibleMessages : Evergreen.V117.VisibleMessages.VisibleMessages Evergreen.V117.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (LastTypedAt Evergreen.V117.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V117.Message.Message Evergreen.V117.Id.ThreadMessageId (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) (LastTypedAt Evergreen.V117.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V117.Message.Message Evergreen.V117.Id.ThreadMessageId (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (LastTypedAt Evergreen.V117.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V117.OneToOne.OneToOne (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ThreadMessageId)
    }
