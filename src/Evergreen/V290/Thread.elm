module Evergreen.V290.Thread exposing (..)

import Array
import Date
import Effect.Time
import Evergreen.V290.Discord
import Evergreen.V290.Drawing
import Evergreen.V290.Id
import Evergreen.V290.Message
import Evergreen.V290.OneToOne
import Evergreen.V290.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V290.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V290.Message.MessageState Evergreen.V290.Id.ThreadMessageId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))
    , visibleMessages : Evergreen.V290.VisibleMessages.VisibleMessages Evergreen.V290.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) (LastTypedAt Evergreen.V290.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V290.Drawing.Drawing (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V290.Message.MessageState Evergreen.V290.Id.ThreadMessageId (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))
    , visibleMessages : Evergreen.V290.VisibleMessages.VisibleMessages Evergreen.V290.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (LastTypedAt Evergreen.V290.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V290.Drawing.Drawing (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V290.Message.Message Evergreen.V290.Id.ThreadMessageId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) (LastTypedAt Evergreen.V290.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V290.Drawing.Drawing (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V290.Message.Message Evergreen.V290.Id.ThreadMessageId (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (LastTypedAt Evergreen.V290.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V290.OneToOne.OneToOne (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V290.Drawing.Drawing (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))
    }
