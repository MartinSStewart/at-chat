module Evergreen.V242.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V242.Discord
import Evergreen.V242.Id
import Evergreen.V242.Message
import Evergreen.V242.OneToOne
import Evergreen.V242.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V242.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V242.Message.MessageState Evergreen.V242.Id.ThreadMessageId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId))
    , visibleMessages : Evergreen.V242.VisibleMessages.VisibleMessages Evergreen.V242.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) (LastTypedAt Evergreen.V242.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V242.Message.MessageState Evergreen.V242.Id.ThreadMessageId (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId))
    , visibleMessages : Evergreen.V242.VisibleMessages.VisibleMessages Evergreen.V242.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (LastTypedAt Evergreen.V242.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V242.Message.Message Evergreen.V242.Id.ThreadMessageId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) (LastTypedAt Evergreen.V242.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V242.Message.Message Evergreen.V242.Id.ThreadMessageId (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (LastTypedAt Evergreen.V242.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V242.OneToOne.OneToOne (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ThreadMessageId)
    }
