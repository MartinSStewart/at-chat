module Evergreen.V344.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V344.Discord
import Evergreen.V344.Drawing
import Evergreen.V344.Id
import Evergreen.V344.IdArray
import Evergreen.V344.Message
import Evergreen.V344.MessageArray
import Evergreen.V344.OneToOne
import Evergreen.V344.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V344.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V344.MessageArray.MessageArray Evergreen.V344.Id.ThreadMessageId (Evergreen.V344.Message.Message Evergreen.V344.Id.ThreadMessageId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))
    , visibleMessages : Evergreen.V344.VisibleMessages.VisibleMessages Evergreen.V344.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (LastTypedAt Evergreen.V344.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V344.Drawing.Drawing (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V344.MessageArray.MessageArray Evergreen.V344.Id.ThreadMessageId (Evergreen.V344.Message.Message Evergreen.V344.Id.ThreadMessageId (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId))
    , visibleMessages : Evergreen.V344.VisibleMessages.VisibleMessages Evergreen.V344.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (LastTypedAt Evergreen.V344.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V344.Drawing.Drawing (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V344.IdArray.IdArray Evergreen.V344.Id.ThreadMessageId (Evergreen.V344.Message.Message Evergreen.V344.Id.ThreadMessageId (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) (LastTypedAt Evergreen.V344.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V344.Drawing.Drawing (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V344.IdArray.IdArray Evergreen.V344.Id.ThreadMessageId (Evergreen.V344.Message.Message Evergreen.V344.Id.ThreadMessageId (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId) (LastTypedAt Evergreen.V344.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V344.OneToOne.OneToOne (Evergreen.V344.Discord.Id Evergreen.V344.Discord.MessageId) (Evergreen.V344.Id.Id Evergreen.V344.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V344.Drawing.Drawing (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId))
    }
