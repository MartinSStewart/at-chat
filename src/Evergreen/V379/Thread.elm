module Evergreen.V379.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V379.Discord
import Evergreen.V379.Drawing
import Evergreen.V379.Id
import Evergreen.V379.IdArray
import Evergreen.V379.Message
import Evergreen.V379.MessageArray
import Evergreen.V379.OneToOne
import Evergreen.V379.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V379.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V379.MessageArray.MessageArray Evergreen.V379.Id.ThreadMessageId (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    , visibleMessages : Evergreen.V379.VisibleMessages.VisibleMessages Evergreen.V379.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (LastTypedAt Evergreen.V379.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V379.Drawing.Drawing (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V379.MessageArray.MessageArray Evergreen.V379.Id.ThreadMessageId (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
    , visibleMessages : Evergreen.V379.VisibleMessages.VisibleMessages Evergreen.V379.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (LastTypedAt Evergreen.V379.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V379.Drawing.Drawing (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V379.IdArray.IdArray Evergreen.V379.Id.ThreadMessageId (Evergreen.V379.Message.Message Evergreen.V379.Id.ThreadMessageId (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) (LastTypedAt Evergreen.V379.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V379.Drawing.Drawing (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V379.IdArray.IdArray Evergreen.V379.Id.ThreadMessageId (Evergreen.V379.Message.Message Evergreen.V379.Id.ThreadMessageId (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId) (LastTypedAt Evergreen.V379.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V379.OneToOne.OneToOne (Evergreen.V379.Discord.Id Evergreen.V379.Discord.MessageId) (Evergreen.V379.Id.Id Evergreen.V379.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V379.Drawing.Drawing (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId))
    }
