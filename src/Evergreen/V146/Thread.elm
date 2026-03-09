module Evergreen.V146.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V146.Discord
import Evergreen.V146.Id
import Evergreen.V146.Message
import Evergreen.V146.OneToOne
import Evergreen.V146.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V146.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V146.Message.MessageState Evergreen.V146.Id.ThreadMessageId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId))
    , visibleMessages : Evergreen.V146.VisibleMessages.VisibleMessages Evergreen.V146.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) (LastTypedAt Evergreen.V146.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V146.Message.MessageState Evergreen.V146.Id.ThreadMessageId (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId))
    , visibleMessages : Evergreen.V146.VisibleMessages.VisibleMessages Evergreen.V146.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (LastTypedAt Evergreen.V146.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V146.Message.Message Evergreen.V146.Id.ThreadMessageId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) (LastTypedAt Evergreen.V146.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V146.Message.Message Evergreen.V146.Id.ThreadMessageId (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (LastTypedAt Evergreen.V146.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V146.OneToOne.OneToOne (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ThreadMessageId)
    }
