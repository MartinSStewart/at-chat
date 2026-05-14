module Evergreen.V218.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V218.Discord
import Evergreen.V218.Id
import Evergreen.V218.Message
import Evergreen.V218.OneToOne
import Evergreen.V218.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V218.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V218.Message.MessageState Evergreen.V218.Id.ThreadMessageId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId))
    , visibleMessages : Evergreen.V218.VisibleMessages.VisibleMessages Evergreen.V218.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) (LastTypedAt Evergreen.V218.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V218.Message.MessageState Evergreen.V218.Id.ThreadMessageId (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId))
    , visibleMessages : Evergreen.V218.VisibleMessages.VisibleMessages Evergreen.V218.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (LastTypedAt Evergreen.V218.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V218.Message.Message Evergreen.V218.Id.ThreadMessageId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) (LastTypedAt Evergreen.V218.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V218.Message.Message Evergreen.V218.Id.ThreadMessageId (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (LastTypedAt Evergreen.V218.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V218.OneToOne.OneToOne (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ThreadMessageId)
    }
