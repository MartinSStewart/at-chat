module Evergreen.V160.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V160.Discord
import Evergreen.V160.Id
import Evergreen.V160.Message
import Evergreen.V160.OneToOne
import Evergreen.V160.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V160.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V160.Message.MessageState Evergreen.V160.Id.ThreadMessageId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId))
    , visibleMessages : Evergreen.V160.VisibleMessages.VisibleMessages Evergreen.V160.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) (LastTypedAt Evergreen.V160.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V160.Message.MessageState Evergreen.V160.Id.ThreadMessageId (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId))
    , visibleMessages : Evergreen.V160.VisibleMessages.VisibleMessages Evergreen.V160.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (LastTypedAt Evergreen.V160.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V160.Message.Message Evergreen.V160.Id.ThreadMessageId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) (LastTypedAt Evergreen.V160.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V160.Message.Message Evergreen.V160.Id.ThreadMessageId (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (LastTypedAt Evergreen.V160.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V160.OneToOne.OneToOne (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ThreadMessageId)
    }
