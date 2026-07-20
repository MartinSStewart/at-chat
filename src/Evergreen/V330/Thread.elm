module Evergreen.V330.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V330.Discord
import Evergreen.V330.Drawing
import Evergreen.V330.Id
import Evergreen.V330.IdArray
import Evergreen.V330.Message
import Evergreen.V330.OneToOne
import Evergreen.V330.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V330.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V330.IdArray.IdArray Evergreen.V330.Id.ThreadMessageId (Evergreen.V330.Message.MessageState Evergreen.V330.Id.ThreadMessageId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))
    , visibleMessages : Evergreen.V330.VisibleMessages.VisibleMessages Evergreen.V330.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (LastTypedAt Evergreen.V330.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V330.Drawing.Drawing (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V330.IdArray.IdArray Evergreen.V330.Id.ThreadMessageId (Evergreen.V330.Message.MessageState Evergreen.V330.Id.ThreadMessageId (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))
    , visibleMessages : Evergreen.V330.VisibleMessages.VisibleMessages Evergreen.V330.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (LastTypedAt Evergreen.V330.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V330.Drawing.Drawing (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V330.IdArray.IdArray Evergreen.V330.Id.ThreadMessageId (Evergreen.V330.Message.Message Evergreen.V330.Id.ThreadMessageId (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) (LastTypedAt Evergreen.V330.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V330.Drawing.Drawing (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V330.IdArray.IdArray Evergreen.V330.Id.ThreadMessageId (Evergreen.V330.Message.Message Evergreen.V330.Id.ThreadMessageId (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId) (LastTypedAt Evergreen.V330.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V330.OneToOne.OneToOne (Evergreen.V330.Discord.Id Evergreen.V330.Discord.MessageId) (Evergreen.V330.Id.Id Evergreen.V330.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V330.Drawing.Drawing (Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId))
    }
