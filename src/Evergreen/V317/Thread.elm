module Evergreen.V317.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V317.Discord
import Evergreen.V317.Drawing
import Evergreen.V317.Id
import Evergreen.V317.IdArray
import Evergreen.V317.Message
import Evergreen.V317.OneToOne
import Evergreen.V317.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V317.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V317.IdArray.IdArray Evergreen.V317.Id.ThreadMessageId (Evergreen.V317.Message.MessageState Evergreen.V317.Id.ThreadMessageId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))
    , visibleMessages : Evergreen.V317.VisibleMessages.VisibleMessages Evergreen.V317.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) (LastTypedAt Evergreen.V317.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V317.Drawing.Drawing (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V317.IdArray.IdArray Evergreen.V317.Id.ThreadMessageId (Evergreen.V317.Message.MessageState Evergreen.V317.Id.ThreadMessageId (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))
    , visibleMessages : Evergreen.V317.VisibleMessages.VisibleMessages Evergreen.V317.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (LastTypedAt Evergreen.V317.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V317.Drawing.Drawing (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V317.IdArray.IdArray Evergreen.V317.Id.ThreadMessageId (Evergreen.V317.Message.Message Evergreen.V317.Id.ThreadMessageId (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) (LastTypedAt Evergreen.V317.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V317.Drawing.Drawing (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V317.IdArray.IdArray Evergreen.V317.Id.ThreadMessageId (Evergreen.V317.Message.Message Evergreen.V317.Id.ThreadMessageId (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId) (LastTypedAt Evergreen.V317.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V317.OneToOne.OneToOne (Evergreen.V317.Discord.Id Evergreen.V317.Discord.MessageId) (Evergreen.V317.Id.Id Evergreen.V317.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V317.Drawing.Drawing (Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId))
    }
