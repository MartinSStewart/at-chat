module Evergreen.V334.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V334.Discord
import Evergreen.V334.Drawing
import Evergreen.V334.Id
import Evergreen.V334.IdArray
import Evergreen.V334.Message
import Evergreen.V334.OneToOne
import Evergreen.V334.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V334.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V334.IdArray.IdArray Evergreen.V334.Id.ThreadMessageId (Evergreen.V334.Message.MessageState Evergreen.V334.Id.ThreadMessageId (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId))
    , visibleMessages : Evergreen.V334.VisibleMessages.VisibleMessages Evergreen.V334.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) (LastTypedAt Evergreen.V334.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V334.Drawing.Drawing (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V334.IdArray.IdArray Evergreen.V334.Id.ThreadMessageId (Evergreen.V334.Message.MessageState Evergreen.V334.Id.ThreadMessageId (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId))
    , visibleMessages : Evergreen.V334.VisibleMessages.VisibleMessages Evergreen.V334.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (LastTypedAt Evergreen.V334.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V334.Drawing.Drawing (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V334.IdArray.IdArray Evergreen.V334.Id.ThreadMessageId (Evergreen.V334.Message.Message Evergreen.V334.Id.ThreadMessageId (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) (LastTypedAt Evergreen.V334.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V334.Drawing.Drawing (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V334.IdArray.IdArray Evergreen.V334.Id.ThreadMessageId (Evergreen.V334.Message.Message Evergreen.V334.Id.ThreadMessageId (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId) (LastTypedAt Evergreen.V334.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V334.OneToOne.OneToOne (Evergreen.V334.Discord.Id Evergreen.V334.Discord.MessageId) (Evergreen.V334.Id.Id Evergreen.V334.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V334.Drawing.Drawing (Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId))
    }
