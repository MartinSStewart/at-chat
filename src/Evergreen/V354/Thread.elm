module Evergreen.V354.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V354.Discord
import Evergreen.V354.Drawing
import Evergreen.V354.Id
import Evergreen.V354.IdArray
import Evergreen.V354.Message
import Evergreen.V354.MessageArray
import Evergreen.V354.OneToOne
import Evergreen.V354.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V354.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V354.MessageArray.MessageArray Evergreen.V354.Id.ThreadMessageId (Evergreen.V354.Message.Message Evergreen.V354.Id.ThreadMessageId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))
    , visibleMessages : Evergreen.V354.VisibleMessages.VisibleMessages Evergreen.V354.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) (LastTypedAt Evergreen.V354.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V354.Drawing.Drawing (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V354.MessageArray.MessageArray Evergreen.V354.Id.ThreadMessageId (Evergreen.V354.Message.Message Evergreen.V354.Id.ThreadMessageId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))
    , visibleMessages : Evergreen.V354.VisibleMessages.VisibleMessages Evergreen.V354.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (LastTypedAt Evergreen.V354.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V354.Drawing.Drawing (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V354.IdArray.IdArray Evergreen.V354.Id.ThreadMessageId (Evergreen.V354.Message.Message Evergreen.V354.Id.ThreadMessageId (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) (LastTypedAt Evergreen.V354.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V354.Drawing.Drawing (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V354.IdArray.IdArray Evergreen.V354.Id.ThreadMessageId (Evergreen.V354.Message.Message Evergreen.V354.Id.ThreadMessageId (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId) (LastTypedAt Evergreen.V354.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V354.OneToOne.OneToOne (Evergreen.V354.Discord.Id Evergreen.V354.Discord.MessageId) (Evergreen.V354.Id.Id Evergreen.V354.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V354.Drawing.Drawing (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId))
    }
