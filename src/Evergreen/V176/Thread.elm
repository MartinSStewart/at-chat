module Evergreen.V176.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V176.Discord
import Evergreen.V176.Id
import Evergreen.V176.Message
import Evergreen.V176.OneToOne
import Evergreen.V176.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V176.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V176.Message.MessageState Evergreen.V176.Id.ThreadMessageId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId))
    , visibleMessages : Evergreen.V176.VisibleMessages.VisibleMessages Evergreen.V176.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) (LastTypedAt Evergreen.V176.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V176.Message.MessageState Evergreen.V176.Id.ThreadMessageId (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId))
    , visibleMessages : Evergreen.V176.VisibleMessages.VisibleMessages Evergreen.V176.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (LastTypedAt Evergreen.V176.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V176.Message.Message Evergreen.V176.Id.ThreadMessageId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) (LastTypedAt Evergreen.V176.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V176.Message.Message Evergreen.V176.Id.ThreadMessageId (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (LastTypedAt Evergreen.V176.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V176.OneToOne.OneToOne (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ThreadMessageId)
    }
