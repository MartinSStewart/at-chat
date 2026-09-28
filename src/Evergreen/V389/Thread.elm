module Evergreen.V389.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V389.Discord
import Evergreen.V389.Drawing
import Evergreen.V389.Id
import Evergreen.V389.IdArray
import Evergreen.V389.Message
import Evergreen.V389.MessageArray
import Evergreen.V389.OneToOne
import Evergreen.V389.VisibleMessages
import SeqDict


type alias LastTypedAt messageId =
    { time : Effect.Time.Posix
    , messageIndex : Maybe (Evergreen.V389.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Evergreen.V389.MessageArray.MessageArray Evergreen.V389.Id.ThreadMessageId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId)
    , visibleMessages : Evergreen.V389.VisibleMessages.VisibleMessages Evergreen.V389.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (LastTypedAt Evergreen.V389.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V389.Drawing.Drawing (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId))
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V389.MessageArray.MessageArray Evergreen.V389.Id.ThreadMessageId (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId)
    , visibleMessages : Evergreen.V389.VisibleMessages.VisibleMessages Evergreen.V389.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (LastTypedAt Evergreen.V389.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V389.Drawing.Drawing (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V389.IdArray.IdArray Evergreen.V389.Id.ThreadMessageId (Evergreen.V389.Message.Message Evergreen.V389.Id.ThreadMessageId (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) (LastTypedAt Evergreen.V389.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V389.Drawing.Drawing (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V389.IdArray.IdArray Evergreen.V389.Id.ThreadMessageId (Evergreen.V389.Message.Message Evergreen.V389.Id.ThreadMessageId (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId) (LastTypedAt Evergreen.V389.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V389.OneToOne.OneToOne (Evergreen.V389.Discord.Id Evergreen.V389.Discord.MessageId) (Evergreen.V389.Id.Id Evergreen.V389.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V389.Drawing.Drawing (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId))
    }
