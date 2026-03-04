module Evergreen.V125.Thread exposing (..)

import Array
import Effect.Time
import Evergreen.V125.Discord.Id
import Evergreen.V125.Id
import Evergreen.V125.Message
import Evergreen.V125.OneToOne
import Evergreen.V125.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V125.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V125.Message.MessageState Evergreen.V125.Id.ThreadMessageId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId))
    , visibleMessages : Evergreen.V125.VisibleMessages.VisibleMessages Evergreen.V125.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (LastTypedAt Evergreen.V125.Id.ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V125.Message.MessageState Evergreen.V125.Id.ThreadMessageId (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId))
    , visibleMessages : Evergreen.V125.VisibleMessages.VisibleMessages Evergreen.V125.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (LastTypedAt Evergreen.V125.Id.ThreadMessageId)
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V125.Message.Message Evergreen.V125.Id.ThreadMessageId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (LastTypedAt Evergreen.V125.Id.ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V125.Message.Message Evergreen.V125.Id.ThreadMessageId (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (LastTypedAt Evergreen.V125.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V125.OneToOne.OneToOne (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ThreadMessageId)
    }
