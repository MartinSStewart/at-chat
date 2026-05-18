module Evergreen.V228.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V228.Discord
import Evergreen.V228.Id
import Evergreen.V228.Message
import Evergreen.V228.OneToOne
import Evergreen.V228.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V228.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V228.Message.MessageState Evergreen.V228.Id.ThreadMessageId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId))
    , visibleMessages : Evergreen.V228.VisibleMessages.VisibleMessages Evergreen.V228.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) (LastTypedAt Evergreen.V228.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V228.Message.MessageState Evergreen.V228.Id.ThreadMessageId (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId))
    , visibleMessages : Evergreen.V228.VisibleMessages.VisibleMessages Evergreen.V228.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (LastTypedAt Evergreen.V228.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V228.Message.Message Evergreen.V228.Id.ThreadMessageId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) (LastTypedAt Evergreen.V228.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V228.Message.Message Evergreen.V228.Id.ThreadMessageId (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (LastTypedAt Evergreen.V228.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V228.OneToOne.OneToOne (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ThreadMessageId)
    }
