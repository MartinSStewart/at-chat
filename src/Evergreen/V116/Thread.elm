module Evergreen.V116.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V116.Discord.Id
import Evergreen.V116.Id
import Evergreen.V116.Message
import Evergreen.V116.OneToOne
import Evergreen.V116.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V116.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V116.Message.MessageState Evergreen.V116.Id.ThreadMessageId (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId))
    , visibleMessages : Evergreen.V116.VisibleMessages.VisibleMessages Evergreen.V116.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) (LastTypedAt Evergreen.V116.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V116.Message.MessageState Evergreen.V116.Id.ThreadMessageId (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))
    , visibleMessages : Evergreen.V116.VisibleMessages.VisibleMessages Evergreen.V116.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (LastTypedAt Evergreen.V116.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V116.Message.Message Evergreen.V116.Id.ThreadMessageId (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) (LastTypedAt Evergreen.V116.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V116.Message.Message Evergreen.V116.Id.ThreadMessageId (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (LastTypedAt Evergreen.V116.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V116.OneToOne.OneToOne (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ThreadMessageId)
    }
