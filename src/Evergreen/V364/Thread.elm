module Evergreen.V364.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V364.Discord
import Evergreen.V364.Drawing
import Evergreen.V364.Id
import Evergreen.V364.IdArray
import Evergreen.V364.Message
import Evergreen.V364.MessageArray
import Evergreen.V364.OneToOne
import Evergreen.V364.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V364.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V364.MessageArray.MessageArray Evergreen.V364.Id.ThreadMessageId (Evergreen.V364.Message.Message Evergreen.V364.Id.ThreadMessageId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))
    , visibleMessages : Evergreen.V364.VisibleMessages.VisibleMessages Evergreen.V364.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (LastTypedAt Evergreen.V364.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V364.Drawing.Drawing (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V364.MessageArray.MessageArray Evergreen.V364.Id.ThreadMessageId (Evergreen.V364.Message.Message Evergreen.V364.Id.ThreadMessageId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))
    , visibleMessages : Evergreen.V364.VisibleMessages.VisibleMessages Evergreen.V364.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (LastTypedAt Evergreen.V364.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V364.Drawing.Drawing (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V364.IdArray.IdArray Evergreen.V364.Id.ThreadMessageId (Evergreen.V364.Message.Message Evergreen.V364.Id.ThreadMessageId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (LastTypedAt Evergreen.V364.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V364.Drawing.Drawing (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V364.IdArray.IdArray Evergreen.V364.Id.ThreadMessageId (Evergreen.V364.Message.Message Evergreen.V364.Id.ThreadMessageId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (LastTypedAt Evergreen.V364.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V364.OneToOne.OneToOne (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V364.Drawing.Drawing (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))
    }
