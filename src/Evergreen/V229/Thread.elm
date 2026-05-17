module Evergreen.V229.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V229.Discord
import Evergreen.V229.Id
import Evergreen.V229.Message
import Evergreen.V229.OneToOne
import Evergreen.V229.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V229.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V229.Message.MessageState Evergreen.V229.Id.ThreadMessageId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId))
    , visibleMessages : Evergreen.V229.VisibleMessages.VisibleMessages Evergreen.V229.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) (LastTypedAt Evergreen.V229.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V229.Message.MessageState Evergreen.V229.Id.ThreadMessageId (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId))
    , visibleMessages : Evergreen.V229.VisibleMessages.VisibleMessages Evergreen.V229.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (LastTypedAt Evergreen.V229.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V229.Message.Message Evergreen.V229.Id.ThreadMessageId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) (LastTypedAt Evergreen.V229.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V229.Message.Message Evergreen.V229.Id.ThreadMessageId (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (LastTypedAt Evergreen.V229.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V229.OneToOne.OneToOne (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ThreadMessageId)
    }
