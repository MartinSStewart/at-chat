module Evergreen.V296.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V296.Discord
import Evergreen.V296.Drawing
import Evergreen.V296.Id
import Evergreen.V296.IdArray
import Evergreen.V296.Message
import Evergreen.V296.OneToOne
import Evergreen.V296.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V296.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V296.IdArray.IdArray Evergreen.V296.Id.ThreadMessageId (Evergreen.V296.Message.MessageState Evergreen.V296.Id.ThreadMessageId (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))
    , visibleMessages : Evergreen.V296.VisibleMessages.VisibleMessages Evergreen.V296.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) (LastTypedAt Evergreen.V296.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V296.Drawing.Drawing (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V296.IdArray.IdArray Evergreen.V296.Id.ThreadMessageId (Evergreen.V296.Message.MessageState Evergreen.V296.Id.ThreadMessageId (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))
    , visibleMessages : Evergreen.V296.VisibleMessages.VisibleMessages Evergreen.V296.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (LastTypedAt Evergreen.V296.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V296.Drawing.Drawing (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V296.IdArray.IdArray Evergreen.V296.Id.ThreadMessageId (Evergreen.V296.Message.Message Evergreen.V296.Id.ThreadMessageId (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) (LastTypedAt Evergreen.V296.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V296.Drawing.Drawing (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V296.IdArray.IdArray Evergreen.V296.Id.ThreadMessageId (Evergreen.V296.Message.Message Evergreen.V296.Id.ThreadMessageId (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId) (LastTypedAt Evergreen.V296.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V296.OneToOne.OneToOne (Evergreen.V296.Discord.Id Evergreen.V296.Discord.MessageId) (Evergreen.V296.Id.Id Evergreen.V296.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V296.Drawing.Drawing (Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId))
    }
