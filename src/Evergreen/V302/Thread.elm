module Evergreen.V302.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V302.Discord
import Evergreen.V302.Drawing
import Evergreen.V302.Id
import Evergreen.V302.IdArray
import Evergreen.V302.Message
import Evergreen.V302.OneToOne
import Evergreen.V302.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V302.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V302.IdArray.IdArray Evergreen.V302.Id.ThreadMessageId (Evergreen.V302.Message.MessageState Evergreen.V302.Id.ThreadMessageId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))
    , visibleMessages : Evergreen.V302.VisibleMessages.VisibleMessages Evergreen.V302.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) (LastTypedAt Evergreen.V302.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V302.Drawing.Drawing (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V302.IdArray.IdArray Evergreen.V302.Id.ThreadMessageId (Evergreen.V302.Message.MessageState Evergreen.V302.Id.ThreadMessageId (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))
    , visibleMessages : Evergreen.V302.VisibleMessages.VisibleMessages Evergreen.V302.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (LastTypedAt Evergreen.V302.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V302.Drawing.Drawing (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V302.IdArray.IdArray Evergreen.V302.Id.ThreadMessageId (Evergreen.V302.Message.Message Evergreen.V302.Id.ThreadMessageId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) (LastTypedAt Evergreen.V302.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V302.Drawing.Drawing (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V302.IdArray.IdArray Evergreen.V302.Id.ThreadMessageId (Evergreen.V302.Message.Message Evergreen.V302.Id.ThreadMessageId (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (LastTypedAt Evergreen.V302.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V302.OneToOne.OneToOne (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V302.Drawing.Drawing (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))
    }
