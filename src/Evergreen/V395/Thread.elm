module Evergreen.V395.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V395.Discord
import Evergreen.V395.Drawing
import Evergreen.V395.Id
import Evergreen.V395.IdArray
import Evergreen.V395.Message
import Evergreen.V395.MessageArray
import Evergreen.V395.OneToOne
import Evergreen.V395.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V395.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V395.MessageArray.MessageArray Evergreen.V395.Id.ThreadMessageId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId)
    , visibleMessages : Evergreen.V395.VisibleMessages.VisibleMessages Evergreen.V395.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (LastTypedAt Evergreen.V395.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V395.Drawing.Drawing (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V395.MessageArray.MessageArray Evergreen.V395.Id.ThreadMessageId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId)
    , visibleMessages : Evergreen.V395.VisibleMessages.VisibleMessages Evergreen.V395.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (LastTypedAt Evergreen.V395.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V395.Drawing.Drawing (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V395.IdArray.IdArray Evergreen.V395.Id.ThreadMessageId (Evergreen.V395.Message.Message Evergreen.V395.Id.ThreadMessageId (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (LastTypedAt Evergreen.V395.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V395.Drawing.Drawing (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V395.IdArray.IdArray Evergreen.V395.Id.ThreadMessageId (Evergreen.V395.Message.Message Evergreen.V395.Id.ThreadMessageId (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId) (LastTypedAt Evergreen.V395.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V395.OneToOne.OneToOne (Evergreen.V395.Discord.Id Evergreen.V395.Discord.MessageId) (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V395.Drawing.Drawing (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId))
    }
