module Evergreen.V386.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V386.Discord
import Evergreen.V386.Drawing
import Evergreen.V386.Id
import Evergreen.V386.IdArray
import Evergreen.V386.Message
import Evergreen.V386.MessageArray
import Evergreen.V386.OneToOne
import Evergreen.V386.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V386.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V386.MessageArray.MessageArray Evergreen.V386.Id.ThreadMessageId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId)
    , visibleMessages : Evergreen.V386.VisibleMessages.VisibleMessages Evergreen.V386.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (LastTypedAt Evergreen.V386.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V386.Drawing.Drawing (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V386.MessageArray.MessageArray Evergreen.V386.Id.ThreadMessageId (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId)
    , visibleMessages : Evergreen.V386.VisibleMessages.VisibleMessages Evergreen.V386.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (LastTypedAt Evergreen.V386.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V386.Drawing.Drawing (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V386.IdArray.IdArray Evergreen.V386.Id.ThreadMessageId (Evergreen.V386.Message.Message Evergreen.V386.Id.ThreadMessageId (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (LastTypedAt Evergreen.V386.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V386.Drawing.Drawing (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V386.IdArray.IdArray Evergreen.V386.Id.ThreadMessageId (Evergreen.V386.Message.Message Evergreen.V386.Id.ThreadMessageId (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId) (LastTypedAt Evergreen.V386.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V386.OneToOne.OneToOne (Evergreen.V386.Discord.Id Evergreen.V386.Discord.MessageId) (Evergreen.V386.Id.Id Evergreen.V386.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V386.Drawing.Drawing (Evergreen.V386.Discord.Id Evergreen.V386.Discord.UserId))
    }
