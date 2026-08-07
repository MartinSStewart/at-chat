module Evergreen.V347.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V347.Discord
import Evergreen.V347.Drawing
import Evergreen.V347.Id
import Evergreen.V347.IdArray
import Evergreen.V347.Message
import Evergreen.V347.MessageArray
import Evergreen.V347.OneToOne
import Evergreen.V347.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V347.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V347.MessageArray.MessageArray Evergreen.V347.Id.ThreadMessageId (Evergreen.V347.Message.Message Evergreen.V347.Id.ThreadMessageId (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId))
    , visibleMessages : Evergreen.V347.VisibleMessages.VisibleMessages Evergreen.V347.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) (LastTypedAt Evergreen.V347.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V347.Drawing.Drawing (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V347.MessageArray.MessageArray Evergreen.V347.Id.ThreadMessageId (Evergreen.V347.Message.Message Evergreen.V347.Id.ThreadMessageId (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId))
    , visibleMessages : Evergreen.V347.VisibleMessages.VisibleMessages Evergreen.V347.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (LastTypedAt Evergreen.V347.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V347.Drawing.Drawing (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V347.IdArray.IdArray Evergreen.V347.Id.ThreadMessageId (Evergreen.V347.Message.Message Evergreen.V347.Id.ThreadMessageId (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) (LastTypedAt Evergreen.V347.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V347.Drawing.Drawing (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V347.IdArray.IdArray Evergreen.V347.Id.ThreadMessageId (Evergreen.V347.Message.Message Evergreen.V347.Id.ThreadMessageId (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId) (LastTypedAt Evergreen.V347.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V347.OneToOne.OneToOne (Evergreen.V347.Discord.Id Evergreen.V347.Discord.MessageId) (Evergreen.V347.Id.Id Evergreen.V347.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V347.Drawing.Drawing (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId))
    }
