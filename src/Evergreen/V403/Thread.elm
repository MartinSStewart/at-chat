module Evergreen.V403.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V403.Discord
import Evergreen.V403.Drawing
import Evergreen.V403.Id
import Evergreen.V403.IdArray
import Evergreen.V403.Message
import Evergreen.V403.MessageArray
import Evergreen.V403.OneToOne
import Evergreen.V403.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V403.MessageArray.MessageArray Evergreen.V403.Id.ThreadMessageId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId)
    , visibleMessages : Evergreen.V403.VisibleMessages.VisibleMessages Evergreen.V403.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V403.Drawing.Drawing (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V403.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V403.MessageArray.MessageArray Evergreen.V403.Id.ThreadMessageId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId)
    , visibleMessages : Evergreen.V403.VisibleMessages.VisibleMessages Evergreen.V403.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V403.Drawing.Drawing (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V403.IdArray.IdArray Evergreen.V403.Id.ThreadMessageId (Evergreen.V403.Message.Message Evergreen.V403.Id.ThreadMessageId (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V403.Drawing.Drawing (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V403.IdArray.IdArray Evergreen.V403.Id.ThreadMessageId (Evergreen.V403.Message.Message Evergreen.V403.Id.ThreadMessageId (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId) (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V403.OneToOne.OneToOne (Evergreen.V403.Discord.Id Evergreen.V403.Discord.MessageId) (Evergreen.V403.Id.Id Evergreen.V403.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V403.Drawing.Drawing (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId))
    }
