module Evergreen.V209.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V209.Discord
import Evergreen.V209.Id
import Evergreen.V209.Message
import Evergreen.V209.OneToOne
import Evergreen.V209.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V209.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V209.Message.MessageState Evergreen.V209.Id.ThreadMessageId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId))
    , visibleMessages : Evergreen.V209.VisibleMessages.VisibleMessages Evergreen.V209.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) (LastTypedAt Evergreen.V209.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V209.Message.MessageState Evergreen.V209.Id.ThreadMessageId (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId))
    , visibleMessages : Evergreen.V209.VisibleMessages.VisibleMessages Evergreen.V209.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (LastTypedAt Evergreen.V209.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V209.Message.Message Evergreen.V209.Id.ThreadMessageId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) (LastTypedAt Evergreen.V209.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V209.Message.Message Evergreen.V209.Id.ThreadMessageId (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (LastTypedAt Evergreen.V209.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V209.OneToOne.OneToOne (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ThreadMessageId)
    }
