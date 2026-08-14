module Evergreen.V352.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V352.Discord
import Evergreen.V352.Drawing
import Evergreen.V352.Id
import Evergreen.V352.IdArray
import Evergreen.V352.Message
import Evergreen.V352.MessageArray
import Evergreen.V352.OneToOne
import Evergreen.V352.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V352.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V352.MessageArray.MessageArray Evergreen.V352.Id.ThreadMessageId (Evergreen.V352.Message.Message Evergreen.V352.Id.ThreadMessageId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))
    , visibleMessages : Evergreen.V352.VisibleMessages.VisibleMessages Evergreen.V352.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) (LastTypedAt Evergreen.V352.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V352.Drawing.Drawing (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V352.MessageArray.MessageArray Evergreen.V352.Id.ThreadMessageId (Evergreen.V352.Message.Message Evergreen.V352.Id.ThreadMessageId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))
    , visibleMessages : Evergreen.V352.VisibleMessages.VisibleMessages Evergreen.V352.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (LastTypedAt Evergreen.V352.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V352.Drawing.Drawing (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V352.IdArray.IdArray Evergreen.V352.Id.ThreadMessageId (Evergreen.V352.Message.Message Evergreen.V352.Id.ThreadMessageId (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId) (LastTypedAt Evergreen.V352.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V352.Drawing.Drawing (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V352.IdArray.IdArray Evergreen.V352.Id.ThreadMessageId (Evergreen.V352.Message.Message Evergreen.V352.Id.ThreadMessageId (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId) (LastTypedAt Evergreen.V352.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V352.OneToOne.OneToOne (Evergreen.V352.Discord.Id Evergreen.V352.Discord.MessageId) (Evergreen.V352.Id.Id Evergreen.V352.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V352.Drawing.Drawing (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId))
    }
