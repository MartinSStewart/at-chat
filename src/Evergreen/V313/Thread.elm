module Evergreen.V313.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V313.Discord
import Evergreen.V313.Drawing
import Evergreen.V313.Id
import Evergreen.V313.IdArray
import Evergreen.V313.Message
import Evergreen.V313.OneToOne
import Evergreen.V313.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V313.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V313.IdArray.IdArray Evergreen.V313.Id.ThreadMessageId (Evergreen.V313.Message.MessageState Evergreen.V313.Id.ThreadMessageId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))
    , visibleMessages : Evergreen.V313.VisibleMessages.VisibleMessages Evergreen.V313.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) (LastTypedAt Evergreen.V313.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V313.Drawing.Drawing (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V313.IdArray.IdArray Evergreen.V313.Id.ThreadMessageId (Evergreen.V313.Message.MessageState Evergreen.V313.Id.ThreadMessageId (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))
    , visibleMessages : Evergreen.V313.VisibleMessages.VisibleMessages Evergreen.V313.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (LastTypedAt Evergreen.V313.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V313.Drawing.Drawing (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V313.IdArray.IdArray Evergreen.V313.Id.ThreadMessageId (Evergreen.V313.Message.Message Evergreen.V313.Id.ThreadMessageId (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) (LastTypedAt Evergreen.V313.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V313.Drawing.Drawing (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V313.IdArray.IdArray Evergreen.V313.Id.ThreadMessageId (Evergreen.V313.Message.Message Evergreen.V313.Id.ThreadMessageId (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId) (LastTypedAt Evergreen.V313.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V313.OneToOne.OneToOne (Evergreen.V313.Discord.Id Evergreen.V313.Discord.MessageId) (Evergreen.V313.Id.Id Evergreen.V313.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V313.Drawing.Drawing (Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId))
    }
