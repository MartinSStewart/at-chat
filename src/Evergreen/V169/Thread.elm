module Evergreen.V169.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V169.Discord
import Evergreen.V169.Id
import Evergreen.V169.Message
import Evergreen.V169.OneToOne
import Evergreen.V169.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V169.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V169.Message.MessageState Evergreen.V169.Id.ThreadMessageId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId))
    , visibleMessages : Evergreen.V169.VisibleMessages.VisibleMessages Evergreen.V169.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) (LastTypedAt Evergreen.V169.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V169.Message.MessageState Evergreen.V169.Id.ThreadMessageId (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId))
    , visibleMessages : Evergreen.V169.VisibleMessages.VisibleMessages Evergreen.V169.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (LastTypedAt Evergreen.V169.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V169.Message.Message Evergreen.V169.Id.ThreadMessageId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) (LastTypedAt Evergreen.V169.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V169.Message.Message Evergreen.V169.Id.ThreadMessageId (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (LastTypedAt Evergreen.V169.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V169.OneToOne.OneToOne (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ThreadMessageId)
    }
