module Evergreen.V336.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V336.Discord
import Evergreen.V336.Drawing
import Evergreen.V336.Id
import Evergreen.V336.IdArray
import Evergreen.V336.Message
import Evergreen.V336.MessageArray
import Evergreen.V336.OneToOne
import Evergreen.V336.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V336.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V336.MessageArray.MessageArray Evergreen.V336.Id.ThreadMessageId (Evergreen.V336.Message.Message Evergreen.V336.Id.ThreadMessageId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))
    , visibleMessages : Evergreen.V336.VisibleMessages.VisibleMessages Evergreen.V336.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (LastTypedAt Evergreen.V336.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V336.Drawing.Drawing (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V336.MessageArray.MessageArray Evergreen.V336.Id.ThreadMessageId (Evergreen.V336.Message.Message Evergreen.V336.Id.ThreadMessageId (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))
    , visibleMessages : Evergreen.V336.VisibleMessages.VisibleMessages Evergreen.V336.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (LastTypedAt Evergreen.V336.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V336.Drawing.Drawing (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V336.IdArray.IdArray Evergreen.V336.Id.ThreadMessageId (Evergreen.V336.Message.Message Evergreen.V336.Id.ThreadMessageId (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) (LastTypedAt Evergreen.V336.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V336.Drawing.Drawing (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V336.IdArray.IdArray Evergreen.V336.Id.ThreadMessageId (Evergreen.V336.Message.Message Evergreen.V336.Id.ThreadMessageId (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (LastTypedAt Evergreen.V336.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V336.OneToOne.OneToOne (Evergreen.V336.Discord.Id Evergreen.V336.Discord.MessageId) (Evergreen.V336.Id.Id Evergreen.V336.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V336.Drawing.Drawing (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId))
    }
