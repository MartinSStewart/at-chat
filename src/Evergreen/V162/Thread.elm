module Evergreen.V162.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V162.Discord
import Evergreen.V162.Id
import Evergreen.V162.Message
import Evergreen.V162.OneToOne
import Evergreen.V162.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V162.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V162.Message.MessageState Evergreen.V162.Id.ThreadMessageId (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId))
    , visibleMessages : Evergreen.V162.VisibleMessages.VisibleMessages Evergreen.V162.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) (LastTypedAt Evergreen.V162.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V162.Message.MessageState Evergreen.V162.Id.ThreadMessageId (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId))
    , visibleMessages : Evergreen.V162.VisibleMessages.VisibleMessages Evergreen.V162.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (LastTypedAt Evergreen.V162.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V162.Message.Message Evergreen.V162.Id.ThreadMessageId (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) (LastTypedAt Evergreen.V162.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V162.Message.Message Evergreen.V162.Id.ThreadMessageId (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (LastTypedAt Evergreen.V162.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V162.OneToOne.OneToOne (Evergreen.V162.Discord.Id Evergreen.V162.Discord.MessageId) (Evergreen.V162.Id.Id Evergreen.V162.Id.ThreadMessageId)
    }
