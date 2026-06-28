module Evergreen.V295.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V295.Discord
import Evergreen.V295.Drawing
import Evergreen.V295.Id
import Evergreen.V295.IdArray
import Evergreen.V295.Message
import Evergreen.V295.OneToOne
import Evergreen.V295.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V295.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V295.IdArray.IdArray Evergreen.V295.Id.ThreadMessageId (Evergreen.V295.Message.MessageState Evergreen.V295.Id.ThreadMessageId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))
    , visibleMessages : Evergreen.V295.VisibleMessages.VisibleMessages Evergreen.V295.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) (LastTypedAt Evergreen.V295.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V295.Drawing.Drawing (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V295.IdArray.IdArray Evergreen.V295.Id.ThreadMessageId (Evergreen.V295.Message.MessageState Evergreen.V295.Id.ThreadMessageId (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))
    , visibleMessages : Evergreen.V295.VisibleMessages.VisibleMessages Evergreen.V295.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (LastTypedAt Evergreen.V295.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V295.Drawing.Drawing (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V295.IdArray.IdArray Evergreen.V295.Id.ThreadMessageId (Evergreen.V295.Message.Message Evergreen.V295.Id.ThreadMessageId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) (LastTypedAt Evergreen.V295.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V295.Drawing.Drawing (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V295.IdArray.IdArray Evergreen.V295.Id.ThreadMessageId (Evergreen.V295.Message.Message Evergreen.V295.Id.ThreadMessageId (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (LastTypedAt Evergreen.V295.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V295.OneToOne.OneToOne (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V295.Drawing.Drawing (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))
    }
