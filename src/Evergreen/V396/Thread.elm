module Evergreen.V396.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V396.Discord
import Evergreen.V396.Drawing
import Evergreen.V396.Id
import Evergreen.V396.IdArray
import Evergreen.V396.Message
import Evergreen.V396.MessageArray
import Evergreen.V396.OneToOne
import Evergreen.V396.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V396.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V396.MessageArray.MessageArray Evergreen.V396.Id.ThreadMessageId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId)
    , visibleMessages : Evergreen.V396.VisibleMessages.VisibleMessages Evergreen.V396.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (LastTypedAt Evergreen.V396.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V396.Drawing.Drawing (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V396.MessageArray.MessageArray Evergreen.V396.Id.ThreadMessageId (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId)
    , visibleMessages : Evergreen.V396.VisibleMessages.VisibleMessages Evergreen.V396.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (LastTypedAt Evergreen.V396.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V396.Drawing.Drawing (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V396.IdArray.IdArray Evergreen.V396.Id.ThreadMessageId (Evergreen.V396.Message.Message Evergreen.V396.Id.ThreadMessageId (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) (LastTypedAt Evergreen.V396.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V396.Drawing.Drawing (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V396.IdArray.IdArray Evergreen.V396.Id.ThreadMessageId (Evergreen.V396.Message.Message Evergreen.V396.Id.ThreadMessageId (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId) (LastTypedAt Evergreen.V396.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V396.OneToOne.OneToOne (Evergreen.V396.Discord.Id Evergreen.V396.Discord.MessageId) (Evergreen.V396.Id.Id Evergreen.V396.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V396.Drawing.Drawing (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId))
    }
