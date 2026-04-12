module Evergreen.V194.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V194.Discord
import Evergreen.V194.Id
import Evergreen.V194.Message
import Evergreen.V194.OneToOne
import Evergreen.V194.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V194.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V194.Message.MessageState Evergreen.V194.Id.ThreadMessageId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))
    , visibleMessages : Evergreen.V194.VisibleMessages.VisibleMessages Evergreen.V194.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) (LastTypedAt Evergreen.V194.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V194.Message.MessageState Evergreen.V194.Id.ThreadMessageId (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId))
    , visibleMessages : Evergreen.V194.VisibleMessages.VisibleMessages Evergreen.V194.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (LastTypedAt Evergreen.V194.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V194.Message.Message Evergreen.V194.Id.ThreadMessageId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) (LastTypedAt Evergreen.V194.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V194.Message.Message Evergreen.V194.Id.ThreadMessageId (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (LastTypedAt Evergreen.V194.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V194.OneToOne.OneToOne (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ThreadMessageId)
    }
