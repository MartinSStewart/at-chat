module Evergreen.V311.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V311.Discord
import Evergreen.V311.Drawing
import Evergreen.V311.Id
import Evergreen.V311.IdArray
import Evergreen.V311.Message
import Evergreen.V311.OneToOne
import Evergreen.V311.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V311.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V311.IdArray.IdArray Evergreen.V311.Id.ThreadMessageId (Evergreen.V311.Message.MessageState Evergreen.V311.Id.ThreadMessageId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))
    , visibleMessages : Evergreen.V311.VisibleMessages.VisibleMessages Evergreen.V311.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) (LastTypedAt Evergreen.V311.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V311.Drawing.Drawing (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V311.IdArray.IdArray Evergreen.V311.Id.ThreadMessageId (Evergreen.V311.Message.MessageState Evergreen.V311.Id.ThreadMessageId (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))
    , visibleMessages : Evergreen.V311.VisibleMessages.VisibleMessages Evergreen.V311.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (LastTypedAt Evergreen.V311.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V311.Drawing.Drawing (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V311.IdArray.IdArray Evergreen.V311.Id.ThreadMessageId (Evergreen.V311.Message.Message Evergreen.V311.Id.ThreadMessageId (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) (LastTypedAt Evergreen.V311.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V311.Drawing.Drawing (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V311.IdArray.IdArray Evergreen.V311.Id.ThreadMessageId (Evergreen.V311.Message.Message Evergreen.V311.Id.ThreadMessageId (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId) (LastTypedAt Evergreen.V311.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V311.OneToOne.OneToOne (Evergreen.V311.Discord.Id Evergreen.V311.Discord.MessageId) (Evergreen.V311.Id.Id Evergreen.V311.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V311.Drawing.Drawing (Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId))
    }
