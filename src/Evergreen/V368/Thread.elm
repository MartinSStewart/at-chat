module Evergreen.V368.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V368.Discord
import Evergreen.V368.Drawing
import Evergreen.V368.Id
import Evergreen.V368.IdArray
import Evergreen.V368.Message
import Evergreen.V368.MessageArray
import Evergreen.V368.OneToOne
import Evergreen.V368.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V368.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V368.MessageArray.MessageArray Evergreen.V368.Id.ThreadMessageId (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    , visibleMessages : Evergreen.V368.VisibleMessages.VisibleMessages Evergreen.V368.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (LastTypedAt Evergreen.V368.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V368.Drawing.Drawing (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V368.MessageArray.MessageArray Evergreen.V368.Id.ThreadMessageId (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
    , visibleMessages : Evergreen.V368.VisibleMessages.VisibleMessages Evergreen.V368.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (LastTypedAt Evergreen.V368.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V368.Drawing.Drawing (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V368.IdArray.IdArray Evergreen.V368.Id.ThreadMessageId (Evergreen.V368.Message.Message Evergreen.V368.Id.ThreadMessageId (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) (LastTypedAt Evergreen.V368.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V368.Drawing.Drawing (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V368.IdArray.IdArray Evergreen.V368.Id.ThreadMessageId (Evergreen.V368.Message.Message Evergreen.V368.Id.ThreadMessageId (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId) (LastTypedAt Evergreen.V368.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V368.OneToOne.OneToOne (Evergreen.V368.Discord.Id Evergreen.V368.Discord.MessageId) (Evergreen.V368.Id.Id Evergreen.V368.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V368.Drawing.Drawing (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId))
    }
