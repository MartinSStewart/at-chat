module Evergreen.V197.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V197.Discord
import Evergreen.V197.Id
import Evergreen.V197.Message
import Evergreen.V197.OneToOne
import Evergreen.V197.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V197.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V197.Message.MessageState Evergreen.V197.Id.ThreadMessageId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))
    , visibleMessages : Evergreen.V197.VisibleMessages.VisibleMessages Evergreen.V197.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) (LastTypedAt Evergreen.V197.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V197.Message.MessageState Evergreen.V197.Id.ThreadMessageId (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId))
    , visibleMessages : Evergreen.V197.VisibleMessages.VisibleMessages Evergreen.V197.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (LastTypedAt Evergreen.V197.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V197.Message.Message Evergreen.V197.Id.ThreadMessageId (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V197.Id.Id Evergreen.V197.Id.UserId) (LastTypedAt Evergreen.V197.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V197.Message.Message Evergreen.V197.Id.ThreadMessageId (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId) (LastTypedAt Evergreen.V197.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V197.OneToOne.OneToOne (Evergreen.V197.Discord.Id Evergreen.V197.Discord.MessageId) (Evergreen.V197.Id.Id Evergreen.V197.Id.ThreadMessageId)
    }
