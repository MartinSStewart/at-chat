module Evergreen.V404.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V404.Discord
import Evergreen.V404.Drawing
import Evergreen.V404.Id
import Evergreen.V404.IdArray
import Evergreen.V404.Message
import Evergreen.V404.MessageArray
import Evergreen.V404.OneToOne
import Evergreen.V404.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V404.MessageArray.MessageArray Evergreen.V404.Id.ThreadMessageId (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId)
    , visibleMessages : Evergreen.V404.VisibleMessages.VisibleMessages Evergreen.V404.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V404.Drawing.Drawing (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V404.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V404.MessageArray.MessageArray Evergreen.V404.Id.ThreadMessageId (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId)
    , visibleMessages : Evergreen.V404.VisibleMessages.VisibleMessages Evergreen.V404.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V404.Drawing.Drawing (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V404.IdArray.IdArray Evergreen.V404.Id.ThreadMessageId (Evergreen.V404.Message.Message Evergreen.V404.Id.ThreadMessageId (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V404.Drawing.Drawing (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V404.IdArray.IdArray Evergreen.V404.Id.ThreadMessageId (Evergreen.V404.Message.Message Evergreen.V404.Id.ThreadMessageId (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId) (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V404.OneToOne.OneToOne (Evergreen.V404.Discord.Id Evergreen.V404.Discord.MessageId) (Evergreen.V404.Id.Id Evergreen.V404.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V404.Drawing.Drawing (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId))
    }
