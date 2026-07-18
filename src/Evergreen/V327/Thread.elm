module Evergreen.V327.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V327.Discord
import Evergreen.V327.Drawing
import Evergreen.V327.Id
import Evergreen.V327.IdArray
import Evergreen.V327.Message
import Evergreen.V327.OneToOne
import Evergreen.V327.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V327.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V327.IdArray.IdArray Evergreen.V327.Id.ThreadMessageId (Evergreen.V327.Message.MessageState Evergreen.V327.Id.ThreadMessageId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))
    , visibleMessages : Evergreen.V327.VisibleMessages.VisibleMessages Evergreen.V327.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) (LastTypedAt Evergreen.V327.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V327.Drawing.Drawing (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V327.IdArray.IdArray Evergreen.V327.Id.ThreadMessageId (Evergreen.V327.Message.MessageState Evergreen.V327.Id.ThreadMessageId (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))
    , visibleMessages : Evergreen.V327.VisibleMessages.VisibleMessages Evergreen.V327.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (LastTypedAt Evergreen.V327.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V327.Drawing.Drawing (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V327.IdArray.IdArray Evergreen.V327.Id.ThreadMessageId (Evergreen.V327.Message.Message Evergreen.V327.Id.ThreadMessageId (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) (LastTypedAt Evergreen.V327.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V327.Drawing.Drawing (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V327.IdArray.IdArray Evergreen.V327.Id.ThreadMessageId (Evergreen.V327.Message.Message Evergreen.V327.Id.ThreadMessageId (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId) (LastTypedAt Evergreen.V327.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V327.OneToOne.OneToOne (Evergreen.V327.Discord.Id Evergreen.V327.Discord.MessageId) (Evergreen.V327.Id.Id Evergreen.V327.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V327.Drawing.Drawing (Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId))
    }
