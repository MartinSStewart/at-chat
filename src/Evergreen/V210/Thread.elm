module Evergreen.V210.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V210.Discord
import Evergreen.V210.Id
import Evergreen.V210.Message
import Evergreen.V210.OneToOne
import Evergreen.V210.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V210.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V210.Message.MessageState Evergreen.V210.Id.ThreadMessageId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId))
    , visibleMessages : Evergreen.V210.VisibleMessages.VisibleMessages Evergreen.V210.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) (LastTypedAt Evergreen.V210.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V210.Message.MessageState Evergreen.V210.Id.ThreadMessageId (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId))
    , visibleMessages : Evergreen.V210.VisibleMessages.VisibleMessages Evergreen.V210.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (LastTypedAt Evergreen.V210.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V210.Message.Message Evergreen.V210.Id.ThreadMessageId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) (LastTypedAt Evergreen.V210.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V210.Message.Message Evergreen.V210.Id.ThreadMessageId (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (LastTypedAt Evergreen.V210.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V210.OneToOne.OneToOne (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ThreadMessageId)
    }
