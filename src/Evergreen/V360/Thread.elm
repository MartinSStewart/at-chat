module Evergreen.V360.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V360.Discord
import Evergreen.V360.Drawing
import Evergreen.V360.Id
import Evergreen.V360.IdArray
import Evergreen.V360.Message
import Evergreen.V360.MessageArray
import Evergreen.V360.OneToOne
import Evergreen.V360.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V360.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V360.MessageArray.MessageArray Evergreen.V360.Id.ThreadMessageId (Evergreen.V360.Message.Message Evergreen.V360.Id.ThreadMessageId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))
    , visibleMessages : Evergreen.V360.VisibleMessages.VisibleMessages Evergreen.V360.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (LastTypedAt Evergreen.V360.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V360.Drawing.Drawing (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V360.MessageArray.MessageArray Evergreen.V360.Id.ThreadMessageId (Evergreen.V360.Message.Message Evergreen.V360.Id.ThreadMessageId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))
    , visibleMessages : Evergreen.V360.VisibleMessages.VisibleMessages Evergreen.V360.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (LastTypedAt Evergreen.V360.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V360.Drawing.Drawing (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V360.IdArray.IdArray Evergreen.V360.Id.ThreadMessageId (Evergreen.V360.Message.Message Evergreen.V360.Id.ThreadMessageId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (LastTypedAt Evergreen.V360.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V360.Drawing.Drawing (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V360.IdArray.IdArray Evergreen.V360.Id.ThreadMessageId (Evergreen.V360.Message.Message Evergreen.V360.Id.ThreadMessageId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (LastTypedAt Evergreen.V360.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V360.OneToOne.OneToOne (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V360.Drawing.Drawing (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))
    }
