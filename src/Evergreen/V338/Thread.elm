module Evergreen.V338.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V338.Discord
import Evergreen.V338.Drawing
import Evergreen.V338.Id
import Evergreen.V338.IdArray
import Evergreen.V338.Message
import Evergreen.V338.MessageArray
import Evergreen.V338.OneToOne
import Evergreen.V338.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V338.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V338.MessageArray.MessageArray Evergreen.V338.Id.ThreadMessageId (Evergreen.V338.Message.Message Evergreen.V338.Id.ThreadMessageId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))
    , visibleMessages : Evergreen.V338.VisibleMessages.VisibleMessages Evergreen.V338.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (LastTypedAt Evergreen.V338.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V338.Drawing.Drawing (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V338.MessageArray.MessageArray Evergreen.V338.Id.ThreadMessageId (Evergreen.V338.Message.Message Evergreen.V338.Id.ThreadMessageId (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))
    , visibleMessages : Evergreen.V338.VisibleMessages.VisibleMessages Evergreen.V338.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (LastTypedAt Evergreen.V338.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V338.Drawing.Drawing (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V338.IdArray.IdArray Evergreen.V338.Id.ThreadMessageId (Evergreen.V338.Message.Message Evergreen.V338.Id.ThreadMessageId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (LastTypedAt Evergreen.V338.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V338.Drawing.Drawing (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V338.IdArray.IdArray Evergreen.V338.Id.ThreadMessageId (Evergreen.V338.Message.Message Evergreen.V338.Id.ThreadMessageId (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (LastTypedAt Evergreen.V338.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V338.OneToOne.OneToOne (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V338.Drawing.Drawing (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))
    }
