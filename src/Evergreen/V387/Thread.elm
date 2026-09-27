module Evergreen.V387.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V387.Discord
import Evergreen.V387.Drawing
import Evergreen.V387.Id
import Evergreen.V387.IdArray
import Evergreen.V387.Message
import Evergreen.V387.MessageArray
import Evergreen.V387.OneToOne
import Evergreen.V387.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V387.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V387.MessageArray.MessageArray Evergreen.V387.Id.ThreadMessageId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId)
    , visibleMessages : Evergreen.V387.VisibleMessages.VisibleMessages Evergreen.V387.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (LastTypedAt Evergreen.V387.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V387.Drawing.Drawing (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V387.MessageArray.MessageArray Evergreen.V387.Id.ThreadMessageId (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId)
    , visibleMessages : Evergreen.V387.VisibleMessages.VisibleMessages Evergreen.V387.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (LastTypedAt Evergreen.V387.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V387.Drawing.Drawing (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V387.IdArray.IdArray Evergreen.V387.Id.ThreadMessageId (Evergreen.V387.Message.Message Evergreen.V387.Id.ThreadMessageId (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) (LastTypedAt Evergreen.V387.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V387.Drawing.Drawing (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V387.IdArray.IdArray Evergreen.V387.Id.ThreadMessageId (Evergreen.V387.Message.Message Evergreen.V387.Id.ThreadMessageId (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId) (LastTypedAt Evergreen.V387.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V387.OneToOne.OneToOne (Evergreen.V387.Discord.Id Evergreen.V387.Discord.MessageId) (Evergreen.V387.Id.Id Evergreen.V387.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V387.Drawing.Drawing (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId))
    }
