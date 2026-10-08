module Evergreen.V401.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V401.Discord
import Evergreen.V401.Drawing
import Evergreen.V401.Id
import Evergreen.V401.IdArray
import Evergreen.V401.Message
import Evergreen.V401.MessageArray
import Evergreen.V401.OneToOne
import Evergreen.V401.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V401.MessageArray.MessageArray Evergreen.V401.Id.ThreadMessageId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId)
    , visibleMessages : Evergreen.V401.VisibleMessages.VisibleMessages Evergreen.V401.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V401.Drawing.Drawing (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V401.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V401.MessageArray.MessageArray Evergreen.V401.Id.ThreadMessageId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId)
    , visibleMessages : Evergreen.V401.VisibleMessages.VisibleMessages Evergreen.V401.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V401.Drawing.Drawing (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V401.IdArray.IdArray Evergreen.V401.Id.ThreadMessageId (Evergreen.V401.Message.Message Evergreen.V401.Id.ThreadMessageId (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V401.Drawing.Drawing (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V401.IdArray.IdArray Evergreen.V401.Id.ThreadMessageId (Evergreen.V401.Message.Message Evergreen.V401.Id.ThreadMessageId (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId) (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V401.OneToOne.OneToOne (Evergreen.V401.Discord.Id Evergreen.V401.Discord.MessageId) (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V401.Drawing.Drawing (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId))
    }
