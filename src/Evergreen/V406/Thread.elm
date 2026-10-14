module Evergreen.V406.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V406.Discord
import Evergreen.V406.Drawing
import Evergreen.V406.Id
import Evergreen.V406.IdArray
import Evergreen.V406.Message
import Evergreen.V406.MessageArray
import Evergreen.V406.OneToOne
import Evergreen.V406.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V406.MessageArray.MessageArray Evergreen.V406.Id.ThreadMessageId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId)
    , visibleMessages : Evergreen.V406.VisibleMessages.VisibleMessages Evergreen.V406.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V406.Drawing.Drawing (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V406.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V406.MessageArray.MessageArray Evergreen.V406.Id.ThreadMessageId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId)
    , visibleMessages : Evergreen.V406.VisibleMessages.VisibleMessages Evergreen.V406.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V406.Drawing.Drawing (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V406.IdArray.IdArray Evergreen.V406.Id.ThreadMessageId (Evergreen.V406.Message.Message Evergreen.V406.Id.ThreadMessageId (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V406.Drawing.Drawing (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V406.IdArray.IdArray Evergreen.V406.Id.ThreadMessageId (Evergreen.V406.Message.Message Evergreen.V406.Id.ThreadMessageId (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId) (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V406.OneToOne.OneToOne (Evergreen.V406.Discord.Id Evergreen.V406.Discord.MessageId) (Evergreen.V406.Id.Id Evergreen.V406.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V406.Drawing.Drawing (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId))
    }
