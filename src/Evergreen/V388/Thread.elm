module Evergreen.V388.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V388.Discord
import Evergreen.V388.Drawing
import Evergreen.V388.Id
import Evergreen.V388.IdArray
import Evergreen.V388.Message
import Evergreen.V388.MessageArray
import Evergreen.V388.OneToOne
import Evergreen.V388.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V388.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V388.MessageArray.MessageArray Evergreen.V388.Id.ThreadMessageId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId)
    , visibleMessages : Evergreen.V388.VisibleMessages.VisibleMessages Evergreen.V388.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (LastTypedAt Evergreen.V388.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V388.Drawing.Drawing (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V388.MessageArray.MessageArray Evergreen.V388.Id.ThreadMessageId (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId)
    , visibleMessages : Evergreen.V388.VisibleMessages.VisibleMessages Evergreen.V388.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (LastTypedAt Evergreen.V388.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V388.Drawing.Drawing (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V388.IdArray.IdArray Evergreen.V388.Id.ThreadMessageId (Evergreen.V388.Message.Message Evergreen.V388.Id.ThreadMessageId (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (LastTypedAt Evergreen.V388.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V388.Drawing.Drawing (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V388.IdArray.IdArray Evergreen.V388.Id.ThreadMessageId (Evergreen.V388.Message.Message Evergreen.V388.Id.ThreadMessageId (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId) (LastTypedAt Evergreen.V388.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V388.OneToOne.OneToOne (Evergreen.V388.Discord.Id Evergreen.V388.Discord.MessageId) (Evergreen.V388.Id.Id Evergreen.V388.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V388.Drawing.Drawing (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId))
    }
