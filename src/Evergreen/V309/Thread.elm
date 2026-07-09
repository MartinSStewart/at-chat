module Evergreen.V309.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V309.Discord
import Evergreen.V309.Drawing
import Evergreen.V309.Id
import Evergreen.V309.IdArray
import Evergreen.V309.Message
import Evergreen.V309.OneToOne
import Evergreen.V309.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V309.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V309.IdArray.IdArray Evergreen.V309.Id.ThreadMessageId (Evergreen.V309.Message.MessageState Evergreen.V309.Id.ThreadMessageId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))
    , visibleMessages : Evergreen.V309.VisibleMessages.VisibleMessages Evergreen.V309.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) (LastTypedAt Evergreen.V309.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V309.Drawing.Drawing (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V309.IdArray.IdArray Evergreen.V309.Id.ThreadMessageId (Evergreen.V309.Message.MessageState Evergreen.V309.Id.ThreadMessageId (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))
    , visibleMessages : Evergreen.V309.VisibleMessages.VisibleMessages Evergreen.V309.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (LastTypedAt Evergreen.V309.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V309.Drawing.Drawing (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V309.IdArray.IdArray Evergreen.V309.Id.ThreadMessageId (Evergreen.V309.Message.Message Evergreen.V309.Id.ThreadMessageId (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId) (LastTypedAt Evergreen.V309.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V309.Drawing.Drawing (Evergreen.V309.Id.Id Evergreen.V309.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V309.IdArray.IdArray Evergreen.V309.Id.ThreadMessageId (Evergreen.V309.Message.Message Evergreen.V309.Id.ThreadMessageId (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId) (LastTypedAt Evergreen.V309.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V309.OneToOne.OneToOne (Evergreen.V309.Discord.Id Evergreen.V309.Discord.MessageId) (Evergreen.V309.Id.Id Evergreen.V309.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V309.Drawing.Drawing (Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId))
    }
