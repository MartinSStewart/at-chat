module Evergreen.V359.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V359.Discord
import Evergreen.V359.Drawing
import Evergreen.V359.Id
import Evergreen.V359.IdArray
import Evergreen.V359.Message
import Evergreen.V359.MessageArray
import Evergreen.V359.OneToOne
import Evergreen.V359.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V359.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V359.MessageArray.MessageArray Evergreen.V359.Id.ThreadMessageId (Evergreen.V359.Message.Message Evergreen.V359.Id.ThreadMessageId (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId))
    , visibleMessages : Evergreen.V359.VisibleMessages.VisibleMessages Evergreen.V359.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) (LastTypedAt Evergreen.V359.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V359.Drawing.Drawing (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V359.MessageArray.MessageArray Evergreen.V359.Id.ThreadMessageId (Evergreen.V359.Message.Message Evergreen.V359.Id.ThreadMessageId (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId))
    , visibleMessages : Evergreen.V359.VisibleMessages.VisibleMessages Evergreen.V359.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (LastTypedAt Evergreen.V359.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V359.Drawing.Drawing (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V359.IdArray.IdArray Evergreen.V359.Id.ThreadMessageId (Evergreen.V359.Message.Message Evergreen.V359.Id.ThreadMessageId (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) (LastTypedAt Evergreen.V359.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V359.Drawing.Drawing (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V359.IdArray.IdArray Evergreen.V359.Id.ThreadMessageId (Evergreen.V359.Message.Message Evergreen.V359.Id.ThreadMessageId (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (LastTypedAt Evergreen.V359.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V359.OneToOne.OneToOne (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V359.Drawing.Drawing (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId))
    }
