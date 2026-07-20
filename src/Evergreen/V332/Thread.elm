module Evergreen.V332.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V332.Discord
import Evergreen.V332.Drawing
import Evergreen.V332.Id
import Evergreen.V332.IdArray
import Evergreen.V332.Message
import Evergreen.V332.OneToOne
import Evergreen.V332.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V332.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V332.IdArray.IdArray Evergreen.V332.Id.ThreadMessageId (Evergreen.V332.Message.MessageState Evergreen.V332.Id.ThreadMessageId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))
    , visibleMessages : Evergreen.V332.VisibleMessages.VisibleMessages Evergreen.V332.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (LastTypedAt Evergreen.V332.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V332.Drawing.Drawing (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V332.IdArray.IdArray Evergreen.V332.Id.ThreadMessageId (Evergreen.V332.Message.MessageState Evergreen.V332.Id.ThreadMessageId (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))
    , visibleMessages : Evergreen.V332.VisibleMessages.VisibleMessages Evergreen.V332.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (LastTypedAt Evergreen.V332.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V332.Drawing.Drawing (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V332.IdArray.IdArray Evergreen.V332.Id.ThreadMessageId (Evergreen.V332.Message.Message Evergreen.V332.Id.ThreadMessageId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (LastTypedAt Evergreen.V332.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V332.Drawing.Drawing (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V332.IdArray.IdArray Evergreen.V332.Id.ThreadMessageId (Evergreen.V332.Message.Message Evergreen.V332.Id.ThreadMessageId (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (LastTypedAt Evergreen.V332.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V332.OneToOne.OneToOne (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V332.Drawing.Drawing (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))
    }
