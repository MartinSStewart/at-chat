module Evergreen.V136.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V136.Discord.Id
import Evergreen.V136.Id
import Evergreen.V136.Message
import Evergreen.V136.OneToOne
import Evergreen.V136.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V136.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V136.Message.MessageState Evergreen.V136.Id.ThreadMessageId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId))
    , visibleMessages : Evergreen.V136.VisibleMessages.VisibleMessages Evergreen.V136.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) (LastTypedAt Evergreen.V136.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V136.Message.MessageState Evergreen.V136.Id.ThreadMessageId (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId))
    , visibleMessages : Evergreen.V136.VisibleMessages.VisibleMessages Evergreen.V136.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (LastTypedAt Evergreen.V136.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V136.Message.Message Evergreen.V136.Id.ThreadMessageId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) (LastTypedAt Evergreen.V136.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V136.Message.Message Evergreen.V136.Id.ThreadMessageId (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (LastTypedAt Evergreen.V136.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V136.OneToOne.OneToOne (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ThreadMessageId)
    }
