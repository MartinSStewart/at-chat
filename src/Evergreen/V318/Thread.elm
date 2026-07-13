module Evergreen.V318.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V318.Discord
import Evergreen.V318.Drawing
import Evergreen.V318.Id
import Evergreen.V318.IdArray
import Evergreen.V318.Message
import Evergreen.V318.OneToOne
import Evergreen.V318.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V318.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V318.IdArray.IdArray Evergreen.V318.Id.ThreadMessageId (Evergreen.V318.Message.MessageState Evergreen.V318.Id.ThreadMessageId (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))
    , visibleMessages : Evergreen.V318.VisibleMessages.VisibleMessages Evergreen.V318.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) (LastTypedAt Evergreen.V318.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V318.Drawing.Drawing (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V318.IdArray.IdArray Evergreen.V318.Id.ThreadMessageId (Evergreen.V318.Message.MessageState Evergreen.V318.Id.ThreadMessageId (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))
    , visibleMessages : Evergreen.V318.VisibleMessages.VisibleMessages Evergreen.V318.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (LastTypedAt Evergreen.V318.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V318.Drawing.Drawing (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V318.IdArray.IdArray Evergreen.V318.Id.ThreadMessageId (Evergreen.V318.Message.Message Evergreen.V318.Id.ThreadMessageId (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId) (LastTypedAt Evergreen.V318.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V318.Drawing.Drawing (Evergreen.V318.Id.Id Evergreen.V318.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V318.IdArray.IdArray Evergreen.V318.Id.ThreadMessageId (Evergreen.V318.Message.Message Evergreen.V318.Id.ThreadMessageId (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId) (LastTypedAt Evergreen.V318.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V318.OneToOne.OneToOne (Evergreen.V318.Discord.Id Evergreen.V318.Discord.MessageId) (Evergreen.V318.Id.Id Evergreen.V318.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V318.Drawing.Drawing (Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId))
    }
