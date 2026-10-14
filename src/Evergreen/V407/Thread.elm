module Evergreen.V407.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V407.Discord
import Evergreen.V407.Drawing
import Evergreen.V407.Id
import Evergreen.V407.IdArray
import Evergreen.V407.Message
import Evergreen.V407.MessageArray
import Evergreen.V407.OneToOne
import Evergreen.V407.Slack
import Evergreen.V407.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V407.MessageArray.MessageArray Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId)
    , visibleMessages : Evergreen.V407.VisibleMessages.VisibleMessages Evergreen.V407.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V407.Drawing.Drawing (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V407.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V407.MessageArray.MessageArray Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId)
    , visibleMessages : Evergreen.V407.VisibleMessages.VisibleMessages Evergreen.V407.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V407.Drawing.Drawing (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId))
    }


type alias FrontendGenericThread userId channelId =
    { messages : Evergreen.V407.MessageArray.MessageArray Evergreen.V407.Id.ThreadMessageId userId channelId
    , visibleMessages : Evergreen.V407.VisibleMessages.VisibleMessages Evergreen.V407.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V407.Drawing.Drawing userId)
    }


type alias SlackFrontendThread =
    FrontendGenericThread (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId)


type alias BackendThread =
    { messages : Evergreen.V407.IdArray.IdArray Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Message.Message Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V407.Drawing.Drawing (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V407.IdArray.IdArray Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Message.Message Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId) (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V407.OneToOne.OneToOne (Evergreen.V407.Discord.Id Evergreen.V407.Discord.MessageId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V407.Drawing.Drawing (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId))
    }


type alias SlackBackendThread =
    { messages : Evergreen.V407.IdArray.IdArray Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Message.Message Evergreen.V407.Id.ThreadMessageId (Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId) (Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V407.OneToOne.OneToOne (Evergreen.V407.Slack.Id Evergreen.V407.Slack.MessageId) (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId)
    }
