module Evergreen.V308.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V308.Discord
import Evergreen.V308.Drawing
import Evergreen.V308.Id
import Evergreen.V308.IdArray
import Evergreen.V308.Message
import Evergreen.V308.OneToOne
import Evergreen.V308.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V308.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V308.IdArray.IdArray Evergreen.V308.Id.ThreadMessageId (Evergreen.V308.Message.MessageState Evergreen.V308.Id.ThreadMessageId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))
    , visibleMessages : Evergreen.V308.VisibleMessages.VisibleMessages Evergreen.V308.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) (LastTypedAt Evergreen.V308.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V308.Drawing.Drawing (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V308.IdArray.IdArray Evergreen.V308.Id.ThreadMessageId (Evergreen.V308.Message.MessageState Evergreen.V308.Id.ThreadMessageId (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))
    , visibleMessages : Evergreen.V308.VisibleMessages.VisibleMessages Evergreen.V308.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (LastTypedAt Evergreen.V308.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V308.Drawing.Drawing (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V308.IdArray.IdArray Evergreen.V308.Id.ThreadMessageId (Evergreen.V308.Message.Message Evergreen.V308.Id.ThreadMessageId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) (LastTypedAt Evergreen.V308.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V308.Drawing.Drawing (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V308.IdArray.IdArray Evergreen.V308.Id.ThreadMessageId (Evergreen.V308.Message.Message Evergreen.V308.Id.ThreadMessageId (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (LastTypedAt Evergreen.V308.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V308.OneToOne.OneToOne (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V308.Drawing.Drawing (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))
    }
