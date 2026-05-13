module Evergreen.V216.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V216.Discord
import Evergreen.V216.Id
import Evergreen.V216.Message
import Evergreen.V216.OneToOne
import Evergreen.V216.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V216.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V216.Message.MessageState Evergreen.V216.Id.ThreadMessageId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId))
    , visibleMessages : Evergreen.V216.VisibleMessages.VisibleMessages Evergreen.V216.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) (LastTypedAt Evergreen.V216.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V216.Message.MessageState Evergreen.V216.Id.ThreadMessageId (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId))
    , visibleMessages : Evergreen.V216.VisibleMessages.VisibleMessages Evergreen.V216.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (LastTypedAt Evergreen.V216.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V216.Message.Message Evergreen.V216.Id.ThreadMessageId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) (LastTypedAt Evergreen.V216.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V216.Message.Message Evergreen.V216.Id.ThreadMessageId (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (LastTypedAt Evergreen.V216.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V216.OneToOne.OneToOne (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ThreadMessageId)
    }
