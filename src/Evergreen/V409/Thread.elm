module Evergreen.V409.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V409.Discord
import Evergreen.V409.Drawing
import Evergreen.V409.Id
import Evergreen.V409.IdArray
import Evergreen.V409.Message
import Evergreen.V409.MessageArray
import Evergreen.V409.OneToOne
import Evergreen.V409.Slack
import Evergreen.V409.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V409.MessageArray.MessageArray Evergreen.V409.Id.ThreadMessageId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId)
    , visibleMessages : Evergreen.V409.VisibleMessages.VisibleMessages Evergreen.V409.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V409.Drawing.Drawing (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V409.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V409.MessageArray.MessageArray Evergreen.V409.Id.ThreadMessageId (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId)
    , visibleMessages : Evergreen.V409.VisibleMessages.VisibleMessages Evergreen.V409.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V409.Drawing.Drawing (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId))
    }


type alias FrontendGenericThread userId channelId =
    { messages : Evergreen.V409.MessageArray.MessageArray Evergreen.V409.Id.ThreadMessageId userId channelId
    , visibleMessages : Evergreen.V409.VisibleMessages.VisibleMessages Evergreen.V409.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V409.Drawing.Drawing userId)
    }


type alias SlackFrontendThread =
    FrontendGenericThread (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId)


type alias BackendThread =
    { messages : Evergreen.V409.IdArray.IdArray Evergreen.V409.Id.ThreadMessageId (Evergreen.V409.Message.Message Evergreen.V409.Id.ThreadMessageId (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V409.Drawing.Drawing (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V409.IdArray.IdArray Evergreen.V409.Id.ThreadMessageId (Evergreen.V409.Message.Message Evergreen.V409.Id.ThreadMessageId (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId) (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V409.OneToOne.OneToOne (Evergreen.V409.Discord.Id Evergreen.V409.Discord.MessageId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V409.Drawing.Drawing (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId))
    }


type alias SlackBackendThread =
    { messages : Evergreen.V409.IdArray.IdArray Evergreen.V409.Id.ThreadMessageId (Evergreen.V409.Message.Message Evergreen.V409.Id.ThreadMessageId (Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId) (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V409.OneToOne.OneToOne (Evergreen.V409.Slack.Id Evergreen.V409.Slack.MessageId) (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId)
    }
