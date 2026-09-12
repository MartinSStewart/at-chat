module Evergreen.V381.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V381.Discord
import Evergreen.V381.Drawing
import Evergreen.V381.Id
import Evergreen.V381.IdArray
import Evergreen.V381.Message
import Evergreen.V381.MessageArray
import Evergreen.V381.OneToOne
import Evergreen.V381.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V381.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V381.MessageArray.MessageArray Evergreen.V381.Id.ThreadMessageId (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    , visibleMessages : Evergreen.V381.VisibleMessages.VisibleMessages Evergreen.V381.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (LastTypedAt Evergreen.V381.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V381.Drawing.Drawing (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V381.MessageArray.MessageArray Evergreen.V381.Id.ThreadMessageId (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
    , visibleMessages : Evergreen.V381.VisibleMessages.VisibleMessages Evergreen.V381.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (LastTypedAt Evergreen.V381.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V381.Drawing.Drawing (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V381.IdArray.IdArray Evergreen.V381.Id.ThreadMessageId (Evergreen.V381.Message.Message Evergreen.V381.Id.ThreadMessageId (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) (LastTypedAt Evergreen.V381.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V381.Drawing.Drawing (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V381.IdArray.IdArray Evergreen.V381.Id.ThreadMessageId (Evergreen.V381.Message.Message Evergreen.V381.Id.ThreadMessageId (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId) (LastTypedAt Evergreen.V381.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V381.OneToOne.OneToOne (Evergreen.V381.Discord.Id Evergreen.V381.Discord.MessageId) (Evergreen.V381.Id.Id Evergreen.V381.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V381.Drawing.Drawing (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId))
    }
