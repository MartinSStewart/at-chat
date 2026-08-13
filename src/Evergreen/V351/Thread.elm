module Evergreen.V351.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V351.Discord
import Evergreen.V351.Drawing
import Evergreen.V351.Id
import Evergreen.V351.IdArray
import Evergreen.V351.Message
import Evergreen.V351.MessageArray
import Evergreen.V351.OneToOne
import Evergreen.V351.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V351.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V351.MessageArray.MessageArray Evergreen.V351.Id.ThreadMessageId (Evergreen.V351.Message.Message Evergreen.V351.Id.ThreadMessageId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))
    , visibleMessages : Evergreen.V351.VisibleMessages.VisibleMessages Evergreen.V351.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (LastTypedAt Evergreen.V351.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V351.Drawing.Drawing (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V351.MessageArray.MessageArray Evergreen.V351.Id.ThreadMessageId (Evergreen.V351.Message.Message Evergreen.V351.Id.ThreadMessageId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))
    , visibleMessages : Evergreen.V351.VisibleMessages.VisibleMessages Evergreen.V351.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (LastTypedAt Evergreen.V351.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V351.Drawing.Drawing (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V351.IdArray.IdArray Evergreen.V351.Id.ThreadMessageId (Evergreen.V351.Message.Message Evergreen.V351.Id.ThreadMessageId (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) (LastTypedAt Evergreen.V351.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V351.Drawing.Drawing (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V351.IdArray.IdArray Evergreen.V351.Id.ThreadMessageId (Evergreen.V351.Message.Message Evergreen.V351.Id.ThreadMessageId (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId) (LastTypedAt Evergreen.V351.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V351.OneToOne.OneToOne (Evergreen.V351.Discord.Id Evergreen.V351.Discord.MessageId) (Evergreen.V351.Id.Id Evergreen.V351.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V351.Drawing.Drawing (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId))
    }
