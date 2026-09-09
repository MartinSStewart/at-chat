module Evergreen.V375.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V375.Discord
import Evergreen.V375.Drawing
import Evergreen.V375.Id
import Evergreen.V375.IdArray
import Evergreen.V375.Message
import Evergreen.V375.MessageArray
import Evergreen.V375.OneToOne
import Evergreen.V375.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V375.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V375.MessageArray.MessageArray Evergreen.V375.Id.ThreadMessageId (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    , visibleMessages : Evergreen.V375.VisibleMessages.VisibleMessages Evergreen.V375.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (LastTypedAt Evergreen.V375.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V375.Drawing.Drawing (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V375.MessageArray.MessageArray Evergreen.V375.Id.ThreadMessageId (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
    , visibleMessages : Evergreen.V375.VisibleMessages.VisibleMessages Evergreen.V375.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (LastTypedAt Evergreen.V375.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V375.Drawing.Drawing (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V375.IdArray.IdArray Evergreen.V375.Id.ThreadMessageId (Evergreen.V375.Message.Message Evergreen.V375.Id.ThreadMessageId (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) (LastTypedAt Evergreen.V375.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V375.Drawing.Drawing (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V375.IdArray.IdArray Evergreen.V375.Id.ThreadMessageId (Evergreen.V375.Message.Message Evergreen.V375.Id.ThreadMessageId (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId) (LastTypedAt Evergreen.V375.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V375.OneToOne.OneToOne (Evergreen.V375.Discord.Id Evergreen.V375.Discord.MessageId) (Evergreen.V375.Id.Id Evergreen.V375.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V375.Drawing.Drawing (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId))
    }
