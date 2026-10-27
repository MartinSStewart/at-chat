module Evergreen.V417.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V417.Discord
import Evergreen.V417.Drawing
import Evergreen.V417.Id
import Evergreen.V417.IdArray
import Evergreen.V417.Message
import Evergreen.V417.MessageArray
import Evergreen.V417.OneToOne
import Evergreen.V417.Slack
import Evergreen.V417.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V417.MessageArray.MessageArray Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId)
    , visibleMessages : Evergreen.V417.VisibleMessages.VisibleMessages Evergreen.V417.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V417.Drawing.Drawing (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V417.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V417.MessageArray.MessageArray Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId)
    , visibleMessages : Evergreen.V417.VisibleMessages.VisibleMessages Evergreen.V417.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V417.Drawing.Drawing (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId))
    }


type alias FrontendGenericThread userId channelId =
    { messages : Evergreen.V417.MessageArray.MessageArray Evergreen.V417.Id.ThreadMessageId userId channelId
    , visibleMessages : Evergreen.V417.VisibleMessages.VisibleMessages Evergreen.V417.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V417.Drawing.Drawing userId)
    }


type alias SlackFrontendThread =
    FrontendGenericThread (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId)


type alias BackendThread =
    { messages : Evergreen.V417.IdArray.IdArray Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Message.Message Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V417.Drawing.Drawing (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V417.IdArray.IdArray Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Message.Message Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId) (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V417.OneToOne.OneToOne (Evergreen.V417.Discord.Id Evergreen.V417.Discord.MessageId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V417.Drawing.Drawing (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId))
    }


type alias SlackBackendThread =
    { messages : Evergreen.V417.IdArray.IdArray Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Message.Message Evergreen.V417.Id.ThreadMessageId (Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId) (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V417.OneToOne.OneToOne (Evergreen.V417.Slack.Id Evergreen.V417.Slack.MessageId) (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId)
    }
