module Evergreen.V193.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V193.Discord
import Evergreen.V193.Id
import Evergreen.V193.Message
import Evergreen.V193.OneToOne
import Evergreen.V193.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V193.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V193.Message.MessageState Evergreen.V193.Id.ThreadMessageId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))
    , visibleMessages : Evergreen.V193.VisibleMessages.VisibleMessages Evergreen.V193.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) (LastTypedAt Evergreen.V193.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V193.Message.MessageState Evergreen.V193.Id.ThreadMessageId (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId))
    , visibleMessages : Evergreen.V193.VisibleMessages.VisibleMessages Evergreen.V193.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (LastTypedAt Evergreen.V193.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V193.Message.Message Evergreen.V193.Id.ThreadMessageId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) (LastTypedAt Evergreen.V193.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V193.Message.Message Evergreen.V193.Id.ThreadMessageId (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (LastTypedAt Evergreen.V193.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V193.OneToOne.OneToOne (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ThreadMessageId)
    }
