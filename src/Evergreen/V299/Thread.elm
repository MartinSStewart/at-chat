module Evergreen.V299.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V299.Discord
import Evergreen.V299.Drawing
import Evergreen.V299.Id
import Evergreen.V299.IdArray
import Evergreen.V299.Message
import Evergreen.V299.OneToOne
import Evergreen.V299.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V299.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V299.IdArray.IdArray Evergreen.V299.Id.ThreadMessageId (Evergreen.V299.Message.MessageState Evergreen.V299.Id.ThreadMessageId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))
    , visibleMessages : Evergreen.V299.VisibleMessages.VisibleMessages Evergreen.V299.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) (LastTypedAt Evergreen.V299.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V299.Drawing.Drawing (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V299.IdArray.IdArray Evergreen.V299.Id.ThreadMessageId (Evergreen.V299.Message.MessageState Evergreen.V299.Id.ThreadMessageId (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))
    , visibleMessages : Evergreen.V299.VisibleMessages.VisibleMessages Evergreen.V299.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (LastTypedAt Evergreen.V299.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V299.Drawing.Drawing (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V299.IdArray.IdArray Evergreen.V299.Id.ThreadMessageId (Evergreen.V299.Message.Message Evergreen.V299.Id.ThreadMessageId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) (LastTypedAt Evergreen.V299.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V299.Drawing.Drawing (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V299.IdArray.IdArray Evergreen.V299.Id.ThreadMessageId (Evergreen.V299.Message.Message Evergreen.V299.Id.ThreadMessageId (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (LastTypedAt Evergreen.V299.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V299.OneToOne.OneToOne (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V299.Drawing.Drawing (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))
    }
