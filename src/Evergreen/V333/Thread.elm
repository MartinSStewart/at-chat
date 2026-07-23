module Evergreen.V333.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V333.Discord
import Evergreen.V333.Drawing
import Evergreen.V333.Id
import Evergreen.V333.IdArray
import Evergreen.V333.Message
import Evergreen.V333.OneToOne
import Evergreen.V333.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V333.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V333.IdArray.IdArray Evergreen.V333.Id.ThreadMessageId (Evergreen.V333.Message.MessageState Evergreen.V333.Id.ThreadMessageId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))
    , visibleMessages : Evergreen.V333.VisibleMessages.VisibleMessages Evergreen.V333.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (LastTypedAt Evergreen.V333.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V333.Drawing.Drawing (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V333.IdArray.IdArray Evergreen.V333.Id.ThreadMessageId (Evergreen.V333.Message.MessageState Evergreen.V333.Id.ThreadMessageId (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))
    , visibleMessages : Evergreen.V333.VisibleMessages.VisibleMessages Evergreen.V333.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (LastTypedAt Evergreen.V333.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V333.Drawing.Drawing (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V333.IdArray.IdArray Evergreen.V333.Id.ThreadMessageId (Evergreen.V333.Message.Message Evergreen.V333.Id.ThreadMessageId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (LastTypedAt Evergreen.V333.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V333.Drawing.Drawing (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V333.IdArray.IdArray Evergreen.V333.Id.ThreadMessageId (Evergreen.V333.Message.Message Evergreen.V333.Id.ThreadMessageId (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (LastTypedAt Evergreen.V333.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V333.OneToOne.OneToOne (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V333.Drawing.Drawing (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))
    }
