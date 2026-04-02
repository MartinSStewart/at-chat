module Evergreen.V186.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V186.Discord
import Evergreen.V186.Id
import Evergreen.V186.Message
import Evergreen.V186.OneToOne
import Evergreen.V186.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V186.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V186.Message.MessageState Evergreen.V186.Id.ThreadMessageId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId))
    , visibleMessages : Evergreen.V186.VisibleMessages.VisibleMessages Evergreen.V186.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) (LastTypedAt Evergreen.V186.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V186.Message.MessageState Evergreen.V186.Id.ThreadMessageId (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId))
    , visibleMessages : Evergreen.V186.VisibleMessages.VisibleMessages Evergreen.V186.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (LastTypedAt Evergreen.V186.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V186.Message.Message Evergreen.V186.Id.ThreadMessageId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) (LastTypedAt Evergreen.V186.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V186.Message.Message Evergreen.V186.Id.ThreadMessageId (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (LastTypedAt Evergreen.V186.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V186.OneToOne.OneToOne (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ThreadMessageId)
    }
