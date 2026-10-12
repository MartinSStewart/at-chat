module Evergreen.V405.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V405.Discord
import Evergreen.V405.Drawing
import Evergreen.V405.Id
import Evergreen.V405.IdArray
import Evergreen.V405.Message
import Evergreen.V405.MessageArray
import Evergreen.V405.OneToOne
import Evergreen.V405.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V405.MessageArray.MessageArray Evergreen.V405.Id.ThreadMessageId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId)
    , visibleMessages : Evergreen.V405.VisibleMessages.VisibleMessages Evergreen.V405.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V405.Drawing.Drawing (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V405.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V405.MessageArray.MessageArray Evergreen.V405.Id.ThreadMessageId (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId)
    , visibleMessages : Evergreen.V405.VisibleMessages.VisibleMessages Evergreen.V405.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V405.Drawing.Drawing (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V405.IdArray.IdArray Evergreen.V405.Id.ThreadMessageId (Evergreen.V405.Message.Message Evergreen.V405.Id.ThreadMessageId (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V405.Drawing.Drawing (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V405.IdArray.IdArray Evergreen.V405.Id.ThreadMessageId (Evergreen.V405.Message.Message Evergreen.V405.Id.ThreadMessageId (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V405.OneToOne.OneToOne (Evergreen.V405.Discord.Id Evergreen.V405.Discord.MessageId) (Evergreen.V405.Id.Id Evergreen.V405.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V405.Drawing.Drawing (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId))
    }
