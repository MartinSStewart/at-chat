module Evergreen.V402.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V402.Discord
import Evergreen.V402.Drawing
import Evergreen.V402.Id
import Evergreen.V402.IdArray
import Evergreen.V402.Message
import Evergreen.V402.MessageArray
import Evergreen.V402.OneToOne
import Evergreen.V402.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V402.MessageArray.MessageArray Evergreen.V402.Id.ThreadMessageId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId)
    , visibleMessages : Evergreen.V402.VisibleMessages.VisibleMessages Evergreen.V402.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V402.Drawing.Drawing (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V402.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V402.MessageArray.MessageArray Evergreen.V402.Id.ThreadMessageId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId)
    , visibleMessages : Evergreen.V402.VisibleMessages.VisibleMessages Evergreen.V402.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V402.Drawing.Drawing (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V402.IdArray.IdArray Evergreen.V402.Id.ThreadMessageId (Evergreen.V402.Message.Message Evergreen.V402.Id.ThreadMessageId (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V402.Drawing.Drawing (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V402.IdArray.IdArray Evergreen.V402.Id.ThreadMessageId (Evergreen.V402.Message.Message Evergreen.V402.Id.ThreadMessageId (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId) (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V402.OneToOne.OneToOne (Evergreen.V402.Discord.Id Evergreen.V402.Discord.MessageId) (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V402.Drawing.Drawing (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId))
    }
