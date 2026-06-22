module Evergreen.V294.Thread exposing (..)

import Array
import Date
import Effect.Time
import Evergreen.V294.Discord
import Evergreen.V294.Drawing
import Evergreen.V294.Id
import Evergreen.V294.Message
import Evergreen.V294.OneToOne
import Evergreen.V294.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V294.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V294.Message.MessageState Evergreen.V294.Id.ThreadMessageId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))
    , visibleMessages : Evergreen.V294.VisibleMessages.VisibleMessages Evergreen.V294.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) (LastTypedAt Evergreen.V294.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V294.Drawing.Drawing (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V294.Message.MessageState Evergreen.V294.Id.ThreadMessageId (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))
    , visibleMessages : Evergreen.V294.VisibleMessages.VisibleMessages Evergreen.V294.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (LastTypedAt Evergreen.V294.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V294.Drawing.Drawing (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V294.Message.Message Evergreen.V294.Id.ThreadMessageId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) (LastTypedAt Evergreen.V294.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V294.Drawing.Drawing (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V294.Message.Message Evergreen.V294.Id.ThreadMessageId (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (LastTypedAt Evergreen.V294.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V294.OneToOne.OneToOne (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V294.Drawing.Drawing (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))
    }
