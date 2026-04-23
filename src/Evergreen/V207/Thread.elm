module Evergreen.V207.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V207.Discord
import Evergreen.V207.Id
import Evergreen.V207.Message
import Evergreen.V207.OneToOne
import Evergreen.V207.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V207.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V207.Message.MessageState Evergreen.V207.Id.ThreadMessageId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId))
    , visibleMessages : Evergreen.V207.VisibleMessages.VisibleMessages Evergreen.V207.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) (LastTypedAt Evergreen.V207.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V207.Message.MessageState Evergreen.V207.Id.ThreadMessageId (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId))
    , visibleMessages : Evergreen.V207.VisibleMessages.VisibleMessages Evergreen.V207.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (LastTypedAt Evergreen.V207.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V207.Message.Message Evergreen.V207.Id.ThreadMessageId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) (LastTypedAt Evergreen.V207.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V207.Message.Message Evergreen.V207.Id.ThreadMessageId (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (LastTypedAt Evergreen.V207.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V207.OneToOne.OneToOne (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ThreadMessageId)
    }
