module Evergreen.V343.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V343.Discord
import Evergreen.V343.Drawing
import Evergreen.V343.Id
import Evergreen.V343.IdArray
import Evergreen.V343.Message
import Evergreen.V343.MessageArray
import Evergreen.V343.OneToOne
import Evergreen.V343.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V343.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V343.MessageArray.MessageArray Evergreen.V343.Id.ThreadMessageId (Evergreen.V343.Message.Message Evergreen.V343.Id.ThreadMessageId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))
    , visibleMessages : Evergreen.V343.VisibleMessages.VisibleMessages Evergreen.V343.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (LastTypedAt Evergreen.V343.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V343.Drawing.Drawing (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V343.MessageArray.MessageArray Evergreen.V343.Id.ThreadMessageId (Evergreen.V343.Message.Message Evergreen.V343.Id.ThreadMessageId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))
    , visibleMessages : Evergreen.V343.VisibleMessages.VisibleMessages Evergreen.V343.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (LastTypedAt Evergreen.V343.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V343.Drawing.Drawing (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V343.IdArray.IdArray Evergreen.V343.Id.ThreadMessageId (Evergreen.V343.Message.Message Evergreen.V343.Id.ThreadMessageId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (LastTypedAt Evergreen.V343.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V343.Drawing.Drawing (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V343.IdArray.IdArray Evergreen.V343.Id.ThreadMessageId (Evergreen.V343.Message.Message Evergreen.V343.Id.ThreadMessageId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (LastTypedAt Evergreen.V343.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V343.OneToOne.OneToOne (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V343.Drawing.Drawing (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))
    }
