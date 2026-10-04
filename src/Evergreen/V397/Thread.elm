module Evergreen.V397.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V397.Discord
import Evergreen.V397.Drawing
import Evergreen.V397.Id
import Evergreen.V397.IdArray
import Evergreen.V397.Message
import Evergreen.V397.MessageArray
import Evergreen.V397.OneToOne
import Evergreen.V397.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V397.MessageArray.MessageArray Evergreen.V397.Id.ThreadMessageId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId)
    , visibleMessages : Evergreen.V397.VisibleMessages.VisibleMessages Evergreen.V397.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V397.Drawing.Drawing (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V397.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V397.MessageArray.MessageArray Evergreen.V397.Id.ThreadMessageId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId)
    , visibleMessages : Evergreen.V397.VisibleMessages.VisibleMessages Evergreen.V397.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V397.Drawing.Drawing (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V397.IdArray.IdArray Evergreen.V397.Id.ThreadMessageId (Evergreen.V397.Message.Message Evergreen.V397.Id.ThreadMessageId (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V397.Drawing.Drawing (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V397.IdArray.IdArray Evergreen.V397.Id.ThreadMessageId (Evergreen.V397.Message.Message Evergreen.V397.Id.ThreadMessageId (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId) (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V397.OneToOne.OneToOne (Evergreen.V397.Discord.Id Evergreen.V397.Discord.MessageId) (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V397.Drawing.Drawing (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId))
    }
