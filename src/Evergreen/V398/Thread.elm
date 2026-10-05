module Evergreen.V398.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V398.Discord
import Evergreen.V398.Drawing
import Evergreen.V398.Id
import Evergreen.V398.IdArray
import Evergreen.V398.Message
import Evergreen.V398.MessageArray
import Evergreen.V398.OneToOne
import Evergreen.V398.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V398.MessageArray.MessageArray Evergreen.V398.Id.ThreadMessageId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId)
    , visibleMessages : Evergreen.V398.VisibleMessages.VisibleMessages Evergreen.V398.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V398.Drawing.Drawing (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V398.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V398.MessageArray.MessageArray Evergreen.V398.Id.ThreadMessageId (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId)
    , visibleMessages : Evergreen.V398.VisibleMessages.VisibleMessages Evergreen.V398.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V398.Drawing.Drawing (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId))
    }


type alias BackendThread =
    { messages : Evergreen.V398.IdArray.IdArray Evergreen.V398.Id.ThreadMessageId (Evergreen.V398.Message.Message Evergreen.V398.Id.ThreadMessageId (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V398.Drawing.Drawing (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V398.IdArray.IdArray Evergreen.V398.Id.ThreadMessageId (Evergreen.V398.Message.Message Evergreen.V398.Id.ThreadMessageId (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId) (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V398.OneToOne.OneToOne (Evergreen.V398.Discord.Id Evergreen.V398.Discord.MessageId) (Evergreen.V398.Id.Id Evergreen.V398.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V398.Drawing.Drawing (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId))
    }
