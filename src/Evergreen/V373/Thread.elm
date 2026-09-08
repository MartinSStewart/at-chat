module Evergreen.V373.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V373.Discord
import Evergreen.V373.Drawing
import Evergreen.V373.Id
import Evergreen.V373.IdArray
import Evergreen.V373.Message
import Evergreen.V373.MessageArray
import Evergreen.V373.OneToOne
import Evergreen.V373.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V373.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V373.MessageArray.MessageArray Evergreen.V373.Id.ThreadMessageId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    , visibleMessages : Evergreen.V373.VisibleMessages.VisibleMessages Evergreen.V373.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (LastTypedAt Evergreen.V373.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V373.Drawing.Drawing (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V373.MessageArray.MessageArray Evergreen.V373.Id.ThreadMessageId (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
    , visibleMessages : Evergreen.V373.VisibleMessages.VisibleMessages Evergreen.V373.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (LastTypedAt Evergreen.V373.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V373.Drawing.Drawing (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V373.IdArray.IdArray Evergreen.V373.Id.ThreadMessageId (Evergreen.V373.Message.Message Evergreen.V373.Id.ThreadMessageId (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) (LastTypedAt Evergreen.V373.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V373.Drawing.Drawing (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V373.IdArray.IdArray Evergreen.V373.Id.ThreadMessageId (Evergreen.V373.Message.Message Evergreen.V373.Id.ThreadMessageId (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId) (LastTypedAt Evergreen.V373.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V373.OneToOne.OneToOne (Evergreen.V373.Discord.Id Evergreen.V373.Discord.MessageId) (Evergreen.V373.Id.Id Evergreen.V373.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V373.Drawing.Drawing (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId))
    }
