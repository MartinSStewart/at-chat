module Evergreen.V377.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V377.Discord
import Evergreen.V377.Drawing
import Evergreen.V377.Id
import Evergreen.V377.IdArray
import Evergreen.V377.Message
import Evergreen.V377.MessageArray
import Evergreen.V377.OneToOne
import Evergreen.V377.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V377.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V377.MessageArray.MessageArray Evergreen.V377.Id.ThreadMessageId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    , visibleMessages : Evergreen.V377.VisibleMessages.VisibleMessages Evergreen.V377.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (LastTypedAt Evergreen.V377.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V377.Drawing.Drawing (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V377.MessageArray.MessageArray Evergreen.V377.Id.ThreadMessageId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
    , visibleMessages : Evergreen.V377.VisibleMessages.VisibleMessages Evergreen.V377.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (LastTypedAt Evergreen.V377.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V377.Drawing.Drawing (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V377.IdArray.IdArray Evergreen.V377.Id.ThreadMessageId (Evergreen.V377.Message.Message Evergreen.V377.Id.ThreadMessageId (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) (LastTypedAt Evergreen.V377.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V377.Drawing.Drawing (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V377.IdArray.IdArray Evergreen.V377.Id.ThreadMessageId (Evergreen.V377.Message.Message Evergreen.V377.Id.ThreadMessageId (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId) (LastTypedAt Evergreen.V377.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V377.OneToOne.OneToOne (Evergreen.V377.Discord.Id Evergreen.V377.Discord.MessageId) (Evergreen.V377.Id.Id Evergreen.V377.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V377.Drawing.Drawing (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId))
    }
