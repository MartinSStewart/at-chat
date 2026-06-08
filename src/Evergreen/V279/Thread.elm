module Evergreen.V279.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V279.Discord
import Evergreen.V279.Id
import Evergreen.V279.Message
import Evergreen.V279.OneToOne
import Evergreen.V279.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V279.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V279.Message.MessageState Evergreen.V279.Id.ThreadMessageId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId))
    , visibleMessages : Evergreen.V279.VisibleMessages.VisibleMessages Evergreen.V279.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) (LastTypedAt Evergreen.V279.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V279.Message.MessageState Evergreen.V279.Id.ThreadMessageId (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId))
    , visibleMessages : Evergreen.V279.VisibleMessages.VisibleMessages Evergreen.V279.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (LastTypedAt Evergreen.V279.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V279.Message.Message Evergreen.V279.Id.ThreadMessageId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) (LastTypedAt Evergreen.V279.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V279.Message.Message Evergreen.V279.Id.ThreadMessageId (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (LastTypedAt Evergreen.V279.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V279.OneToOne.OneToOne (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ThreadMessageId)
    }
