module Evergreen.V214.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V214.Discord
import Evergreen.V214.Id
import Evergreen.V214.Message
import Evergreen.V214.OneToOne
import Evergreen.V214.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V214.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V214.Message.MessageState Evergreen.V214.Id.ThreadMessageId (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId))
    , visibleMessages : Evergreen.V214.VisibleMessages.VisibleMessages Evergreen.V214.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) (LastTypedAt Evergreen.V214.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V214.Message.MessageState Evergreen.V214.Id.ThreadMessageId (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId))
    , visibleMessages : Evergreen.V214.VisibleMessages.VisibleMessages Evergreen.V214.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (LastTypedAt Evergreen.V214.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V214.Message.Message Evergreen.V214.Id.ThreadMessageId (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) (LastTypedAt Evergreen.V214.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V214.Message.Message Evergreen.V214.Id.ThreadMessageId (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (LastTypedAt Evergreen.V214.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V214.OneToOne.OneToOne (Evergreen.V214.Discord.Id Evergreen.V214.Discord.MessageId) (Evergreen.V214.Id.Id Evergreen.V214.Id.ThreadMessageId)
    }
