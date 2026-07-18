module Evergreen.V328.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V328.Discord
import Evergreen.V328.Drawing
import Evergreen.V328.Id
import Evergreen.V328.IdArray
import Evergreen.V328.Message
import Evergreen.V328.OneToOne
import Evergreen.V328.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V328.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V328.IdArray.IdArray Evergreen.V328.Id.ThreadMessageId (Evergreen.V328.Message.MessageState Evergreen.V328.Id.ThreadMessageId (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId))
    , visibleMessages : Evergreen.V328.VisibleMessages.VisibleMessages Evergreen.V328.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) (LastTypedAt Evergreen.V328.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V328.Drawing.Drawing (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V328.IdArray.IdArray Evergreen.V328.Id.ThreadMessageId (Evergreen.V328.Message.MessageState Evergreen.V328.Id.ThreadMessageId (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId))
    , visibleMessages : Evergreen.V328.VisibleMessages.VisibleMessages Evergreen.V328.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (LastTypedAt Evergreen.V328.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V328.Drawing.Drawing (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V328.IdArray.IdArray Evergreen.V328.Id.ThreadMessageId (Evergreen.V328.Message.Message Evergreen.V328.Id.ThreadMessageId (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) (LastTypedAt Evergreen.V328.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V328.Drawing.Drawing (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V328.IdArray.IdArray Evergreen.V328.Id.ThreadMessageId (Evergreen.V328.Message.Message Evergreen.V328.Id.ThreadMessageId (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId) (LastTypedAt Evergreen.V328.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V328.OneToOne.OneToOne (Evergreen.V328.Discord.Id Evergreen.V328.Discord.MessageId) (Evergreen.V328.Id.Id Evergreen.V328.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V328.Drawing.Drawing (Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId))
    }
