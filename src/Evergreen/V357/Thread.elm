module Evergreen.V357.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V357.Discord
import Evergreen.V357.Drawing
import Evergreen.V357.Id
import Evergreen.V357.IdArray
import Evergreen.V357.Message
import Evergreen.V357.MessageArray
import Evergreen.V357.OneToOne
import Evergreen.V357.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V357.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V357.MessageArray.MessageArray Evergreen.V357.Id.ThreadMessageId (Evergreen.V357.Message.Message Evergreen.V357.Id.ThreadMessageId (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))
    , visibleMessages : Evergreen.V357.VisibleMessages.VisibleMessages Evergreen.V357.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (LastTypedAt Evergreen.V357.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V357.Drawing.Drawing (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V357.MessageArray.MessageArray Evergreen.V357.Id.ThreadMessageId (Evergreen.V357.Message.Message Evergreen.V357.Id.ThreadMessageId (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))
    , visibleMessages : Evergreen.V357.VisibleMessages.VisibleMessages Evergreen.V357.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (LastTypedAt Evergreen.V357.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V357.Drawing.Drawing (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V357.IdArray.IdArray Evergreen.V357.Id.ThreadMessageId (Evergreen.V357.Message.Message Evergreen.V357.Id.ThreadMessageId (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) (LastTypedAt Evergreen.V357.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V357.Drawing.Drawing (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V357.IdArray.IdArray Evergreen.V357.Id.ThreadMessageId (Evergreen.V357.Message.Message Evergreen.V357.Id.ThreadMessageId (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId) (LastTypedAt Evergreen.V357.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V357.OneToOne.OneToOne (Evergreen.V357.Discord.Id Evergreen.V357.Discord.MessageId) (Evergreen.V357.Id.Id Evergreen.V357.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V357.Drawing.Drawing (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId))
    }
