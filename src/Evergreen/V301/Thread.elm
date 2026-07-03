module Evergreen.V301.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V301.Discord
import Evergreen.V301.Drawing
import Evergreen.V301.Id
import Evergreen.V301.IdArray
import Evergreen.V301.Message
import Evergreen.V301.OneToOne
import Evergreen.V301.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V301.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V301.IdArray.IdArray Evergreen.V301.Id.ThreadMessageId (Evergreen.V301.Message.MessageState Evergreen.V301.Id.ThreadMessageId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))
    , visibleMessages : Evergreen.V301.VisibleMessages.VisibleMessages Evergreen.V301.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) (LastTypedAt Evergreen.V301.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V301.Drawing.Drawing (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V301.IdArray.IdArray Evergreen.V301.Id.ThreadMessageId (Evergreen.V301.Message.MessageState Evergreen.V301.Id.ThreadMessageId (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))
    , visibleMessages : Evergreen.V301.VisibleMessages.VisibleMessages Evergreen.V301.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (LastTypedAt Evergreen.V301.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V301.Drawing.Drawing (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V301.IdArray.IdArray Evergreen.V301.Id.ThreadMessageId (Evergreen.V301.Message.Message Evergreen.V301.Id.ThreadMessageId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) (LastTypedAt Evergreen.V301.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V301.Drawing.Drawing (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V301.IdArray.IdArray Evergreen.V301.Id.ThreadMessageId (Evergreen.V301.Message.Message Evergreen.V301.Id.ThreadMessageId (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (LastTypedAt Evergreen.V301.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V301.OneToOne.OneToOne (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V301.Drawing.Drawing (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))
    }
