module Evergreen.V190.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V190.Discord
import Evergreen.V190.Id
import Evergreen.V190.Message
import Evergreen.V190.OneToOne
import Evergreen.V190.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V190.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V190.Message.MessageState Evergreen.V190.Id.ThreadMessageId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))
    , visibleMessages : Evergreen.V190.VisibleMessages.VisibleMessages Evergreen.V190.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) (LastTypedAt Evergreen.V190.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V190.Message.MessageState Evergreen.V190.Id.ThreadMessageId (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId))
    , visibleMessages : Evergreen.V190.VisibleMessages.VisibleMessages Evergreen.V190.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (LastTypedAt Evergreen.V190.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V190.Message.Message Evergreen.V190.Id.ThreadMessageId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) (LastTypedAt Evergreen.V190.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V190.Message.Message Evergreen.V190.Id.ThreadMessageId (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (LastTypedAt Evergreen.V190.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V190.OneToOne.OneToOne (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ThreadMessageId)
    }
