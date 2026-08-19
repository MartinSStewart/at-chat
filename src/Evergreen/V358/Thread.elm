module Evergreen.V358.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V358.Discord
import Evergreen.V358.Drawing
import Evergreen.V358.Id
import Evergreen.V358.IdArray
import Evergreen.V358.Message
import Evergreen.V358.MessageArray
import Evergreen.V358.OneToOne
import Evergreen.V358.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V358.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V358.MessageArray.MessageArray Evergreen.V358.Id.ThreadMessageId (Evergreen.V358.Message.Message Evergreen.V358.Id.ThreadMessageId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))
    , visibleMessages : Evergreen.V358.VisibleMessages.VisibleMessages Evergreen.V358.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (LastTypedAt Evergreen.V358.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V358.Drawing.Drawing (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V358.MessageArray.MessageArray Evergreen.V358.Id.ThreadMessageId (Evergreen.V358.Message.Message Evergreen.V358.Id.ThreadMessageId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))
    , visibleMessages : Evergreen.V358.VisibleMessages.VisibleMessages Evergreen.V358.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (LastTypedAt Evergreen.V358.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V358.Drawing.Drawing (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V358.IdArray.IdArray Evergreen.V358.Id.ThreadMessageId (Evergreen.V358.Message.Message Evergreen.V358.Id.ThreadMessageId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (LastTypedAt Evergreen.V358.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V358.Drawing.Drawing (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V358.IdArray.IdArray Evergreen.V358.Id.ThreadMessageId (Evergreen.V358.Message.Message Evergreen.V358.Id.ThreadMessageId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (LastTypedAt Evergreen.V358.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V358.OneToOne.OneToOne (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V358.Drawing.Drawing (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))
    }
