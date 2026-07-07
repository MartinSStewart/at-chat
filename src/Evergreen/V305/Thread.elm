module Evergreen.V305.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V305.Discord
import Evergreen.V305.Drawing
import Evergreen.V305.Id
import Evergreen.V305.IdArray
import Evergreen.V305.Message
import Evergreen.V305.OneToOne
import Evergreen.V305.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V305.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V305.IdArray.IdArray Evergreen.V305.Id.ThreadMessageId (Evergreen.V305.Message.MessageState Evergreen.V305.Id.ThreadMessageId (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId))
    , visibleMessages : Evergreen.V305.VisibleMessages.VisibleMessages Evergreen.V305.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) (LastTypedAt Evergreen.V305.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V305.Drawing.Drawing (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V305.IdArray.IdArray Evergreen.V305.Id.ThreadMessageId (Evergreen.V305.Message.MessageState Evergreen.V305.Id.ThreadMessageId (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId))
    , visibleMessages : Evergreen.V305.VisibleMessages.VisibleMessages Evergreen.V305.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (LastTypedAt Evergreen.V305.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V305.Drawing.Drawing (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V305.IdArray.IdArray Evergreen.V305.Id.ThreadMessageId (Evergreen.V305.Message.Message Evergreen.V305.Id.ThreadMessageId (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) (LastTypedAt Evergreen.V305.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V305.Drawing.Drawing (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V305.IdArray.IdArray Evergreen.V305.Id.ThreadMessageId (Evergreen.V305.Message.Message Evergreen.V305.Id.ThreadMessageId (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId) (LastTypedAt Evergreen.V305.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V305.OneToOne.OneToOne (Evergreen.V305.Discord.Id Evergreen.V305.Discord.MessageId) (Evergreen.V305.Id.Id Evergreen.V305.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V305.Drawing.Drawing (Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId))
    }
