module Evergreen.V166.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V166.Discord
import Evergreen.V166.Id
import Evergreen.V166.Message
import Evergreen.V166.OneToOne
import Evergreen.V166.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V166.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V166.Message.MessageState Evergreen.V166.Id.ThreadMessageId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId))
    , visibleMessages : Evergreen.V166.VisibleMessages.VisibleMessages Evergreen.V166.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) (LastTypedAt Evergreen.V166.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V166.Message.MessageState Evergreen.V166.Id.ThreadMessageId (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId))
    , visibleMessages : Evergreen.V166.VisibleMessages.VisibleMessages Evergreen.V166.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (LastTypedAt Evergreen.V166.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V166.Message.Message Evergreen.V166.Id.ThreadMessageId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) (LastTypedAt Evergreen.V166.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V166.Message.Message Evergreen.V166.Id.ThreadMessageId (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (LastTypedAt Evergreen.V166.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V166.OneToOne.OneToOne (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ThreadMessageId)
    }
