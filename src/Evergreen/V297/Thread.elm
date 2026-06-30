module Evergreen.V297.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V297.Discord
import Evergreen.V297.Drawing
import Evergreen.V297.Id
import Evergreen.V297.IdArray
import Evergreen.V297.Message
import Evergreen.V297.OneToOne
import Evergreen.V297.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V297.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V297.IdArray.IdArray Evergreen.V297.Id.ThreadMessageId (Evergreen.V297.Message.MessageState Evergreen.V297.Id.ThreadMessageId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))
    , visibleMessages : Evergreen.V297.VisibleMessages.VisibleMessages Evergreen.V297.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) (LastTypedAt Evergreen.V297.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V297.Drawing.Drawing (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V297.IdArray.IdArray Evergreen.V297.Id.ThreadMessageId (Evergreen.V297.Message.MessageState Evergreen.V297.Id.ThreadMessageId (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))
    , visibleMessages : Evergreen.V297.VisibleMessages.VisibleMessages Evergreen.V297.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (LastTypedAt Evergreen.V297.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V297.Drawing.Drawing (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V297.IdArray.IdArray Evergreen.V297.Id.ThreadMessageId (Evergreen.V297.Message.Message Evergreen.V297.Id.ThreadMessageId (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) (LastTypedAt Evergreen.V297.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V297.Drawing.Drawing (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V297.IdArray.IdArray Evergreen.V297.Id.ThreadMessageId (Evergreen.V297.Message.Message Evergreen.V297.Id.ThreadMessageId (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId) (LastTypedAt Evergreen.V297.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V297.OneToOne.OneToOne (Evergreen.V297.Discord.Id Evergreen.V297.Discord.MessageId) (Evergreen.V297.Id.Id Evergreen.V297.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V297.Drawing.Drawing (Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId))
    }
