module Evergreen.V340.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V340.Discord
import Evergreen.V340.Drawing
import Evergreen.V340.Id
import Evergreen.V340.IdArray
import Evergreen.V340.Message
import Evergreen.V340.MessageArray
import Evergreen.V340.OneToOne
import Evergreen.V340.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V340.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V340.MessageArray.MessageArray Evergreen.V340.Id.ThreadMessageId (Evergreen.V340.Message.Message Evergreen.V340.Id.ThreadMessageId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))
    , visibleMessages : Evergreen.V340.VisibleMessages.VisibleMessages Evergreen.V340.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (LastTypedAt Evergreen.V340.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V340.Drawing.Drawing (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V340.MessageArray.MessageArray Evergreen.V340.Id.ThreadMessageId (Evergreen.V340.Message.Message Evergreen.V340.Id.ThreadMessageId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))
    , visibleMessages : Evergreen.V340.VisibleMessages.VisibleMessages Evergreen.V340.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (LastTypedAt Evergreen.V340.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V340.Drawing.Drawing (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V340.IdArray.IdArray Evergreen.V340.Id.ThreadMessageId (Evergreen.V340.Message.Message Evergreen.V340.Id.ThreadMessageId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (LastTypedAt Evergreen.V340.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V340.Drawing.Drawing (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V340.IdArray.IdArray Evergreen.V340.Id.ThreadMessageId (Evergreen.V340.Message.Message Evergreen.V340.Id.ThreadMessageId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (LastTypedAt Evergreen.V340.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V340.OneToOne.OneToOne (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V340.Drawing.Drawing (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))
    }
