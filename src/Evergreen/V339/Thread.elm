module Evergreen.V339.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V339.Discord
import Evergreen.V339.Drawing
import Evergreen.V339.Id
import Evergreen.V339.IdArray
import Evergreen.V339.Message
import Evergreen.V339.MessageArray
import Evergreen.V339.OneToOne
import Evergreen.V339.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V339.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V339.MessageArray.MessageArray Evergreen.V339.Id.ThreadMessageId (Evergreen.V339.Message.Message Evergreen.V339.Id.ThreadMessageId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))
    , visibleMessages : Evergreen.V339.VisibleMessages.VisibleMessages Evergreen.V339.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (LastTypedAt Evergreen.V339.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V339.Drawing.Drawing (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V339.MessageArray.MessageArray Evergreen.V339.Id.ThreadMessageId (Evergreen.V339.Message.Message Evergreen.V339.Id.ThreadMessageId (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))
    , visibleMessages : Evergreen.V339.VisibleMessages.VisibleMessages Evergreen.V339.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (LastTypedAt Evergreen.V339.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V339.Drawing.Drawing (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V339.IdArray.IdArray Evergreen.V339.Id.ThreadMessageId (Evergreen.V339.Message.Message Evergreen.V339.Id.ThreadMessageId (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) (LastTypedAt Evergreen.V339.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V339.Drawing.Drawing (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V339.IdArray.IdArray Evergreen.V339.Id.ThreadMessageId (Evergreen.V339.Message.Message Evergreen.V339.Id.ThreadMessageId (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId) (LastTypedAt Evergreen.V339.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V339.OneToOne.OneToOne (Evergreen.V339.Discord.Id Evergreen.V339.Discord.MessageId) (Evergreen.V339.Id.Id Evergreen.V339.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V339.Drawing.Drawing (Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId))
    }
