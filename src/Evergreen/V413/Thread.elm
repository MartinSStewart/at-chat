module Evergreen.V413.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V413.Discord
import Evergreen.V413.Drawing
import Evergreen.V413.Id
import Evergreen.V413.IdArray
import Evergreen.V413.Message
import Evergreen.V413.MessageArray
import Evergreen.V413.OneToOne
import Evergreen.V413.Slack
import Evergreen.V413.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V413.MessageArray.MessageArray Evergreen.V413.Id.ThreadMessageId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId)
    , visibleMessages : Evergreen.V413.VisibleMessages.VisibleMessages Evergreen.V413.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V413.Drawing.Drawing (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V413.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V413.MessageArray.MessageArray Evergreen.V413.Id.ThreadMessageId (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId)
    , visibleMessages : Evergreen.V413.VisibleMessages.VisibleMessages Evergreen.V413.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V413.Drawing.Drawing (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId))
    }


type alias FrontendGenericThread userId channelId =
    { messages : Evergreen.V413.MessageArray.MessageArray Evergreen.V413.Id.ThreadMessageId userId channelId
    , visibleMessages : Evergreen.V413.VisibleMessages.VisibleMessages Evergreen.V413.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V413.Drawing.Drawing userId)
    }


type alias SlackFrontendThread =
    FrontendGenericThread (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId)


type alias BackendThread =
    { messages : Evergreen.V413.IdArray.IdArray Evergreen.V413.Id.ThreadMessageId (Evergreen.V413.Message.Message Evergreen.V413.Id.ThreadMessageId (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V413.Drawing.Drawing (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V413.IdArray.IdArray Evergreen.V413.Id.ThreadMessageId (Evergreen.V413.Message.Message Evergreen.V413.Id.ThreadMessageId (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId) (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V413.OneToOne.OneToOne (Evergreen.V413.Discord.Id Evergreen.V413.Discord.MessageId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V413.Drawing.Drawing (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId))
    }


type alias SlackBackendThread =
    { messages : Evergreen.V413.IdArray.IdArray Evergreen.V413.Id.ThreadMessageId (Evergreen.V413.Message.Message Evergreen.V413.Id.ThreadMessageId (Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId) (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V413.OneToOne.OneToOne (Evergreen.V413.Slack.Id Evergreen.V413.Slack.MessageId) (Evergreen.V413.Id.Id Evergreen.V413.Id.ThreadMessageId)
    }
