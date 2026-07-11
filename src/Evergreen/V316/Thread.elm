module Evergreen.V316.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V316.Discord
import Evergreen.V316.Drawing
import Evergreen.V316.Id
import Evergreen.V316.IdArray
import Evergreen.V316.Message
import Evergreen.V316.OneToOne
import Evergreen.V316.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V316.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V316.IdArray.IdArray Evergreen.V316.Id.ThreadMessageId (Evergreen.V316.Message.MessageState Evergreen.V316.Id.ThreadMessageId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))
    , visibleMessages : Evergreen.V316.VisibleMessages.VisibleMessages Evergreen.V316.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) (LastTypedAt Evergreen.V316.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V316.Drawing.Drawing (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V316.IdArray.IdArray Evergreen.V316.Id.ThreadMessageId (Evergreen.V316.Message.MessageState Evergreen.V316.Id.ThreadMessageId (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))
    , visibleMessages : Evergreen.V316.VisibleMessages.VisibleMessages Evergreen.V316.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (LastTypedAt Evergreen.V316.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V316.Drawing.Drawing (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V316.IdArray.IdArray Evergreen.V316.Id.ThreadMessageId (Evergreen.V316.Message.Message Evergreen.V316.Id.ThreadMessageId (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) (LastTypedAt Evergreen.V316.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V316.Drawing.Drawing (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V316.IdArray.IdArray Evergreen.V316.Id.ThreadMessageId (Evergreen.V316.Message.Message Evergreen.V316.Id.ThreadMessageId (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId) (LastTypedAt Evergreen.V316.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V316.OneToOne.OneToOne (Evergreen.V316.Discord.Id Evergreen.V316.Discord.MessageId) (Evergreen.V316.Id.Id Evergreen.V316.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V316.Drawing.Drawing (Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId))
    }
