module Evergreen.V298.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V298.Discord
import Evergreen.V298.Drawing
import Evergreen.V298.Id
import Evergreen.V298.IdArray
import Evergreen.V298.Message
import Evergreen.V298.OneToOne
import Evergreen.V298.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V298.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V298.IdArray.IdArray Evergreen.V298.Id.ThreadMessageId (Evergreen.V298.Message.MessageState Evergreen.V298.Id.ThreadMessageId (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))
    , visibleMessages : Evergreen.V298.VisibleMessages.VisibleMessages Evergreen.V298.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) (LastTypedAt Evergreen.V298.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V298.Drawing.Drawing (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V298.IdArray.IdArray Evergreen.V298.Id.ThreadMessageId (Evergreen.V298.Message.MessageState Evergreen.V298.Id.ThreadMessageId (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId))
    , visibleMessages : Evergreen.V298.VisibleMessages.VisibleMessages Evergreen.V298.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (LastTypedAt Evergreen.V298.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V298.Drawing.Drawing (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V298.IdArray.IdArray Evergreen.V298.Id.ThreadMessageId (Evergreen.V298.Message.Message Evergreen.V298.Id.ThreadMessageId (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId) (LastTypedAt Evergreen.V298.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V298.Drawing.Drawing (Evergreen.V298.Id.Id Evergreen.V298.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V298.IdArray.IdArray Evergreen.V298.Id.ThreadMessageId (Evergreen.V298.Message.Message Evergreen.V298.Id.ThreadMessageId (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId) (LastTypedAt Evergreen.V298.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V298.OneToOne.OneToOne (Evergreen.V298.Discord.Id Evergreen.V298.Discord.MessageId) (Evergreen.V298.Id.Id Evergreen.V298.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V298.Drawing.Drawing (Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId))
    }
