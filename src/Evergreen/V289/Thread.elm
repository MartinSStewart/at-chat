module Evergreen.V289.Thread exposing (..)

import Array
import Date
import Effect.Time
import Evergreen.V289.Discord
import Evergreen.V289.Drawing
import Evergreen.V289.Id
import Evergreen.V289.Message
import Evergreen.V289.OneToOne
import Evergreen.V289.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V289.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V289.Message.MessageState Evergreen.V289.Id.ThreadMessageId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))
    , visibleMessages : Evergreen.V289.VisibleMessages.VisibleMessages Evergreen.V289.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) (LastTypedAt Evergreen.V289.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V289.Drawing.Drawing (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V289.Message.MessageState Evergreen.V289.Id.ThreadMessageId (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))
    , visibleMessages : Evergreen.V289.VisibleMessages.VisibleMessages Evergreen.V289.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (LastTypedAt Evergreen.V289.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V289.Drawing.Drawing (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V289.Message.Message Evergreen.V289.Id.ThreadMessageId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) (LastTypedAt Evergreen.V289.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V289.Drawing.Drawing (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V289.Message.Message Evergreen.V289.Id.ThreadMessageId (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (LastTypedAt Evergreen.V289.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V289.OneToOne.OneToOne (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V289.Drawing.Drawing (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))
    }
