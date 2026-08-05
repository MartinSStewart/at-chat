module Evergreen.V345.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V345.Discord
import Evergreen.V345.Drawing
import Evergreen.V345.Id
import Evergreen.V345.IdArray
import Evergreen.V345.Message
import Evergreen.V345.MessageArray
import Evergreen.V345.OneToOne
import Evergreen.V345.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V345.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V345.MessageArray.MessageArray Evergreen.V345.Id.ThreadMessageId (Evergreen.V345.Message.Message Evergreen.V345.Id.ThreadMessageId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))
    , visibleMessages : Evergreen.V345.VisibleMessages.VisibleMessages Evergreen.V345.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (LastTypedAt Evergreen.V345.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V345.Drawing.Drawing (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V345.MessageArray.MessageArray Evergreen.V345.Id.ThreadMessageId (Evergreen.V345.Message.Message Evergreen.V345.Id.ThreadMessageId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))
    , visibleMessages : Evergreen.V345.VisibleMessages.VisibleMessages Evergreen.V345.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (LastTypedAt Evergreen.V345.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V345.Drawing.Drawing (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V345.IdArray.IdArray Evergreen.V345.Id.ThreadMessageId (Evergreen.V345.Message.Message Evergreen.V345.Id.ThreadMessageId (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) (LastTypedAt Evergreen.V345.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V345.Drawing.Drawing (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V345.IdArray.IdArray Evergreen.V345.Id.ThreadMessageId (Evergreen.V345.Message.Message Evergreen.V345.Id.ThreadMessageId (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (LastTypedAt Evergreen.V345.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V345.OneToOne.OneToOne (Evergreen.V345.Discord.Id Evergreen.V345.Discord.MessageId) (Evergreen.V345.Id.Id Evergreen.V345.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V345.Drawing.Drawing (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId))
    }
