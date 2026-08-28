module Evergreen.V363.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V363.Discord
import Evergreen.V363.Drawing
import Evergreen.V363.Id
import Evergreen.V363.IdArray
import Evergreen.V363.Message
import Evergreen.V363.MessageArray
import Evergreen.V363.OneToOne
import Evergreen.V363.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V363.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V363.MessageArray.MessageArray Evergreen.V363.Id.ThreadMessageId (Evergreen.V363.Message.Message Evergreen.V363.Id.ThreadMessageId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))
    , visibleMessages : Evergreen.V363.VisibleMessages.VisibleMessages Evergreen.V363.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (LastTypedAt Evergreen.V363.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V363.Drawing.Drawing (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V363.MessageArray.MessageArray Evergreen.V363.Id.ThreadMessageId (Evergreen.V363.Message.Message Evergreen.V363.Id.ThreadMessageId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))
    , visibleMessages : Evergreen.V363.VisibleMessages.VisibleMessages Evergreen.V363.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (LastTypedAt Evergreen.V363.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V363.Drawing.Drawing (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V363.IdArray.IdArray Evergreen.V363.Id.ThreadMessageId (Evergreen.V363.Message.Message Evergreen.V363.Id.ThreadMessageId (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) (LastTypedAt Evergreen.V363.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V363.Drawing.Drawing (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V363.IdArray.IdArray Evergreen.V363.Id.ThreadMessageId (Evergreen.V363.Message.Message Evergreen.V363.Id.ThreadMessageId (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId) (LastTypedAt Evergreen.V363.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V363.OneToOne.OneToOne (Evergreen.V363.Discord.Id Evergreen.V363.Discord.MessageId) (Evergreen.V363.Id.Id Evergreen.V363.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V363.Drawing.Drawing (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId))
    }
