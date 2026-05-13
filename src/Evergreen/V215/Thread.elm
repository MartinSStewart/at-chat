module Evergreen.V215.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V215.Discord
import Evergreen.V215.Id
import Evergreen.V215.Message
import Evergreen.V215.OneToOne
import Evergreen.V215.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V215.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V215.Message.MessageState Evergreen.V215.Id.ThreadMessageId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId))
    , visibleMessages : Evergreen.V215.VisibleMessages.VisibleMessages Evergreen.V215.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) (LastTypedAt Evergreen.V215.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V215.Message.MessageState Evergreen.V215.Id.ThreadMessageId (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId))
    , visibleMessages : Evergreen.V215.VisibleMessages.VisibleMessages Evergreen.V215.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (LastTypedAt Evergreen.V215.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V215.Message.Message Evergreen.V215.Id.ThreadMessageId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) (LastTypedAt Evergreen.V215.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V215.Message.Message Evergreen.V215.Id.ThreadMessageId (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (LastTypedAt Evergreen.V215.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V215.OneToOne.OneToOne (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ThreadMessageId)
    }
