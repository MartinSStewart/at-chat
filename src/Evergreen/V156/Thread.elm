module Evergreen.V156.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V156.Discord
import Evergreen.V156.Id
import Evergreen.V156.Message
import Evergreen.V156.OneToOne
import Evergreen.V156.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V156.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V156.Message.MessageState Evergreen.V156.Id.ThreadMessageId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId))
    , visibleMessages : Evergreen.V156.VisibleMessages.VisibleMessages Evergreen.V156.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) (LastTypedAt Evergreen.V156.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V156.Message.MessageState Evergreen.V156.Id.ThreadMessageId (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId))
    , visibleMessages : Evergreen.V156.VisibleMessages.VisibleMessages Evergreen.V156.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (LastTypedAt Evergreen.V156.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V156.Message.Message Evergreen.V156.Id.ThreadMessageId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) (LastTypedAt Evergreen.V156.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V156.Message.Message Evergreen.V156.Id.ThreadMessageId (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (LastTypedAt Evergreen.V156.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V156.OneToOne.OneToOne (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ThreadMessageId)
    }
