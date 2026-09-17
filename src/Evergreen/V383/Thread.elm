module Evergreen.V383.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V383.Discord
import Evergreen.V383.Drawing
import Evergreen.V383.Id
import Evergreen.V383.IdArray
import Evergreen.V383.Message
import Evergreen.V383.MessageArray
import Evergreen.V383.OneToOne
import Evergreen.V383.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V383.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V383.MessageArray.MessageArray Evergreen.V383.Id.ThreadMessageId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    , visibleMessages : Evergreen.V383.VisibleMessages.VisibleMessages Evergreen.V383.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (LastTypedAt Evergreen.V383.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V383.Drawing.Drawing (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V383.MessageArray.MessageArray Evergreen.V383.Id.ThreadMessageId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
    , visibleMessages : Evergreen.V383.VisibleMessages.VisibleMessages Evergreen.V383.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (LastTypedAt Evergreen.V383.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V383.Drawing.Drawing (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V383.IdArray.IdArray Evergreen.V383.Id.ThreadMessageId (Evergreen.V383.Message.Message Evergreen.V383.Id.ThreadMessageId (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) (LastTypedAt Evergreen.V383.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V383.Drawing.Drawing (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V383.IdArray.IdArray Evergreen.V383.Id.ThreadMessageId (Evergreen.V383.Message.Message Evergreen.V383.Id.ThreadMessageId (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId) (LastTypedAt Evergreen.V383.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V383.OneToOne.OneToOne (Evergreen.V383.Discord.Id Evergreen.V383.Discord.MessageId) (Evergreen.V383.Id.Id Evergreen.V383.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V383.Drawing.Drawing (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId))
    }
