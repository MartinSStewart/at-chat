module Evergreen.V203.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V203.Discord
import Evergreen.V203.Id
import Evergreen.V203.Message
import Evergreen.V203.OneToOne
import Evergreen.V203.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V203.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V203.Message.MessageState Evergreen.V203.Id.ThreadMessageId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))
    , visibleMessages : Evergreen.V203.VisibleMessages.VisibleMessages Evergreen.V203.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) (LastTypedAt Evergreen.V203.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V203.Message.MessageState Evergreen.V203.Id.ThreadMessageId (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId))
    , visibleMessages : Evergreen.V203.VisibleMessages.VisibleMessages Evergreen.V203.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (LastTypedAt Evergreen.V203.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V203.Message.Message Evergreen.V203.Id.ThreadMessageId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) (LastTypedAt Evergreen.V203.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V203.Message.Message Evergreen.V203.Id.ThreadMessageId (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (LastTypedAt Evergreen.V203.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V203.OneToOne.OneToOne (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ThreadMessageId)
    }
