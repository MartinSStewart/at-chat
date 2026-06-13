module Evergreen.V287.Thread exposing (..)

import Array
import Date
import Effect.Time
import Evergreen.V287.Discord
import Evergreen.V287.Drawing
import Evergreen.V287.Id
import Evergreen.V287.Message
import Evergreen.V287.OneToOne
import Evergreen.V287.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V287.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V287.Message.MessageState Evergreen.V287.Id.ThreadMessageId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))
    , visibleMessages : Evergreen.V287.VisibleMessages.VisibleMessages Evergreen.V287.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) (LastTypedAt Evergreen.V287.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V287.Drawing.Drawing (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Array.Array (Evergreen.V287.Message.MessageState Evergreen.V287.Id.ThreadMessageId (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))
    , visibleMessages : Evergreen.V287.VisibleMessages.VisibleMessages Evergreen.V287.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (LastTypedAt Evergreen.V287.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V287.Drawing.Drawing (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))
    }


type alias BackendThread =
    { messages : Array.Array (Evergreen.V287.Message.Message Evergreen.V287.Id.ThreadMessageId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) (LastTypedAt Evergreen.V287.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V287.Drawing.Drawing (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Array.Array (Evergreen.V287.Message.Message Evergreen.V287.Id.ThreadMessageId (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (LastTypedAt Evergreen.V287.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V287.OneToOne.OneToOne (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V287.Drawing.Drawing (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))
    }
