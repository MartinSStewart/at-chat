module Evergreen.V158.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V158.Discord
import Evergreen.V158.Id
import Evergreen.V158.Message
import Evergreen.V158.OneToOne
import Evergreen.V158.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V158.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V158.Message.MessageState Evergreen.V158.Id.ThreadMessageId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId))
    , visibleMessages : Evergreen.V158.VisibleMessages.VisibleMessages Evergreen.V158.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) (LastTypedAt Evergreen.V158.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V158.Message.MessageState Evergreen.V158.Id.ThreadMessageId (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId))
    , visibleMessages : Evergreen.V158.VisibleMessages.VisibleMessages Evergreen.V158.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (LastTypedAt Evergreen.V158.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V158.Message.Message Evergreen.V158.Id.ThreadMessageId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) (LastTypedAt Evergreen.V158.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V158.Message.Message Evergreen.V158.Id.ThreadMessageId (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (LastTypedAt Evergreen.V158.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V158.OneToOne.OneToOne (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ThreadMessageId)
    }
