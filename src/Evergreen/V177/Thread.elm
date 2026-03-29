module Evergreen.V177.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V177.Discord
import Evergreen.V177.Id
import Evergreen.V177.Message
import Evergreen.V177.OneToOne
import Evergreen.V177.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V177.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V177.Message.MessageState Evergreen.V177.Id.ThreadMessageId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId))
    , visibleMessages : Evergreen.V177.VisibleMessages.VisibleMessages Evergreen.V177.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) (LastTypedAt Evergreen.V177.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V177.Message.MessageState Evergreen.V177.Id.ThreadMessageId (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId))
    , visibleMessages : Evergreen.V177.VisibleMessages.VisibleMessages Evergreen.V177.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (LastTypedAt Evergreen.V177.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V177.Message.Message Evergreen.V177.Id.ThreadMessageId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) (LastTypedAt Evergreen.V177.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V177.Message.Message Evergreen.V177.Id.ThreadMessageId (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (LastTypedAt Evergreen.V177.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V177.OneToOne.OneToOne (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ThreadMessageId)
    }
