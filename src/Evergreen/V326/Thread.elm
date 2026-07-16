module Evergreen.V326.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V326.Discord
import Evergreen.V326.Drawing
import Evergreen.V326.Id
import Evergreen.V326.IdArray
import Evergreen.V326.Message
import Evergreen.V326.OneToOne
import Evergreen.V326.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V326.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V326.IdArray.IdArray Evergreen.V326.Id.ThreadMessageId (Evergreen.V326.Message.MessageState Evergreen.V326.Id.ThreadMessageId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))
    , visibleMessages : Evergreen.V326.VisibleMessages.VisibleMessages Evergreen.V326.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) (LastTypedAt Evergreen.V326.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V326.Drawing.Drawing (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V326.IdArray.IdArray Evergreen.V326.Id.ThreadMessageId (Evergreen.V326.Message.MessageState Evergreen.V326.Id.ThreadMessageId (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))
    , visibleMessages : Evergreen.V326.VisibleMessages.VisibleMessages Evergreen.V326.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (LastTypedAt Evergreen.V326.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V326.Drawing.Drawing (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V326.IdArray.IdArray Evergreen.V326.Id.ThreadMessageId (Evergreen.V326.Message.Message Evergreen.V326.Id.ThreadMessageId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) (LastTypedAt Evergreen.V326.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V326.Drawing.Drawing (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V326.IdArray.IdArray Evergreen.V326.Id.ThreadMessageId (Evergreen.V326.Message.Message Evergreen.V326.Id.ThreadMessageId (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (LastTypedAt Evergreen.V326.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V326.OneToOne.OneToOne (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V326.Drawing.Drawing (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))
    }
