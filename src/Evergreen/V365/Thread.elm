module Evergreen.V365.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V365.Discord
import Evergreen.V365.Drawing
import Evergreen.V365.Id
import Evergreen.V365.IdArray
import Evergreen.V365.Message
import Evergreen.V365.MessageArray
import Evergreen.V365.OneToOne
import Evergreen.V365.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V365.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V365.MessageArray.MessageArray Evergreen.V365.Id.ThreadMessageId (Evergreen.V365.Message.Message Evergreen.V365.Id.ThreadMessageId (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))
    , visibleMessages : Evergreen.V365.VisibleMessages.VisibleMessages Evergreen.V365.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (LastTypedAt Evergreen.V365.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V365.Drawing.Drawing (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V365.MessageArray.MessageArray Evergreen.V365.Id.ThreadMessageId (Evergreen.V365.Message.Message Evergreen.V365.Id.ThreadMessageId (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))
    , visibleMessages : Evergreen.V365.VisibleMessages.VisibleMessages Evergreen.V365.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (LastTypedAt Evergreen.V365.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V365.Drawing.Drawing (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V365.IdArray.IdArray Evergreen.V365.Id.ThreadMessageId (Evergreen.V365.Message.Message Evergreen.V365.Id.ThreadMessageId (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) (LastTypedAt Evergreen.V365.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V365.Drawing.Drawing (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V365.IdArray.IdArray Evergreen.V365.Id.ThreadMessageId (Evergreen.V365.Message.Message Evergreen.V365.Id.ThreadMessageId (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId) (LastTypedAt Evergreen.V365.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V365.OneToOne.OneToOne (Evergreen.V365.Discord.Id Evergreen.V365.Discord.MessageId) (Evergreen.V365.Id.Id Evergreen.V365.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V365.Drawing.Drawing (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId))
    }
