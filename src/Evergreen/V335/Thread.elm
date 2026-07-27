module Evergreen.V335.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V335.Discord
import Evergreen.V335.Drawing
import Evergreen.V335.Id
import Evergreen.V335.IdArray
import Evergreen.V335.Message
import Evergreen.V335.MessageArray
import Evergreen.V335.OneToOne
import Evergreen.V335.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V335.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V335.MessageArray.MessageArray Evergreen.V335.Id.ThreadMessageId (Evergreen.V335.Message.Message Evergreen.V335.Id.ThreadMessageId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))
    , visibleMessages : Evergreen.V335.VisibleMessages.VisibleMessages Evergreen.V335.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (LastTypedAt Evergreen.V335.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V335.Drawing.Drawing (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V335.MessageArray.MessageArray Evergreen.V335.Id.ThreadMessageId (Evergreen.V335.Message.Message Evergreen.V335.Id.ThreadMessageId (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))
    , visibleMessages : Evergreen.V335.VisibleMessages.VisibleMessages Evergreen.V335.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (LastTypedAt Evergreen.V335.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V335.Drawing.Drawing (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V335.IdArray.IdArray Evergreen.V335.Id.ThreadMessageId (Evergreen.V335.Message.Message Evergreen.V335.Id.ThreadMessageId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (LastTypedAt Evergreen.V335.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V335.Drawing.Drawing (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V335.IdArray.IdArray Evergreen.V335.Id.ThreadMessageId (Evergreen.V335.Message.Message Evergreen.V335.Id.ThreadMessageId (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (LastTypedAt Evergreen.V335.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V335.OneToOne.OneToOne (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V335.Drawing.Drawing (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))
    }
