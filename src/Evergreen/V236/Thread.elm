module Evergreen.V236.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V236.Discord
import Evergreen.V236.Id
import Evergreen.V236.Message
import Evergreen.V236.OneToOne
import Evergreen.V236.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V236.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V236.Message.MessageState Evergreen.V236.Id.ThreadMessageId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId))
    , visibleMessages : Evergreen.V236.VisibleMessages.VisibleMessages Evergreen.V236.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) (LastTypedAt Evergreen.V236.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V236.Message.MessageState Evergreen.V236.Id.ThreadMessageId (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId))
    , visibleMessages : Evergreen.V236.VisibleMessages.VisibleMessages Evergreen.V236.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (LastTypedAt Evergreen.V236.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V236.Message.Message Evergreen.V236.Id.ThreadMessageId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) (LastTypedAt Evergreen.V236.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V236.Message.Message Evergreen.V236.Id.ThreadMessageId (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (LastTypedAt Evergreen.V236.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V236.OneToOne.OneToOne (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ThreadMessageId)
    }
