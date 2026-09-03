module Evergreen.V367.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V367.Discord
import Evergreen.V367.Drawing
import Evergreen.V367.Id
import Evergreen.V367.IdArray
import Evergreen.V367.Message
import Evergreen.V367.MessageArray
import Evergreen.V367.OneToOne
import Evergreen.V367.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V367.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V367.MessageArray.MessageArray Evergreen.V367.Id.ThreadMessageId (Evergreen.V367.Message.Message Evergreen.V367.Id.ThreadMessageId (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId))
    , visibleMessages : Evergreen.V367.VisibleMessages.VisibleMessages Evergreen.V367.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (LastTypedAt Evergreen.V367.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V367.Drawing.Drawing (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V367.MessageArray.MessageArray Evergreen.V367.Id.ThreadMessageId (Evergreen.V367.Message.Message Evergreen.V367.Id.ThreadMessageId (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId))
    , visibleMessages : Evergreen.V367.VisibleMessages.VisibleMessages Evergreen.V367.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (LastTypedAt Evergreen.V367.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V367.Drawing.Drawing (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V367.IdArray.IdArray Evergreen.V367.Id.ThreadMessageId (Evergreen.V367.Message.Message Evergreen.V367.Id.ThreadMessageId (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) (LastTypedAt Evergreen.V367.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V367.Drawing.Drawing (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V367.IdArray.IdArray Evergreen.V367.Id.ThreadMessageId (Evergreen.V367.Message.Message Evergreen.V367.Id.ThreadMessageId (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId) (LastTypedAt Evergreen.V367.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V367.OneToOne.OneToOne (Evergreen.V367.Discord.Id Evergreen.V367.Discord.MessageId) (Evergreen.V367.Id.Id Evergreen.V367.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V367.Drawing.Drawing (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId))
    }
