module Evergreen.V270.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V270.Discord
import Evergreen.V270.Id
import Evergreen.V270.Message
import Evergreen.V270.OneToOne
import Evergreen.V270.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V270.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V270.Message.MessageState Evergreen.V270.Id.ThreadMessageId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId))
    , visibleMessages : Evergreen.V270.VisibleMessages.VisibleMessages Evergreen.V270.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) (LastTypedAt Evergreen.V270.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V270.Message.MessageState Evergreen.V270.Id.ThreadMessageId (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId))
    , visibleMessages : Evergreen.V270.VisibleMessages.VisibleMessages Evergreen.V270.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (LastTypedAt Evergreen.V270.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V270.Message.Message Evergreen.V270.Id.ThreadMessageId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) (LastTypedAt Evergreen.V270.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V270.Message.Message Evergreen.V270.Id.ThreadMessageId (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (LastTypedAt Evergreen.V270.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V270.OneToOne.OneToOne (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ThreadMessageId)
    }
