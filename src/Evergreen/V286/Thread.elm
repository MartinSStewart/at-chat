module Evergreen.V286.Thread exposing (..)

import Array
import Date
import Effect.Time
import Evergreen.V286.Discord
import Evergreen.V286.Drawing
import Evergreen.V286.Id
import Evergreen.V286.Message
import Evergreen.V286.OneToOne
import Evergreen.V286.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V286.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V286.Message.MessageState Evergreen.V286.Id.ThreadMessageId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))
    , visibleMessages : Evergreen.V286.VisibleMessages.VisibleMessages Evergreen.V286.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) (LastTypedAt Evergreen.V286.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V286.Drawing.Drawing (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V286.Message.MessageState Evergreen.V286.Id.ThreadMessageId (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))
    , visibleMessages : Evergreen.V286.VisibleMessages.VisibleMessages Evergreen.V286.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (LastTypedAt Evergreen.V286.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V286.Drawing.Drawing (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V286.Message.Message Evergreen.V286.Id.ThreadMessageId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) (LastTypedAt Evergreen.V286.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V286.Drawing.Drawing (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V286.Message.Message Evergreen.V286.Id.ThreadMessageId (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (LastTypedAt Evergreen.V286.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V286.OneToOne.OneToOne (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V286.Drawing.Drawing (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))
    }
