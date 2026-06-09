module Evergreen.V283.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V283.Discord
import Evergreen.V283.Id
import Evergreen.V283.Message
import Evergreen.V283.OneToOne
import Evergreen.V283.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V283.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V283.Message.MessageState Evergreen.V283.Id.ThreadMessageId (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId))
    , visibleMessages : Evergreen.V283.VisibleMessages.VisibleMessages Evergreen.V283.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) (LastTypedAt Evergreen.V283.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V283.Message.MessageState Evergreen.V283.Id.ThreadMessageId (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId))
    , visibleMessages : Evergreen.V283.VisibleMessages.VisibleMessages Evergreen.V283.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (LastTypedAt Evergreen.V283.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V283.Message.Message Evergreen.V283.Id.ThreadMessageId (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) (LastTypedAt Evergreen.V283.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V283.Message.Message Evergreen.V283.Id.ThreadMessageId (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (LastTypedAt Evergreen.V283.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V283.OneToOne.OneToOne (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ThreadMessageId)
    }
