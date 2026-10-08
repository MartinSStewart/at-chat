module Evergreen.V400.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V400.Discord
import Evergreen.V400.Drawing
import Evergreen.V400.Id
import Evergreen.V400.IdArray
import Evergreen.V400.Message
import Evergreen.V400.MessageArray
import Evergreen.V400.OneToOne
import Evergreen.V400.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V400.MessageArray.MessageArray Evergreen.V400.Id.ThreadMessageId (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId)
    , visibleMessages : Evergreen.V400.VisibleMessages.VisibleMessages Evergreen.V400.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V400.Drawing.Drawing (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V400.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V400.MessageArray.MessageArray Evergreen.V400.Id.ThreadMessageId (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId)
    , visibleMessages : Evergreen.V400.VisibleMessages.VisibleMessages Evergreen.V400.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V400.Drawing.Drawing (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V400.IdArray.IdArray Evergreen.V400.Id.ThreadMessageId (Evergreen.V400.Message.Message Evergreen.V400.Id.ThreadMessageId (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V400.Drawing.Drawing (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V400.IdArray.IdArray Evergreen.V400.Id.ThreadMessageId (Evergreen.V400.Message.Message Evergreen.V400.Id.ThreadMessageId (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId) (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V400.OneToOne.OneToOne (Evergreen.V400.Discord.Id Evergreen.V400.Discord.MessageId) (Evergreen.V400.Id.Id Evergreen.V400.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V400.Drawing.Drawing (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId))
    }
