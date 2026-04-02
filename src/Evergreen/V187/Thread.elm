module Evergreen.V187.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V187.Discord
import Evergreen.V187.Id
import Evergreen.V187.Message
import Evergreen.V187.OneToOne
import Evergreen.V187.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V187.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V187.Message.MessageState Evergreen.V187.Id.ThreadMessageId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))
    , visibleMessages : Evergreen.V187.VisibleMessages.VisibleMessages Evergreen.V187.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) (LastTypedAt Evergreen.V187.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V187.Message.MessageState Evergreen.V187.Id.ThreadMessageId (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId))
    , visibleMessages : Evergreen.V187.VisibleMessages.VisibleMessages Evergreen.V187.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (LastTypedAt Evergreen.V187.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V187.Message.Message Evergreen.V187.Id.ThreadMessageId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) (LastTypedAt Evergreen.V187.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V187.Message.Message Evergreen.V187.Id.ThreadMessageId (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (LastTypedAt Evergreen.V187.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V187.OneToOne.OneToOne (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ThreadMessageId)
    }
