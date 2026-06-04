module Evergreen.V271.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V271.Discord
import Evergreen.V271.Id
import Evergreen.V271.Message
import Evergreen.V271.OneToOne
import Evergreen.V271.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V271.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V271.Message.MessageState Evergreen.V271.Id.ThreadMessageId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId))
    , visibleMessages : Evergreen.V271.VisibleMessages.VisibleMessages Evergreen.V271.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) (LastTypedAt Evergreen.V271.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V271.Message.MessageState Evergreen.V271.Id.ThreadMessageId (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId))
    , visibleMessages : Evergreen.V271.VisibleMessages.VisibleMessages Evergreen.V271.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (LastTypedAt Evergreen.V271.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V271.Message.Message Evergreen.V271.Id.ThreadMessageId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) (LastTypedAt Evergreen.V271.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V271.Message.Message Evergreen.V271.Id.ThreadMessageId (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (LastTypedAt Evergreen.V271.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V271.OneToOne.OneToOne (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ThreadMessageId)
    }
